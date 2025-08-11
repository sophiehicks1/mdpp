" This file contains functions for building and querying a tree model of the heading structure of a markdown file. """""""""""
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

function! s:strIsEmpty(lineStr)
  " Check if the line is empty or contains only whitespace.
  return a:lineStr =~ '^\s*$'
endfunction

function! s:strIsHashHeading(lineStr)
  " Check if the line starts with a hash followed by spaces.
  return a:lineStr =~ '^##*\s'
endfunction

function! s:strIsHeadingUnderline(lineStr)
  " Check if the line is a heading underline (either == or --).
  return a:lineStr =~ '^[=-][=-]*$'
endfunction

function! s:strIsListItem(lineStr)
  " Check if the line is a list item (starts with - or * followed by space).
  return a:lineStr =~ '^\s*[-*]\s'
endfunction

" Get the heading level of the line at lnum.
" Returns 0 if the line is not a heading.
function! s:headingLevel(lnum)
  let line = getline(a:lnum)
  " Check if the line is a hash heading (##, ###, etc.).
  if s:strIsHashHeading(line)
    return len(matchstr(line, '^##*\ze\s'))
  endif
  " Check if the line is a heading underline (either == or --).
  if !(s:strIsEmpty(line) || s:strIsListItem(line))
    let nextLine = getline(s:lineAsNum(a:lnum) + 1)
    if s:strIsHeadingUnderline(nextLine)
      " This is a heading underline, so we return the level based on the underline.
      return line[0] ==# '=' ? 1 : 2
    endif
  endif
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

"""""""""""""""""""""""""""""""""""""""
" Functions for handling "tree" objects
"""""""""""""""""""""""""""""""""""""""

" Create a new tree object. This will represent the entire heading structure of a document.
function! s:tree_new()
  " nodeIdToNode:    mapping from node ID to nodes
  " linesToNodeId:   mapping from line number to the node at that line
  " maxId:           the largest ID yet created
  " latestNodeId: the ID of the node we're currently assigning children to
  " root:            a node representing the root of the document
  let root = s:node_new(0, 0)
  return { 'nodeIdToNode': {'0': root},
        \  'linesToNodeId': {},
        \  'maxId': 0,
        \  'latestNodeId': 0,
        \  'root': root }
endfunction

" return the current parent node
function! s:tree_latestNode(tree)
  return a:tree.nodeIdToNode[a:tree.latestNodeId]
endfunction

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
  " create an orphan node
  let a:tree.maxId += 1
  let node = s:node_new(a:tree.maxId, a:level)
  " wire it to the node id index
  let a:tree.nodeIdToNode[a:tree.maxId] = node
  " wire it to the line index and update its lines
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

function! s:tree_getNodeById(tree, id)
  " Get a node by its ID from the tree.
  return a:tree.nodeIdToNode[a:id]
endfunction

" get node at line
function! s:tree_getNodeAtLine(tree, line)
  let nodeId = a:tree.linesToNodeId[a:line]
  return s:tree_getNodeById(a:tree, nodeId)
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Public API for querying the dom of the current buffer
"""""""""""""""""""""""""""""""""""""""""""""""""""""""

" This API interacts exclusively with a representation of the document structure, stored in buffer local
" state. No attempt is made to update that state when the file is changed, so you should generally refresh the
" document tree any time it's possible the buffer content may have changed.

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

function! md#dom#parentHeadingLine(lnum)
  let lnum = s:lineAsNum(a:lnum)
  return s:tree_getNodeAtLine(b:dom, lnum).parent.lines[0]
endfunction

function! md#dom#headingLevel(lnum)
  let lnum = s:lineAsNum(a:lnum)
  let node = s:tree_getNodeAtLine(b:dom, lnum)
  return node.level
endfunction

" Return a list of all heading lines in the document.
function! md#dom#allHeadingLines()
  let headings = []
  for nodeId in keys(b:dom.nodeIdToNode)
    let node = b:dom.nodeIdToNode[nodeId]
    if node.level > 0
      call add(headings, node.lines[0])
    endif
  endfor
  return headings
endfunction
