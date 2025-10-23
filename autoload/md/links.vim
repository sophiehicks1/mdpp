"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" s:find___LinksInText {{{

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
      let alias = wiki_content[pipe_pos + 1 : -1]
      let display_text = alias
      let target_start_col = wiki_start + 3
      let target_end_col = wiki_start + 2 + pipe_pos
      let text_start_col = wiki_start + 3 + pipe_pos + 1
      let text_end_col = wiki_end
    else
      " No alias: [[Target]]
      let target = wiki_content
      let alias = ''
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
          \ 'alias': alias,
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

    " Find the reference definition
    let ref_info = s:findReferenceDefinitionInfo(reference)

    let link_info = {
          \ 'type': 'reference',
          \ 'line_num': a:temp_line_num,
          \ 'start_col': bracket_start + 1,
          \ 'end_col': ref_end + 1,
          \ 'text': text,
          \ 'text_start_col': bracket_start + 2,
          \ 'text_end_col': bracket_end,
          \ 'reference': reference,
          \ 'full_start_col': bracket_start + 1,
          \ 'full_end_col': ref_end + 1
          \ }

    if !empty(ref_info)
      let link_info.target = ref_info.target
      let link_info.target_start_line = ref_info.line_num
      let link_info.target_start_col = ref_info.target_start_col
      let link_info.target_end_col = ref_info.target_end_col
      let link_info.target_end_line = ref_info.line_num
    else
      " FIXME this is causing target_start_line et al to be optional
      let link_info.target = ''
    endif

    call add(links, link_info)
    let pos = ref_end + 1
  endwhile

  return links
endfunction

" }}}

" md#links#findLinkAtPos(pos) {{{

" Find the link that contains the given position
" Returns a dictionary with link information or {} if no link found
function! md#links#findLinkAtPos(pos)
  let line_num = a:pos[1]
  let col_num = a:pos[2]

  " First check if we're on a reference definition line
  let ref_def_info = s:findReferenceDefinitionAtPosition(line_num, col_num)
  if !empty(ref_def_info)
    " Find the first link that references this definition
    let referring_link = s:findFirstReferringLink(ref_def_info.reference)
    if !empty(referring_link)
      return referring_link
    endif
    " If no referring link found, fall back to treating as regular reference definition
    return ref_def_info
  endif

  " Try to find a wiki link
  let wiki_link = s:findWikiLinkAtPosition(line_num, col_num)
  if !empty(wiki_link)
    return wiki_link
  endif

  " Try to find an inline link
  let inline_link = s:findInlineLinkAtPosition(line_num, col_num)
  if !empty(inline_link)
    return inline_link
  endif

  " Try to find a reference link
  let reference_link = s:findReferenceLinkAtPosition(line_num, col_num)
  if !empty(reference_link)
    return reference_link
  endif

  return {}
endfunction

" }}}

" find___LinkAtPosition {{{

function! s:findInlineLinkAtPosition(line_num, col_num)
  for link in md#links#findInlineLinksInLine(a:line_num)
    if s:posInsideLink(a:line_num, a:col_num, link)
      return link
    endif
  endfor
  return {}
endfunction

" Find wiki link at the given position
" Returns link info dict or {} if none found
function! s:findWikiLinkAtPosition(line_num, col_num)
  for link in md#links#findWikiLinksInLine(a:line_num)
    if s:posInsideLink(a:line_num, a:col_num, link)
      return link
    endif
  endfor
  return {}
endfunction

" Find reference link at the given position
" Returns link info dict or {} if none found
function! s:findReferenceLinkAtPosition(line_num, col_num)
  for link in md#links#findReferenceLinksInLine(a:line_num)
    if s:posInsideLink(a:line_num, a:col_num, link)
      return link
    endif
  endfor
  return {}
endfunction

" }}}

" md#links#find___LinksInLine {{{

" Returns list of link info dictionaries
" This now supports multi-line links (links that span to adjacent lines)
function s:genericFindLinksInLine(find_in_text_fn, line_num)
  " Join current line with previous and next lines
  let [joined_text, lengths] = s:joinThreeLines(a:line_num)

  " Find all links in the joined text
  let all_links = a:find_in_text_fn(joined_text, a:line_num)
  " Filter to only links that touch the target line
  let touching_links = []
  for link in all_links
    " Check if link touches target line (using 0-indexed positions)
    if s:linkTouchesTargetLine(link.start_col - 1, link.end_col - 1, lengths)
      " Adjust link info to correct line numbers and columns
      let adjusted_link = s:adjustLinkInfo(link, a:line_num, lengths)
      call add(touching_links, adjusted_link)
    endif
  endfor

  return touching_links
endfunction

" Find all inline links in a line - PUBLIC for testing
function! md#links#findInlineLinksInLine(line_num)
  return s:genericFindLinksInLine(function('<SID>findInlineLinksInText'), a:line_num)
endfunction

" Find all reference links in a line - PUBLIC for testing
function! md#links#findReferenceLinksInLine(line_num)
  return s:genericFindLinksInLine(function('<SID>findReferenceLinksInText'), a:line_num)
endfunction

" Find all wiki links in a line - PUBLIC for testing
function! md#links#findWikiLinksInLine(line_num)
  return s:genericFindLinksInLine(function('<SID>findWikiLinksInText'), a:line_num)
endfunction

" }}}

" Pure text/vim stuff {{{

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

" }}}

" Link dict helpers / getters / queries {{{

function! s:posInsideLink(line_num, col_num, link)
  let link_start_before_pos = a:link.line_num < a:line_num
        \ || a:link.line_num == a:line_num && a:link.start_col <= a:col_num
  let link_end_after_pos = a:link.full_end_line > a:line_num
        \ || a:link.full_end_line == a:line_num && a:link.end_col >= a:col_num
  return link_start_before_pos && link_end_after_pos
endfunction

function! s:isMultiLine(link)
  if has_key(a:link, 'end_line') && a:link.end_line > a:link.line_num
    return v:true
  endif
  return v:false
endfunction

" Get the text content of a link (what's between the [])
function! md#links#getLinkText(link_info)
  if empty(a:link_info)
    return ''
  endif
  return a:link_info.text
endfunction

" Get the target of a link
function! md#links#getLinkTarget(link_info)
  if empty(a:link_info)
    return ''
  endif
  return a:link_info.target
endfunction

" Get position range for link text selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkTextRange(link_info)
  if empty(a:link_info)
    return []
  endif
  " Use text_start_line and text_end_line if available (for multi-line links)
  let start_line = has_key(a:link_info, 'text_start_line') ? a:link_info.text_start_line : a:link_info.line_num
  let end_line = has_key(a:link_info, 'text_end_line') ? a:link_info.text_end_line : a:link_info.line_num
  return [start_line, a:link_info.text_start_col, end_line, a:link_info.text_end_col]
endfunction

" TODO make this generic
" - FIXME standardize the link object, so that all link objects use the same
"   fields for the same semantic purpose
" Get position range for link target selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkTargetRange(link_info)
  if empty(a:link_info)
    return []
  endif

  if a:link_info.type == 'inline'
    " Use target_start_line and target_end_line if available (for multi-line links)
    let start_line = has_key(a:link_info, 'target_start_line') ? a:link_info.target_start_line : a:link_info.line_num
    let end_line = has_key(a:link_info, 'target_end_line') ? a:link_info.target_end_line : a:link_info.line_num
    return [start_line, a:link_info.target_start_col, end_line, a:link_info.target_end_col]
  elseif a:link_info.type == 'wiki'
    " For wiki links, return the target portion
    let start_line = has_key(a:link_info, 'target_start_line') ? a:link_info.target_start_line : a:link_info.line_num
    let end_line = has_key(a:link_info, 'target_end_line') ? a:link_info.target_end_line : a:link_info.line_num
    return [start_line, a:link_info.target_start_col, end_line, a:link_info.target_end_col]
  elseif a:link_info.type == 'reference'
    " For reference links, find the definition line
    if has_key(a:link_info, 'target_start_line')
      let start_line = a:link_info.target_start_line
      let end_line = a:link_info.target_end_line
      return [start_line, a:link_info.target_start_col, end_line, a:link_info.target_end_col]
    endif
  endif

  return []
endfunction

" Get position range for entire link selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkFullRange(link_info)
  if empty(a:link_info)
    return []
  endif
  " Use full_start_line and full_end_line if available (for multi-line links)
  let start_line = has_key(a:link_info, 'full_start_line') ? a:link_info.full_start_line : a:link_info.line_num
  let end_line = has_key(a:link_info, 'full_end_line') ? a:link_info.full_end_line : a:link_info.line_num
  return [start_line, a:link_info.full_start_col, end_line, a:link_info.full_end_col]
endfunction

" }}}

" Reference definition stuff {{{

" make a regex pattern to find a reference definition line. Reference should
" either be a reference id (e.g. 'foo' to find the reference definition for
" `[this link][foo]`) or an empty string to find any/all reference definitions)
"
" In both cases, the reference ID will be captured in the first group, and the
" target will be captured in the second.
function! s:makeReferencePattern(reference)
  let reference = escape(a:reference, '[]')
  if empty(reference)
    let reference = '[^\]]\+'
  endif
  return '^\s*\[\(' . reference . '\)\]:\s*\(\S\+\)'
endfunction

" Extract reference definition info from a specific line number
" Returns reference definition info dict or {} if none found
"
" The 'reference' argument is the reference ID to look for, or empty string
" to match any reference definition on that line.
function! s:extractReferenceFromLine(line_num, reference)
  let pattern = s:makeReferencePattern(a:reference)
  let line_content = getline(a:line_num)
  let match = matchlist(line_content, pattern)
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

function! s:findReferenceDefinitionInfo(reference)
  let line_num = 1
  let last_line = line('$')
  while line_num <= last_line
    let reference_info = s:extractReferenceFromLine(line_num, a:reference)
    if !empty(reference_info)
      return reference_info
    endif
    let line_num += 1
  endwhile
  return {}
endfunction

" Find reference definition at the given position
" Returns reference definition info dict or {} if none found
function! s:findReferenceDefinitionAtPosition(line_num, col_num)
  let reference_info = s:extractReferenceFromLine(a:line_num, '')
  if !empty(reference_info) && a:col_num <= reference_info.target_end_col
    return reference_info
  endif
  return {}
endfunction

" Find the first link that references the given reference label
" Returns link info dict or {} if none found
function! s:findFirstReferringLink(reference)
  let line_num = 1
  let last_line = line('$')

  while line_num <= last_line
    let links = md#links#findReferenceLinksInLine(line_num)

    for link in links
      if link.reference ==# a:reference
        return link
      endif
    endfor

    let line_num += 1
  endwhile

  return {}
endfunction

" }}}

" Line joining && and adjusting {{{

" Helper function to join three lines for multi-line link detection
" Returns: [joined_text, lengths_dict]
" Where lengths_dict contains:
"   - original_lengths: [len(prev_line), len(curr_line), len(next_line)]
"   - stripped_lengths: [len(prev_stripped), len(curr_line_stripped), len(next_stripped)]
"   - leading_spaces: [prev_spaces, curr_spaces, next_spaces]
function! s:joinThreeLines(line_num)
  let prev_line = s:getLineSafe(a:line_num - 1)
  let curr_line = s:getLineSafe(a:line_num)
  let next_line = s:getLineSafe(a:line_num + 1)

  " Strip structural indentation and markers from all lines
  " This handles list items, blockquotes, and other indented contexts

  " Handle previous line
  let [prev_stripped, prev_spaces] = s:stripStructuralMarkers(prev_line)

  " Handle current line
  let [curr_stripped, curr_spaces] = s:stripStructuralMarkers(curr_line)

  " Handle next line
  let [next_stripped, next_spaces] = s:stripStructuralMarkers(next_line)

  " Add spaces to continuation lines to correctly model line wrapping in
  " practice
  let curr_stripped = ' ' . curr_stripped
  let next_stripped = ' ' . next_stripped

  " Join lines without newlines (just concatenate)
  let joined = prev_stripped . curr_stripped . next_stripped

  " Return both original and stripped lengths for position mapping
  let lengths = {
        \ 'original_lengths': [len(prev_line), len(curr_line), len(next_line)],
        \ 'stripped_lengths': [len(prev_stripped), len(curr_stripped), len(next_stripped)],
        \ 'leading_spaces': [prev_spaces, curr_spaces, next_spaces]
        \ }

  return [joined, lengths]
endfunction

" Helper function to strip structural markers from a line
" Returns: [stripped_line, spaces_removed]
function! s:stripStructuralMarkers(line)
  if empty(a:line)
    return ['', 0]
  endif

  " Count leading whitespace
  let leading = matchstr(a:line, '^\s*')
  let spaces = len(leading)
  let content = a:line[spaces :]

  " Check for and strip structural markers
  " List markers: -, *, +, or numbered lists
  " Blockquote markers: >
  " But don't strip if the line starts with a list marker (it's a new item)
  let stripped = content
  let marker_len = 0

  " Strip blockquote markers (> ) recursively
  while stripped =~# '^>\s\?'
    let marker_match = matchstr(stripped, '^>\s\?')
    let marker_len += len(marker_match)
    let stripped = stripped[len(marker_match):]
  endwhile

  return [stripped, spaces + marker_len]
endfunction

" Helper function to determine if a position in joined text belongs to the target line
" pos is 0-indexed position in joined text
" lengths is the dict returned by s:joinThreeLines
" Returns: 1 if position is in current line, 0 otherwise
function! s:isInTargetLine(pos, lengths)
  let prev_len = a:lengths['stripped_lengths'][0]
  let curr_len = a:lengths['stripped_lengths'][1]
  return a:pos >= prev_len && a:pos < prev_len + curr_len
endfunction

" Helper function to check if a link (defined by start and end positions in joined text)
" touches the target line
" lengths is the dict returned by s:joinThreeLines
" Returns: 1 if link touches target line, 0 otherwise
function! s:linkTouchesTargetLine(link_start, link_end, lengths)
  let prev_len = a:lengths['stripped_lengths'][0]
  let curr_len = a:lengths['stripped_lengths'][1]
  let target_start = prev_len
  let target_end = prev_len + curr_len - 1

  " Link touches target line if:
  " - link starts before or in target line AND ends in or after target line
  return a:link_start <= target_end && a:link_end >= target_start
endfunction

" Helper function to convert a position in joined text to actual line/column
" pos is 0-indexed position in joined text
" line_num is the target line number
" lengths is the dict returned by s:joinThreeLines
" Returns: [line, col] where line is absolute and col is 1-indexed
function! s:posToLineCol(pos, line_num, lengths)
  let prev_len = a:lengths['stripped_lengths'][0]
  let curr_len = a:lengths['stripped_lengths'][1]
  let prev_spaces = a:lengths['leading_spaces'][0]
  let curr_spaces = a:lengths['leading_spaces'][1]
  let next_spaces = a:lengths['leading_spaces'][2]

  if a:pos < prev_len
    " Position is on previous line
    " Add back the leading spaces that were stripped
    return [a:line_num - 1, a:pos + prev_spaces + 1]
    " TODO vvv this can be simplified... the two branches are nearly identical
  elseif a:pos < prev_len + curr_len " Position is on current line
    let pos_in_curr = a:pos - prev_len

    " Current line always has a leading space
    if pos_in_curr == 0
      " Position is at the added space - map to first char after original whitespace
      return [a:line_num, curr_spaces + 1]
    else
      " Position is after the added space - subtract 1 and add back original spaces
      return [a:line_num, pos_in_curr - 1 + curr_spaces + 1]
    endif
  else " Position is on next line
    let pos_in_next_stripped = a:pos - prev_len - curr_len

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
  " Note: link_info columns are 1-indexed, so convert to 0-indexed first
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

  " For inline links, also adjust target columns
  if adjusted.type ==# 'inline'
    let target_start_pos = s:posToLineCol(a:link_info.target_start_col - 1, a:line_num, a:lengths)
    let target_end_pos = s:posToLineCol(a:link_info.target_end_col - 1, a:line_num, a:lengths)
    let adjusted.target_start_col = target_start_pos[1]
    let adjusted.target_end_col = target_end_pos[1]
    let adjusted.target_start_line = target_start_pos[0]
    let adjusted.target_end_line = target_end_pos[0]
  endif

  " For wiki links, also adjust target columns
  if adjusted.type ==# 'wiki'
    let target_start_pos = s:posToLineCol(a:link_info.target_start_col - 1, a:line_num, a:lengths)
    let target_end_pos = s:posToLineCol(a:link_info.target_end_col - 1, a:line_num, a:lengths)
    let adjusted.target_start_col = target_start_pos[1]
    let adjusted.target_end_col = target_end_pos[1]
    let adjusted.target_start_line = target_start_pos[0]
    let adjusted.target_end_line = target_end_pos[0]
  endif

  return adjusted
endfunction

" }}}
