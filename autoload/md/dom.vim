" This file contains functions for building and querying a tree model of the heading structure of a markdown file.

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

""""""""""""
" Utilities
"""""""""""

" Coerce lnum to an integer
function! s:lineAsNum(lnum)
  if type(a:lnum) ==# 0
    return a:lnum
  else
    return line(a:lnum)
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

" Get the heading level of the line at lnum (i.e. 1 for '# foo', 2 for '## foo', etc.
" Returns 0 if the line is not a heading.
function! s:headingLevel(lnum)
  let line = getline(a:lnum)
  " Check if the line is a hash heading (##, ###, etc.), and return the count
  " of hashes if it is
  if s:strIsHashHeading(line)
    return len(matchstr(line, '^##*\ze\s'))
  endif
  " Check if the line is a heading underline (either == or --).
  if !(s:strIsEmpty(line) || s:strIsListItem(line))
    let nextLine = getline(s:lineAsNum(a:lnum) + 1)
    if s:strIsHeadingUnderline(nextLine)
      " This is a heading underline, so we return the level based on the
      " underline character used.
      return line[0] ==# '=' ? 1 : 2
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
" - lines:    List of line numbers that this node represents (including the content of the section)
function! s:node_new(id, level)
  return {
        \ 'id': a:id,
        \ 'parent': 0,
        \ 'level': a:level,
        \ 'children': [],
        \ 'lines': []
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
  echom '{id: ' . a:node.id 
        \ . ', level: ' . a:node.level 
        \ . ', parentId: ' . ((type(a:node.parent) == type({}) && has_key(a:node.parent, 'id')) ? a:node.parent.id : 'n/a') 
        \ . ', children: ' .string(map(a:node.children, 'v:val.id'))
        \ . ', lines: ' . string(map(a:node.lines, 'v:val')) . '}'
  return
endfunction

"""""""""""""""""""""""""""""""""""""""
" Functions for handling "tree" objects
"""""""""""""""""""""""""""""""""""""""

" Create a new tree object. This will represent the entire heading structure of a document.
" nodeIdToNode:    mapping from node ID to nodes
" linesToNodeId:   mapping from line number to the node at that line
" maxId:           the largest ID yet created
" latestNodeId:    the ID of the most recent node we added
" root:            a node representing the root of the document
function! s:tree_new()
  let root = s:node_new(0, 0)
  return { 'nodeIdToNode': {'0': root},
        \  'linesToNodeId': {},
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
function! s:tree_newNode(tree, line, level)
  " create an orphaned node
  let a:tree.maxId += 1
  let node = s:node_new(a:tree.maxId, a:level)
  " wire it to the node id index
  let a:tree.nodeIdToNode[a:tree.maxId] = node
  " wire it to the line index and add the current line to it's lines
  let node.lines += [a:line]
  let a:tree.linesToNodeId[a:line] = node.id
  " setup parentage, and set the new node to be the current parent
  let parent = s:tree_findParentForChild(a:tree, node)
  call s:node_addChild(parent, node)
  let a:tree.latestNodeId = node.id
  return
endfunction

" adds a pointer from a line to the last node we added (i.e. because a:line is still part of the current last
" node), and adds the current line to the latest node.
function! s:tree_newLine(tree, line)
  let a:tree.linesToNodeId[a:line] = a:tree.latestNodeId
  let node = s:tree_latestNode(a:tree)
  let node.lines += [a:line]
  return
endfunction

" Get a node by its ID from the tree.
function! s:tree_getNodeById(tree, id)
  return a:tree.nodeIdToNode[a:id]
endfunction

" get node at line. This will return the closest heading node above the given
" line, or the root node if line is before the first heading in the document
function! s:tree_getNodeAtLine(tree, line)
  let nodeId = a:tree.linesToNodeId[a:line]
  return s:tree_getNodeById(a:tree, nodeId)
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public API for querying the dom of the current buffer
"""""""""""""""""""""""""""""""""""""""""""""""""""""""

" scan the lines in a document to build the tree, and store it in buffer state.
function! md#dom#refreshDocumentTree()
  let tree = s:tree_new()
  for line in range(1, line('$'))
    let level = s:headingLevel(line)
    if level
      call s:tree_newNode(tree, line, level)
    else
      call s:tree_newLine(tree, line)
    endif
  endfor
  let b:dom = tree
  return
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""
" Functions that always return a heading level.
"""""""""""""""""""""""""""""""""""""""""""""""

""""""""""""""""""""""""""""""""""""
" Functions that return line numbers
""""""""""""""""""""""""""""""""""""

" These return line numbers of headings with specific relationships to the
" heading at lnum, or -1 if there is no such heading.

" Return the line number of the parent heading of the line at lnum.
function! md#dom#parentHeadingLine(lnum)
  let lnum = s:lineAsNum(a:lnum)
  let node = s:tree_getNodeAtLine(b:dom, lnum)
  " If the line or parent are the root node, return -1
  if node.id == 0 || node.parent.id == 0
    return -1
  endif
  return node.parent.lines[0]
endfunction

" Return the line number of the first child heading of the line at lnum.
" If there are no child headings, return -1.
function! md#dom#firstChildHeadingLine(lnum)
  let lnum = s:lineAsNum(a:lnum)
  let node = s:tree_getNodeAtLine(b:dom, lnum)
  if empty(node.children)
    return -1
  endif
  return node.children[0].lines[0]
endfunction

" Return a list of all heading lines in the document.
" If there are no headings, return an empty list.
function! s:allHeadingLines()
  let headings = []
  for nodeId in keys(b:dom.nodeIdToNode)
    let node = b:dom.nodeIdToNode[nodeId]
    if node.level > 0
      call add(headings, node.lines[0])
    endif
  endfor
  return headings
endfunction

" Return the last heading line before lnum or -1 if there is no such heading.
function! md#dom#headingLineBefore(lnum)
  let headings = s:allHeadingLines()
  let lnum = s:lineAsNum(a:lnum)
  let previousHeadings = filter(headings, 'v:val < lnum')
  if empty(previousHeadings)
    return -1
  endif
  return max(previousHeadings)
endfunction

" Return the next heading line after lnum or -1 if there is no such heading.
function! md#dom#headingLineAfter(lnum)
  let headings = s:allHeadingLines()
  let lnum = s:lineAsNum(a:lnum)
  let nextHeadings = filter(headings, 'v:val > lnum')
  if empty(nextHeadings)
    return -1
  endif
  return min(nextHeadings)
endfunction

" Return a list of all child headings of the lnum's parent heading.
" If there are no child headings, return an empty list.
function! s:siblingHeadingLines(lnum)
  let lnum = s:lineAsNum(a:lnum)
  let node = s:tree_getNodeAtLine(b:dom, lnum)
  let siblings = []
  for sibling in node.parent.children
    if sibling.id != node.id && sibling.level > 0
      call add(siblings, sibling.lines[0])
    endif
  endfor
  return siblings
endfunction

" Return the line number of the previous sibling heading of the line at lnum.
" If there is no previous sibling, return -1.
function! md#dom#siblingHeadingLineBefore(lnum)
  let lnum = s:lineAsNum(a:lnum)
  let siblings = s:siblingHeadingLines(lnum)
  if empty(siblings)
    throw "MDPP: Tree is corrupted. This is a bug" 
  endif
  let previousSibling = filter(siblings, 'v:val < lnum')
  if empty(previousSibling)
    return -1
  else
    return max(previousSibling)
  endif
endfunction

" Return the line number of the next sibling heading of the line at lnum.
" If there is no next sibling, return -1.
function! md#dom#siblingHeadingLineAfter(lnum)
  let lnum = s:lineAsNum(a:lnum)
  let siblings = s:siblingHeadingLines(lnum)
  if empty(siblings)
    throw "MDPP: Tree is corrupted. This is a bug"
  endif
  let nextSibling = filter(siblings, 'v:val > lnum')
  if empty(nextSibling)
    return -1
  else
    return min(nextSibling)
  endif
endfunction
