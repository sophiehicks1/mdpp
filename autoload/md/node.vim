" Functions for parsing a markdown document into a DOM-like structure,
" consisting of sections and links, which can be queried and manipulated by
" other modules.
"
" Each section is modeled as a node in a tree, with the following fields:
"
" ID - Integer ID, unique within a particular document (but not stable. This
"      will change each time the document is parsed)
" Parent - The parent node object, representing the document section this node
"          is nested inside
" Level - The HTML heading level of the section heading (H1, H2, etc.) Larger
"         heading level nodes are nested inside smaller heading level parents
" Children - A (possibly empty) list of child nodes, for which this node is
"            the parent
" lnums - A list of integer line numbers, representing where in the document
"         this node is shown. These line numbers include the heading line, and
"         any content lines, but not the children's headings or content (since
"         those nodes are included directly)
"
" Each link is modeled as a dictionary with the following fields:
" {
"   'type': 'wiki' | 'inline' | 'reference' | 'reference_definition',
"   'line_num': <line number where link starts>,
"   'end_line': <line number where link ends>,
"   'start_col': <1-indexed column where link starts>,
"   'end_col': <1-indexed column where link ends>,
"   'text': <display text of the link>,
"   'text_start_line': <line number where link text starts>,
"   'text_end_line': <line number where link text ends>,
"   'text_start_col': <1-indexed column where link text starts>,
"   'text_end_col': <1-indexed column where link text ends>,
"   'target': <target of the link>,
"   'target_start_line': <line number where link target starts>,
"   'target_end_line': <line number where link target ends>,
"   'target_start_col': <1-indexed column where link target starts>,
"   'target_end_col': <1-indexed column where link target ends>,
"   'full_start_line': <line number where full link starts>,
"   'full_end_line': <line number where full link ends>,
"   'full_start_col': <1-indexed column where full link starts>,
"   'full_end_col': <1-indexed column where full link ends>
" }
"
" All these fields are always present, although reference-style links may have
" target set to empty string or target-related lines/cols set to -1 if no
" reference definition is found.

" Functions to build the DOM. This is the data structure that's exposed to the
" other modules

" TODO Potential Optimizations {{{
" - currently this scans the entire next line every time, even if there are no
"   open links at the end of the first line. We should optimize this to stop
"   scanning if there are no open links at the end of the first line.
" - currently this scans each line for each link type separately, but we could
"   probably avoid some redundant scanning by scanning for all link types in one pass 
" - add something to only rebuild the dom if the document has changed
" }}}

" Tree/Node Construction API {{{

" Construct a tree of nodes, to represent markdown document structure.
function! md#node#buildTree()
  " The root node and it's children represent the entire document. By
  " definition it's the only node with no heading, since it contains only the
  " content lines before the first heading. All other nodes in the document
  " are children or descendents of the root node
  let root = s:newNode(0, 0)
  let nodes = [root]
  let lastNode = root
  let links = []
  let refs = {}
  " add the lines to the tree one by one
  for lnum in range(1, line('$'))
    let [nodes, lastNode] = s:addLineToHeadingTree(lnum, nodes, lastNode)
    let [links, refs] = s:addLineToLinksAndRefs(lnum, links, refs)
  endfor
  let links = s:connectLinksToRefs(links, refs)
  return { 'root': root, 'nodes': nodes , 'links': links, 'refs': refs}
endfunction

function! s:addLineToLinksAndRefs(lnum, links, refs)
  let [links, refs] = [a:links, a:refs]
  let ref_info = s:findReferenceDefsInLine(a:lnum)
  if !empty(ref_info)
    if !has_key(refs, ref_info.reference)
      let refs[ref_info.reference] = ref_info
    else
      echoerr "Duplicate reference definition found for reference " . ref_info.reference
    endif
    return [links, refs]
  endif
  let links += s:findLinksInLine(a:lnum)
  return [links, refs]
endfunction

function! s:connectLinksToRefs(links, refs)
  " now that we have all the reference definitions, update the reference links
  " to include target information
  for link in a:links
    if link.type == 'reference' && has_key(a:refs, link.reference)
      let ref_info = a:refs[link.reference]
      let link.target = ref_info.target
      let link.target_start_line = ref_info.line_num
      let link.target_end_line = ref_info.line_num
      let link.target_start_col = ref_info.target_start_col
      let link.target_end_col = ref_info.target_end_col
    endif
  endfor
  return a:links
endfunction

" }}}

" Heading tree construction logic {{{

function! s:addLineToHeadingTree(lnum, nodes, lastNode)
  let [nodes, lastNode] = [a:nodes, a:lastNode]

  " if the line is a heading, it's a new node
  if md#line#headingLevel(a:lnum)
    let node = s:newNode(lastNode.id + 1, a:lnum)
    call s:assignParent(node, lastNode)
    let nodes += [node]
    let lastNode = node
  else
    " otherwise we add the new line as content in the last node we added
    let lastNode.lnums += [a:lnum]
  endif

  return [nodes, lastNode]
endfunction

function! s:assignParent(newNode, candidateParent)
  let candidateParent = a:candidateParent

  " find the first parent that can parent the new node
  while !s:canParent(candidateParent, a:newNode)
    if !md#node#hasParent(candidateParent)
      call md#node#debugPrint(a:newNode)
      throw "MDPP No parent found for newNode. This is a bug"
    endif
    let candidateParent = candidateParent.parent
  endwhile

  " add this node as a child of the found parent
  call s:addChild(candidateParent, a:newNode)
endfunction

" Create a new node object, which will be stored in the tree. Each node object
" represents a section in the document. Each node is a section of the
" document. Each section consists of a heading on the first line (or no
" heading if it's the root node), some number lines under the heading and
" optionally some number of child sections with smaller headings (i.e.
" headings with higher HTML heading level numbers - H1 is bigger than H2,
" etc.)
" Fields:
" - id:       Integer ID of the node, unique within the tree
" - parent:   Node object of the parent, or 0 if this is the root
" - level:    Integer heading level (1 for h1, 2 for h2, etc.)
" - children: List of child nodes (List<Node>)
" - lnums:    List of line numbers that this node represents (including the content of the section)
function! s:newNode(id, lnum)
  return {
        \ 'id': a:id,
        \ 'parent': 0,
        \ 'level': s:headingLevelForNode(a:lnum),
        \ 'children': [],
        \ 'lnums': [a:lnum]
        \ }
endfunction

function! s:headingLevelForNode(lnum)
  " lnum == 0 means it's the root node, so it has -1 heading level (i.e. it
  " can parent anything)
  if a:lnum == 0
    return -1
  endif
  return md#line#headingLevel(a:lnum)
endfunction

" Wire a parent and child to each other during construction
function! s:addChild(parent, child)
  let a:parent.children += [a:child]
  let a:child.parent = a:parent
endfunction

" parent must have a lower heading level than child (e.g. H2 cannot have an H1
" child)
function! s:canParent(parentNode, childNode)
  return a:parentNode.level < a:childNode.level
endfunction

" }}}

" Link tree construction logic {{{1

" s:find___InLine {{{2

function! s:findLinksInLine(lnum)
  let links = []
  let links += s:genericFindLinksInLine(function('<SID>findWikiLinksInText'), a:lnum)
  let links += s:genericFindLinksInLine(function('<SID>findInlineLinksInText'), a:lnum)
  let links += s:genericFindLinksInLine(function('<SID>findReferenceLinksInText'), a:lnum)
  return links
endfunction

function! s:genericFindLinksInLine(find_in_text_fn, line_num)
  " Join current line with next line to handle multi-line links
  let [joined_text, lengths] = s:joinTwoLines(a:line_num)

  " Find all links in the joined text
  let all_links = a:find_in_text_fn(joined_text, a:line_num)
  let result_links = []

  " Filter out links that don't belong to the current line
  for link in all_links
    " Check if link starts within the current line
    if s:linkStartsInCurrentLine(link.start_col, lengths)
      let adjusted_link = s:adjustLinkInfo(link, a:line_num, lengths)
      call add(result_links, adjusted_link)
    endif
  endfor

  return result_links
endfunction

function! s:findReferenceDefsInLine(line_num)
  " Find reference definition in the given line
  let pattern = '^\s*\[\([^\]]\+\)\]:\s*\(\S\+\)'
  let match = matchlist(getline(a:line_num), pattern)

  " Build reference definition info if found
  if !empty(match)
    let reference = match[1]
    let target = match[2]

    let target_end = len(match[0])
    let target_start = target_end - len(target) + 1
    return {
          \ 'type': 'reference_definition',
          \ 'line_num': a:line_num,
          \ 'reference': reference,
          \ 'target': target,
          \ 'target_start_col': target_start,
          \ 'target_end_col': target_end
          \ }
  endif
  return {}
endfunction

" 2}}}

" s:find___LinksInText {{{2

" Helper function to find wiki links in a text string
" Returns list of link info dictionaries (with temporary line_num)
function! s:findWikiLinksInText(text, temp_line_num)
  let links = []
  let pos = 0

  while 1
    " Find the next [[ sequence
    let wiki_start = stridx(a:text, '[[', pos)
    if wiki_start == -1
      break
    endif

    " Find the matching ]] sequence
    let wiki_end = stridx(a:text, ']]', wiki_start + 2)
    if wiki_end == -1
      let pos = wiki_start + 2
      continue
    endif

    " Extract the content between [[ and ]]
    let wiki_content = a:text[wiki_start + 2 : wiki_end - 1]

    " Parse target and alias
    let pipe_pos = stridx(wiki_content, '|')
    if pipe_pos != -1
      " Has alias: [[Target|Alias]]
      let target = wiki_content[0 : pipe_pos - 1]
      let display_text = wiki_content[pipe_pos + 1 : -1]
      let target_start_col = wiki_start + 3
      let target_end_col = wiki_start + 2 + pipe_pos
      let text_start_col = wiki_start + 3 + pipe_pos + 1
      let text_end_col = wiki_end
    else
      " No alias: [[Target]]
      let target = wiki_content
      let display_text = target
      let target_start_col = wiki_start + 3
      let target_end_col = wiki_end
      let text_start_col = wiki_start + 3
      let text_end_col = wiki_end
    endif

    let link_info = {
          \ 'type': 'wiki',
          \ 'line_num': a:temp_line_num,
          \ 'start_col': wiki_start + 1,
          \ 'end_col': wiki_end + 2,
          \ 'text': display_text,
          \ 'text_start_col': text_start_col,
          \ 'text_end_col': text_end_col,
          \ 'target': target,
          \ 'target_start_col': target_start_col,
          \ 'target_end_col': target_end_col,
          \ 'full_start_col': wiki_start + 1,
          \ 'full_end_col': wiki_end + 2
          \ }

    call add(links, link_info)
    let pos = wiki_end + 2
  endwhile

  return links
endfunction

" Helper function to find inline links in a text string
" Returns list of link info dictionaries (with temporary line_num)
function! s:findInlineLinksInText(text, temp_line_num)
  let links = []
  let pos = 0

  while 1
    " Find the next [ character
    let bracket_start = stridx(a:text, '[', pos)
    if bracket_start == -1
      break
    endif

    " Find the matching ] character
    let bracket_end = s:findMatchingBracket(a:text, bracket_start)
    if bracket_end == -1
      let pos = bracket_start + 1
      continue
    endif

    " Check if this is followed by a ( for inline link
    let paren_start = bracket_end + 1
    if paren_start >= len(a:text) || a:text[paren_start] != '('
      let pos = bracket_start + 1
      continue
    endif

    " Find the matching ) character
    let paren_end = s:findMatchingParen(a:text, paren_start)
    if paren_end == -1
      let pos = bracket_start + 1
      continue
    endif

    " Extract link components
    let text = a:text[bracket_start + 1 : bracket_end - 1]
    let target = a:text[paren_start + 1 : paren_end - 1]

    let link_info = {
          \ 'type': 'inline',
          \ 'line_num': a:temp_line_num,
          \ 'start_col': bracket_start + 1,
          \ 'end_col': paren_end + 1,
          \ 'text': text,
          \ 'text_start_col': bracket_start + 2,
          \ 'text_end_col': bracket_end,
          \ 'target': target,
          \ 'target_start_col': paren_start + 2,
          \ 'target_end_col': paren_end,
          \ 'full_start_col': bracket_start + 1,
          \ 'full_end_col': paren_end + 1
          \ }

    call add(links, link_info)
    let pos = paren_end + 1
  endwhile

  return links
endfunction

" Helper function to find reference links in a text string
" Returns list of link info dictionaries (with temporary line_num)
function! s:findReferenceLinksInText(text, temp_line_num)
  let links = []
  let pos = 0

  while 1
    " Find the next [ character
    let bracket_start = stridx(a:text, '[', pos)
    if bracket_start == -1
      break
    endif

    " Find the matching ] character
    let bracket_end = s:findMatchingBracket(a:text, bracket_start)
    if bracket_end == -1
      let pos = bracket_start + 1
      continue
    endif

    " Check if this is followed by another [ for reference link
    let ref_start = bracket_end + 1
    if ref_start >= len(a:text) || a:text[ref_start] != '['
      " Check for implicit reference (just [text][])
      let pos = bracket_start + 1
      continue
    endif

    " Find the matching ] character for reference
    let ref_end = s:findMatchingBracket(a:text, ref_start)
    if ref_end == -1
      let pos = bracket_start + 1
      continue
    endif

    " Extract link components
    let text = a:text[bracket_start + 1 : bracket_end - 1]
    let reference = a:text[ref_start + 1 : ref_end - 1]

    " If reference is empty, use text as reference (implicit reference)
    if empty(reference)
      let reference = text
    endif

    let link_info = {
          \ 'type': 'reference',
          \ 'text': text,
          \ 'reference': reference,
          \ 'target': '',
          \ 'line_num': a:temp_line_num,
          \ 'start_col': bracket_start + 1,
          \ 'end_col': ref_end + 1,
          \ 'text_start_col': bracket_start + 2,
          \ 'text_end_col': bracket_end,
          \ 'full_start_col': bracket_start + 1,
          \ 'full_end_col': ref_end + 1,
          \ 'target_start_line': -1,
          \ 'target_end_line': -1,
          \ 'target_start_col': -1,
          \ 'target_end_col': -1,
          \ }

    call add(links, link_info)
    let pos = ref_end + 1
  endwhile

  return links
endfunction

" 2}}}

" Pure text/vim stuff {{{2

" Find matching bracket, handling nested brackets
function! s:findMatchingBracket(text, start_pos)
  let bracket_count = 1
  let pos = a:start_pos + 1

  while pos < len(a:text) && bracket_count > 0
    let char = a:text[pos]
    if char == '['
      let bracket_count += 1
    elseif char == ']'
      let bracket_count -= 1
    endif
    let pos += 1
  endwhile

  if bracket_count == 0
    return pos - 1
  else
    return -1
  endif
endfunction

" Find matching parenthesis, handling nested parentheses
function! s:findMatchingParen(text, start_pos)
  let paren_count = 1
  let pos = a:start_pos + 1

  while pos < len(a:text) && paren_count > 0
    let char = a:text[pos]
    if char == '('
      let paren_count += 1
    elseif char == ')'
      let paren_count -= 1
    endif
    let pos += 1
  endwhile

  if paren_count == 0
    return pos - 1
  else
    return -1
  endif
endfunction

" Helper function to get line content safely (returns empty string for invalid line numbers)
function! s:getLineSafe(line_num)
  if a:line_num < 1 || a:line_num > line('$')
    return ''
  endif
  return getline(a:line_num)
endfunction

" 2}}}

" Line joining and adjusting {{{2

function! s:joinTwoLines(lnum)
  let curr_line = s:getLineSafe(a:lnum)
  let next_line = s:getLineSafe(a:lnum + 1)

  " Strip structural indentation and markers from all lines
  " This handles list items, blockquotes, and other indented contexts
  let [curr_stripped, curr_spaces] = s:stripStructuralMarkers(curr_line)
  let [next_stripped, next_spaces] = s:stripStructuralMarkers(next_line)

  " Add spaces to continuation lines to correctly model line wrapping in practice
  let next_stripped = ' ' . next_stripped

  " Return both original and stripped lengths for position mapping
  let lengths = {
        \ 'original_lengths': [len(curr_line), len(next_line)],
        \ 'stripped_lengths': [len(curr_stripped), len(next_stripped)],
        \ 'leading_spaces': [curr_spaces, next_spaces]
        \ }

  return [curr_stripped . next_stripped, lengths]
endfunction

" Helper function to strip structural markers from a line
" Returns: [stripped_line, spaces_removed]
function! s:stripStructuralMarkers(line)
  if empty(a:line)
    return ['', 0]
  endif

  " Check for and strip structural markers
  " Blockquote markers: >
  " But don't strip if the line starts with a list marker (it's a new item)
  " List markers: -, *, +, or numbered lists
  let num_spaces = len(matchstr(a:line, '^\s*'))
  let stripped = a:line[num_spaces :]
  let marker_len = 0

  " Strip blockquote markers (> ) recursively
  while stripped =~# '^>\s\?'
    let marker_match = matchstr(stripped, '^>\s\?')
    let marker_len += len(marker_match)
    let stripped = stripped[len(marker_match):]
  endwhile

  return [stripped, num_spaces + marker_len]
endfunction

function! s:linkStartsInCurrentLine(start_col, lengths)
  let original_lengths = a:lengths.original_lengths
  let stripped_lengths = a:lengths.stripped_lengths

  " Calculate the end column of the current line in stripped text
  let curr_line_end_stripped = stripped_lengths[0]

  " If the link starts before or at the end of the current line, it belongs here
  return a:start_col <= curr_line_end_stripped
endfunction

" Helper function to convert a position in joined text to actual line/column
" pos is 0-indexed position in joined text
" line_num is the target line number
" lengths is the dict returned by s:joinThreeLines
" Returns: [line, col] where line is absolute and col is 1-indexed
function! s:posToLineCol(pos, line_num, lengths)
  let curr_len = a:lengths['stripped_lengths'][0]
  let curr_spaces = a:lengths['leading_spaces'][0]
  let next_spaces = a:lengths['leading_spaces'][1]

  if a:pos < curr_len
    " Position is on current line
    " Add back the leading spaces that were stripped
    return [a:line_num, a:pos + curr_spaces + 1]
  else " Position is on next line
    let pos_in_next_stripped = a:pos - curr_len

    " If we stripped leading spaces and added a single space
    if pos_in_next_stripped == 0
      " Position is at the single space we added - map to first non-whitespace char
      return [a:line_num + 1, next_spaces + 1]
    else
      " Position is after the added space - subtract 1 for the space and add back leading spaces
      return [a:line_num + 1, pos_in_next_stripped - 1 + next_spaces + 1]
    endif
  endif
endfunction

" Helper function to adjust link info from joined text back to original line coordinates
" This handles multi-line links by determining the actual line where the link starts
function! s:adjustLinkInfo(link_info, line_num, lengths)
  " Convert all positions from joined text to actual line/col
  " Note: link_info columns are 1-indexed to match vim semantics, so convert to 0-indexed first
  let start_pos = s:posToLineCol(a:link_info.start_col - 1, a:line_num, a:lengths)
  let end_pos = s:posToLineCol(a:link_info.end_col - 1, a:line_num, a:lengths)
  let text_start_pos = s:posToLineCol(a:link_info.text_start_col - 1, a:line_num, a:lengths)
  let text_end_pos = s:posToLineCol(a:link_info.text_end_col - 1, a:line_num, a:lengths)

  " Create adjusted link info with proper multi-line coordinates
  let adjusted = copy(a:link_info)
  let adjusted.line_num = start_pos[0]
  let adjusted.start_col = start_pos[1]
  let adjusted.end_col = end_pos[1]
  let adjusted.end_line = end_pos[0]
  let adjusted.text_start_col = text_start_pos[1]
  let adjusted.text_end_col = text_end_pos[1]
  let adjusted.text_start_line = text_start_pos[0]
  let adjusted.text_end_line = text_end_pos[0]
  let adjusted.full_start_col = start_pos[1]
  let adjusted.full_end_col = end_pos[1]
  let adjusted.full_start_line = start_pos[0]
  let adjusted.full_end_line = end_pos[0]

  if adjusted.type !=# 'reference'
    " skip reference links because their targets live in the reference definition and were never line-joined
    let target_start_pos = s:posToLineCol(a:link_info.target_start_col - 1, a:line_num, a:lengths)
    let target_end_pos = s:posToLineCol(a:link_info.target_end_col - 1, a:line_num, a:lengths)
    let adjusted.target_start_col = target_start_pos[1]
    let adjusted.target_end_col = target_end_pos[1]
    let adjusted.target_start_line = target_start_pos[0]
    let adjusted.target_end_line = target_end_pos[0]
  endif

  return adjusted
endfunction

" 2}}}

" 1}}}

" Getters {{{

" Return true if node has a valid parent
function! md#node#hasParent(node)
  return type(a:node.parent) == type({})
endfunction

" Return v:true if a:node has a heading
function! md#node#hasHeading(node)
  return a:node.level > 0
endfunction

" return the line number for this section's heading. If there is no heading
" (i.e. if it's the root node), return -1
function! md#node#headingLnum(node)
  if md#node#hasHeading(a:node)
    return a:node.lnums[0]
  end
  return -1
endfunction

" return the start and end line numbers for this link.
function! md#node#linkLnums(link)
  return [a:link.line_num, a:link.end_line]
endfunction

function! s:addNodeRecursive(acc, node)
  let acc = a:acc + [a:node]
  for child in a:node.children
    let acc += s:addNodeRecursive(a:acc, child)
  endfor
  return acc
endfunction

function! md#node#getDescendents(node)
  let descendents = []
  let descendents += s:addNodeRecursive([], a:node)
  return descendents
endfunction

function! md#node#getLnums(node, withDescendents)
  let lnums = []
  if a:withDescendents
    for child in md#node#getDescendents(a:node)
      let lnums += child.lnums
    endfor
  else
    let lnums += a:node.lnums
  endif
  return lnums
endfunction

" Return a (possibly empty) list of a:node's child nodes.
function! md#node#getChildren(node)
  return a:node.children
endfunction

"return a list of a:node's siblings (including a:node itself)
function! md#node#getSiblings(node)
  " if there's no parent, it's the root node, which means there are no
  " siblings besides itself
  if !md#node#hasParent(a:node)
    return [a:node]
  endif
  let parent = a:node.parent
  return parent.children
endfunction

function! md#node#getParent(node)
  return a:node.parent
endfunction

function! md#node#getHeadingLevel(node)
  return a:node.level
endfunction

" }}}

" Update functions {{{

function! s:setHeadingLevel(node, newLevel)
  let lnum = md#node#headingLnum(a:node)
  if lnum == -1
    throw "MDPP: Tried to update heading on a non heading line. This is a bug."
  endif
  " get heading content
  let headingContent = md#line#getHeadingText(lnum)
  call md#line#setHeadingAtLine(lnum, a:newLevel, headingContent)
endfunction

function! md#node#decrementHeading(node)
  let currentLevel = a:node.level
  let targetLevel = max([1, currentLevel - 1])
  call s:setHeadingLevel(a:node, targetLevel)
endfunction

function! md#node#incrementHeading(node)
  let currentLevel = a:node.level
  let targetLevel = min([6, currentLevel + 1])
  call s:setHeadingLevel(a:node, targetLevel)
endfunction

function! md#node#prependNewHeading(node, newLevel)
  let targetLine = md#node#headingLnum(a:node)
  call md#line#insertHeading(targetLine, a:newLevel, '')
endfunction

" }}}

" Debugging functions {{{

" Print a node object for debugging purposes. This is needed, because the raw
" node objects contain self references (because parent links to child, and
" child links to parent)
function! md#node#debugPrint(node)
  let parent_id = ((type(a:node.parent) == type({}) && has_key(a:node.parent, 'id')) ? a:node.parent.id : 'n/a') 
  echom '{id: ' . a:node.id . ', '
        \ 'level: ' . a:node.level . ', '
        \ 'parentId: ' . parent_id . ', '
        \ 'children: ' . string(map(copy(a:node.children), 'v:val.id')) . ', '
        \ 'lnums: ' . string(a:node.lnums) . '}'
  return
endfunction

" }}}
