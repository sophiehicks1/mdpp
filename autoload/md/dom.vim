" This file contains functions for building and querying a tree model of the
" heading structure of a markdown file.
"
" TODO
" - change the use of the 'lnum' and 'line' names, so that line is either Int
"   or string, and lnum is always a number. That way, I don't need to call
"   s:lineAsNum so much, and expectations are clear

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"             ___                            _              _   _              "
"            |_ _|_ __ ___  _ __   ___  _ __| |_ __ _ _ __ | |_| |             "
"             | || '_ ` _ \| '_ \ / _ \| '__| __/ _` | '_ \| __| |             "
"             | || | | | | | |_) | (_) | |  | || (_| | | | | |_|_|             "
"            |___|_| |_| |_| .__/ \___/|_|   \__\__,_|_| |_|\__(_)             "
"                          |_|                                                 "
"                                                                              "
" This API interacts exclusively with a representation of the document         "
" structure stored in buffer local state. No attempt is made to update that    "
" state when the file is changed outside this file, so you are responsible for "
" refreshing the document tree any time it's possible the buffer content may   "
" have changed.                                                                "
"                                                                              "
" It takes about 0.24s to fully parse a 10k line file with 740 headings in it, "
" so any reasonable file should complete fast enough that it's not a           "
" significant delay.                                                           "
"                                                                              "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Conventions used in this file:
" - when referencing lines:
"   - `line` can be either an integer line number, or a string representing a
"      line (e.g. '.')
"   - `lnum` is an integer line number.
"   - `lineStr` is a string, representing the _content_ of a line.
" - `s:node_*` functions and `s:tree_*` functions always expect and return exclusively lnums
" - public APIs accept lines, and return lnums
" - other internal functions should accept lines where possible, and are responsible
"   for internally converting to lnums when necessary
" - I miss static type checking.

""""""""""""
" Utilities
"""""""""""

" Coerce lnum to an integer
function! s:lineAsNum(line)
  if type(a:line) ==# 0
    return a:line
  else
    return line(a:line)
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""
" functions for parsing individual lines
""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Check if the line is empty or contains only whitespace.
function! s:strIsEmpty(lineStr)
  return a:lineStr =~ '^\s*$'
endfunction

" Check if the line starts with a hash followed by spaces.
function! s:strIsHashHeading(lineStr)
  return a:lineStr =~ '^##*\s'
endfunction

" Check if the line is a heading underline (either == or --).
function! s:strIsHeadingUnderline(lineStr)
  return a:lineStr =~ '^[=-][=-]*$'
endfunction

" Check if the line is a list item (starts with - or * followed by space).
function! s:strIsListItem(lineStr)
  return a:lineStr =~ '^\s*[-*]\s'
endfunction

" Get the heading level of the line at line (i.e. 1 for '# foo', 2 for '## foo', etc.
" Returns 0 if the line is not a heading.
function! s:headingLevel(line)
  let lineStr = getline(a:line)
  " Check if the lineStr is a hash heading (##, ###, etc.), and return the count
  " of hashes if it is
  if s:strIsHashHeading(lineStr)
    return len(matchstr(lineStr, '^##*\ze\s'))
  endif
  " Check if the lineStr is a heading underline (either == or --).
  if !(s:strIsEmpty(lineStr) || s:strIsListItem(lineStr))
    let nextLine = getline(s:lineAsNum(a:line) + 1)
    if s:strIsHeadingUnderline(nextLine)
      " This is a heading underline, so we return the level based on the
      " underline character used.
      return lineStr[0] ==# '=' ? 1 : 2
    endif
  endif
  " If we get here, it's not a heading.
  return 0
endfunction

"""""""""""""""""""""""""""""""""""""""
" Functions for handling "node" objects
"""""""""""""""""""""""""""""""""""""""

" Create a new node object, that will be stored in the tree. Each node object represents a heading line in the
" document.
" Fields:
" - id:       Integer ID of the node, unique within the tree
" - parent:   Node object of the parent, or 0 if this is the root
" - level:    Integer heading level (1 for h1, 2 for h2, etc.)
" - children: List of child nodes (List<Node>)
" - lnums:    List of line numbers that this node represents (including the content of the section)
function! s:node_new(id, level)
  return {
        \ 'id': a:id,
        \ 'parent': 0,
        \ 'level': a:level,
        \ 'children': [],
        \ 'lnums': []
        \ }
endfunction

" Wire a parent and child to each other
function! s:node_addChild(parent, child)
  let a:parent.children += [a:child]
  let a:child.parent = a:parent
endfunction

" Print a node object for debugging purposes. This is needed, because the raw
" node objects contain self references (because parent links to child, and
" child links to parent)
function! s:node_debugPrint(node)
  let parent_id = ((type(a:node.parent) == type({}) && has_key(a:node.parent, 'id')) ? a:node.parent.id : 'n/a') 
  echom '{id: ' . a:node.id . ', '
        \ 'level: ' . a:node.level . ', '
        \ 'parentId: ' . parent_id . ', '
        \ 'children: ' . string(map(copy(a:node.children), 'v:val.id')) . ', '
        \ 'lnums: ' . string(a:node.lnums) . '}'
  return
endfunction

"""""""""""""""""""""""""""""""""""""""
" Functions for handling "tree" objects
"""""""""""""""""""""""""""""""""""""""

" Create a new tree object. This will represent the entire heading structure of a document.
" nodeIdToNode:    mapping from node ID to nodes
" lnumsToNodeId:   mapping from integer line number to the node at that line
" maxId:           the largest ID yet created
" latestNodeId:    the ID of the most recent node we added
" root:            a node representing the root of the document
function! s:tree_new()
  let root = s:node_new(0, 0)
  return { 'nodeIdToNode': {'0': root},
        \  'lnumsToNodeId': {},
        \  'maxId': 0,
        \  'latestNodeId': 0,
        \  'root': root }
endfunction

" return the most recently added node
function! s:tree_latestNode(tree)
  return a:tree.nodeIdToNode[a:tree.latestNodeId]
endfunction

" Find the right parent for a new child. Parent nodes must have level smaller,
" than their childrem, so we find the right node by starting at the most recent node, and
" climbing the tree until we find a node that has a low enough heading level
" to be newChild's parent node.
function! s:tree_findParentForChild(tree, newChild)
  let childLevel = a:newChild.level
  let parent = s:tree_latestNode(a:tree)
  " Climb up the tree until we find a parent that is at a lower level than the child
  while parent.id != 0 && childLevel <= parent.level
    let parent = parent.parent
  endwhile
  return parent
endfunction

" creates a new node object, and wires it into the tree
function! s:tree_newNode(tree, lnum, level)
  " create an orphaned node
  let a:tree.maxId += 1
  let node = s:node_new(a:tree.maxId, a:level)
  " wire it to the node id index
  let a:tree.nodeIdToNode[a:tree.maxId] = node
  " wire it to the lnum index and add the current line to its lnums
  let node.lnums += [a:lnum]
  let a:tree.lnumsToNodeId[a:lnum] = node.id
  " setup parentage, and set the new node to be the current parent
  let parent = s:tree_findParentForChild(a:tree, node)
  call s:node_addChild(parent, node)
  let a:tree.latestNodeId = node.id
  return
endfunction

" adds a pointer from an lnum to the last node we added (i.e. because a:lnum is still part of the current last
" node), and adds the current lnum to the latest node.
function! s:tree_newLine(tree, lnum)
  let a:tree.lnumsToNodeId[a:lnum] = a:tree.latestNodeId
  let node = s:tree_latestNode(a:tree)
  let node.lnum += [a:lnum]
  return
endfunction

" Get a node by its ID from the tree.
function! s:tree_getNodeById(tree, id)
  return a:tree.nodeIdToNode[a:id]
endfunction

" get node at lnum. This will return the closest heading node above the given
" lnum, or the root node if lnum is before the first heading in the document
function! s:tree_getNodeAtLnum(tree, lnum)
  let nodeId = a:tree.lnumsToNodeId[a:lnum]
  return s:tree_getNodeById(a:tree, nodeId)
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public API for querying the dom of the current buffer
"""""""""""""""""""""""""""""""""""""""""""""""""""""""

" scan the lines in a document to build the tree, and store it in buffer state.
function! md#dom#refreshDocumentTree()
  let tree = s:tree_new()
  for lnum in range(1, line('$'))
    let level = s:headingLevel(line)
    if level
      call s:tree_newNode(tree, lnum, level)
    else
      call s:tree_newLine(tree, lnum)
    endif
  endfor
  let b:dom = tree
  return
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions that always return a list of line numbers
"""""""""""""""""""""""""""""""""""""""""""""""""""""

" Return a list of all heading lnums in the document.
" If there are no headings, return an empty list.
function! s:allHeadingLnums()
  let headings = []
  for nodeId in keys(b:dom.nodeIdToNode)
    let node = b:dom.nodeIdToNode[nodeId]
    if node.level > 0
      call add(headings, node.lnums[0])
    endif
  endfor
  return headings
endfunction

" Return a list of all child heading lnums of the a:line's parent heading.
" If there are no child headings, return an empty list. This shouldn't happen,
" since at the very least, the starting node should be in it's own sibling
" list.
function! s:siblingHeadingLnums(line)
  let lnum = s:lineAsNum(a:line)
  let node = s:tree_getNodeAtLnum(b:dom, lnum)
  let siblings = []
  for sibling in node.parent.children
    call add(siblings, sibling.lnums[0])
  endfor
  return siblings
endfunction

" add all the lnums from node to the list acc, including node's children's
" lnums
function! s:addNodeLnumsRecursive(acc, node)
  let acc = a:acc + a:node.lnums
  for child in a:node.children
    let acc += s:addNodeLnumsRecursive(a:acc, child)
  endfor
  return acc
endfunction

" Return a list of lnums for the document section that includes a:line. It
" should not be possible for a section's lnums to be empty.
function! md#dom#sectionLnums(line, withChildren)
  let lnum = s:lineAsNum(a:line)
  let node = s:tree_getNodeAtLnum(b:dom, lnum)
  let lnums = []
  " TODO try changing this to `call s:add...(lnums, node)
  if a:withChildren
    let lnums += s:addNodeLnumsRecursive([], node)
  else
    let lnums += node.lnums
  endif
  return lnums
endfunction

" Return a list of _content_ lines for the section at line lnum (i.e. all
" lines, not including the section heading.
function! md#dom#contentLnums(line, withChildren)
  let lnums = md#dom#sectionLnums(a:line, a:withChildren)
  if len(lnums) == 1
    return []
  endif
  return lnums[1:-1]
endfunction

""""""""""""""""""""""""""""""""""""""
" Functions that return heading levels
""""""""""""""""""""""""""""""""""""""

" return the heading level of the section that contains a:line
function! md#dom#sectionLevel(line)
  let lnum = s:lineAsNum(a:line)
  let node = s:tree_getNodeAtLnum(b:dom, lnum)
  return node.level
endfunction

""""""""""""""""""""""""""""""""""""
" Functions that return line numbers
""""""""""""""""""""""""""""""""""""

" These return line numbers of headings with specific relationships to the
" heading at lnum, or -1 if there is no such heading.

" Return the line number from the heading of the section containing a:line. If
" a:line is a heading, then it is the section heading.
function! md#dom#sectionHeadingLnum(line)
  let lnum = s:lineAsNum(a:line)
  let node = s:tree_getNodeAtLnum(b:dom, lnum)
  return node.lnums[0]
endfunction

" Return the line number of the parent heading of the line at line. If line is
" a content line, this is the line number from the section heading. If line is
" a heading line, it'a the parent node's heading
function! md#dom#parentHeadingLnum(line)
  let lnum = s:lineAsNum(a:line)
  let node = s:tree_getNodeAtLnum(b:dom, lnum)
  " If heading level is 0, then we're inside a section. Return the
  " heading of the current node
  if s:headingLevel(lnum) == 0
    return node.lnums[0]
  endif
  " If the line or parent are the root node, return -1
  if node.id == 0 || node.parent.id == 0
    return -1
  endif
  return node.parent.lnums[0]
endfunction

" Return the line number of the first child heading of a:line.
" If there are no child headings, return -1.
function! md#dom#firstChildHeadingLnum(line)
  let lnum = s:lineAsNum(a:line)
  let node = s:tree_getNodeAtLnum(b:dom, lnum)
  if empty(node.children)
    return -1
  endif
  return node.children[0].lnums[0]
endfunction

" returns the last line from a:candidateLines before a:lnum, or -1 if there is
" no such line
function! s:lastLnumBefore(candidateLines, line)
  let lnum = s:lineAsNum(a:line)
  let candidatesBefore = filter(a:candidateLines, 'v:val < lnum')
  if empty(candidatesBefore)
    return -1
  endif
  return max(candidatesBefore)
endfunction

" returns the first line from a:candidateLines after a:line, or -1 if there is
" no such line
function! s:firstLnumAfter(candidateLines, line)
  let lnum = s:lineAsNum(a:line)
  let candidatesAfter = filter(a:candidateLines, 'v:val > lnum')
  if empty(candidatesAfter)
    return -1
  endif
  return min(candidatesAfter)
endfunction

" Return the last heading lnum before a:line or -1 if there is no such heading.
function! md#dom#headingLnumBefore(line)
  return s:lastLnumBefore(s:allHeadingLnums(), a:line)
endfunction

" Return the next heading lnum after a:line or -1 if there is no such heading.
function! md#dom#headingLnumAfter(line)
  return s:firstLnumAfter(s:allHeadingLnums(), a:line)
endfunction

" Return the line number of the previous sibling heading of the line at a:line.
" If there is no previous sibling, return -1.
function! md#dom#siblingHeadingLnumBefore(line)
  return s:lastLnumBefore(s:siblingHeadingLnums(a:line), a:line)
endfunction

" Return the line number of the next sibling heading of the line at a:line.
" If there is no next sibling, return -1.
function! md#dom#siblingHeadingLnumAfter(line)
  return s:firstLnumAfter(s:siblingHeadingLnums(a:line), a:line)
endfunction
