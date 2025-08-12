" This file should depend be the only one using the tree/node api in md#node
" It exposes an API for querying a markdown document using line numbers

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

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Construct a tree model of the document, stored in buffer local state
" throughout this module.
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! md#dom#refreshDocument()
  call s:buildDom()
endfunction

function! s:buildDom()
  let tree = md#node#buildTree()
  let b:dom = { 'root': tree.root, 'allNodes': tree.nodes }
  let b:dom.lnumsToNode = s:buildLnumIndex(b:dom.allNodes)
  return
endfunction

function! s:buildLnumIndex(nodes)
  let lnumsToNode = {}
  " collect all the nodes from root
  for node in a:nodes
    for lnum in md#node#getLnums(node, 0)
      let lnumsToNode[lnum] = node
    endfor
  endfor
  return lnumsToNode
endfunction

"""""""""""""""""""""""""
" Node fetching functions
"""""""""""""""""""""""""

" The rest of this module operates on Nodes from the md#node api, retrieved
" from the DOM using these two functions

" get the node that includes a:line a:lnum
function s:getNodeAtLine(line)
  let lnum = md#line#lineAsNum(a:line)
  return b:dom.lnumsToNode[lnum]
endfunction

" return a sorted list of all the nodes in the current buffer.
function s:allNodes()
  return b:dom.allNodes
endfunction

"""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions that always return a list of line numbers
"""""""""""""""""""""""""""""""""""""""""""""""""""""

" Return a list of line numbers for all headings in the document.
" If there are no headings, return an empty list.
function! s:allHeadingLnums()
  let headings = []
  for node in s:allNodes()
    if md#node#hasHeading(node)
      call add(headings, md#node#headingLnum(node))
    endif
  endfor
  return headings
endfunction

" Return a list of line numbers for all the headings from childrem of the node
" at a:line. If there are no child headings, return an empty list. This
" shouldn't happen, since at the very least, every node should be in it's own
" sibling list.
function! s:siblingHeadingLnums(line)
  let node = s:getNodeAtLine(a:line)
  let siblings = []
  for sibling in md#node#getSiblings(node)
    if md#node#hasHeading(sibling)
      call add(siblings, md#node#headingLnum(sibling))
    endif
  endfor
  return siblings
endfunction

" Return a list of lnums for the document section that includes a:line. It
" should not be possible for a section's lnums to be empty.
function! md#dom#sectionLnums(line, withDescendents)
  let node = s:getNodeAtLine(a:line)
  let lnums = md#node#getLnums(node, a:withDescendents)
  return lnums
endfunction

" Return a list of _content_ lines for the section at line a:line (i.e. all
" lines, not including the section heading.
function! md#dom#contentLnums(line, withDescendents)
  let lnums = md#dom#sectionLnums(a:line, a:withDescendents)
  if len(lnums) == 1
    return []
  endif
  return lnums[1:-1]
endfunction

""""""""""""""""""""""""""""""""""""""
" Functions that return heading levels
""""""""""""""""""""""""""""""""""""""

" return the heading level of the document section that contains a:line
function! md#dom#sectionLevel(line)
  let node = s:getNodeAtLine(a:line)
  return md#node#getHeadingLevel(node)
endfunction

""""""""""""""""""""""""""""""""""""""""""""
" Functions that return heading line numbers
""""""""""""""""""""""""""""""""""""""""""""

" These return line numbers of headings with specific relationships to the
" heading at the given line argument, or -1 if there is no such heading.

" Return the line number from the heading of the document section containing
" a:line, or -1 if this section has no heading (i.e. if line is before teh
" first heading in the document)
function! md#dom#sectionHeadingLnum(line)
  let node = s:getNodeAtLine(a:line)
  return md#node#headingLnum(node)
endfunction

" Return the line number of the parent heading of the line at line. If line is
" a content line, this is the line number from the section heading. If line is
" a heading line, it'a the parent node's heading
function! md#dom#parentHeadingLnum(line)
  let lnum = md#line#lineAsNum(a:line)
  let node = s:getNodeAtLine(lnum)
  let thisSectionHeadingLnum = md#node#headingLnum(node)
  " If this section has a heading, and we're not on that line, then we're
  " inside the heading, so we looking for this section heading
  if md#node#hasHeading(node) && thisSectionHeadingLnum != lnum
    return thisSectionHeadingLnum
  endif
  " Otherwise, if there's a parent node with a heading, we want that heading
  if md#node#hasParent(node) && md#node#hasHeading(md#node#getParent(node))
    return md#node#headingLnum(md#node#getParent(node))
  endif
  return -1
endfunction

" Return the line number of the first child heading of a:line.
" If there are no child headings, return -1.
function! md#dom#firstChildHeadingLnum(line)
  let node = s:getNodeAtLine(a:line)
  let children = md#node#getChildren(node)
  if empty(children)
    return -1
  endif
  return md#node#headingLnum(children[0])
endfunction

" returns the last line from a:candidateLines before a:line, or -1 if there is
" no such line
function! s:lastLnumBefore(candidateLines, line)
  let lnum = md#line#lineAsNum(a:line)
  let candidatesBefore = filter(a:candidateLines, 'v:val < lnum')
  if empty(candidatesBefore)
    return -1
  endif
  return max(candidatesBefore)
endfunction

" returns the first line from a:candidateLines after a:line, or -1 if there is
" no such line
function! s:firstLnumAfter(candidateLines, line)
  let lnum = md#line#lineAsNum(a:line)
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

""""""""""""""""""""""""""""""""""
" Functions that update the buffer
""""""""""""""""""""""""""""""""""
" Apply a:updateFn to the node at line. If a:withDescendents is true, the function will also be applied to all
" descendents too. The tree is walked in reverse (from the bottom of the buffer to the top), so that you can
" safely delete lines in a:updateFn without worrying about refreshing the buffer tree.
"
" This function doesn't return anything. It's intended to be used for side effects.
function! s:updateTree(startingNode, updateFn, withDescendents)
  if a:withDescendents
    " update in reverse, so that we can delete lines without messing up the line numbers for later lines
    for node in reverse(md#node#getDescendents(a:startingNode))
      call a:updateFn(node)
    endfor
  else
    call a:updateFn(a:startingNode)
  endif
  return
endfunction

function! md#dom#incDescendentHeadings(line, withDescendents)
  let startingNode = s:getNodeAtLine(a:line)
  let l:IncFunction = function('md#node#incrementHeading')
  call s:updateTree(startingNode, l:IncFunction, a:withDescendents)
endfunction

function! md#dom#decDescendentHeadings(line, withDescendents)
  let startingNode = s:getNodeAtLine(a:line)
  let l:DecFunction = function('md#node#decrementHeading')
  call s:updateTree(startingNode, l:DecFunction, a:withDescendents)
endfunction

" Nest the section at a:line, by incrementing the headers, cascading to the
" children, and then creating a new heading above the starting node
function! md#dom#nestSection(line)
  let startingNode = s:getNodeAtLine(a:line)
  let headingLevel = md#node#getHeadingLevel(startingNode)
  let l:IncFunction = function('md#node#incrementHeading')
  call s:updateTree(startingNode, l:IncFunction, 1)
  call md#node#prependNewHeading(startingNode, headingLevel)
endfunction
