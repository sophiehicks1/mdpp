" FIXME move everything to do with constructing the tree/node hierarchy into here

" FIXME rename this module to tree
" FIXME reorder and group the functions in this file so it makes more sense

" Functions for managing sections of a document. Each section is modeled as a
" node in a tree, with the following fields:
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

" Functions to build the DOM. This is the data structure that's exposed to the
" other modules

" scan the lines in a document to build the tree, and store it in buffer state.


function! s:headingLevelForNode(lnum)
  " lnum == 0 means it's the root node, so it has -1 heading level (i.e. it
  " can parent anything)
  if a:lnum == 0
    return -1
  endif
  return md#line#headingLevel(a:lnum)
endfunction

""""""""""""""""""""""""""""""
" Tree/Node Construction Logic
""""""""""""""""""""""""""""""

" Construct a tree of nodes, to represent markdown document structure.
function! md#node#buildTree()
  " The root node and it's children represent the entire document. By
  " definition it's the only node with no heading, since it contents only the
  " content lines before the first heading. All other nodes in the document
  " are children or descendents of the root node
  let root = s:newNode(0, 0)
  let nodes = [root]
  let lastNode = root
  " add the lines to the tree one by one
  for lnum in range(1, line('$'))
    " if the line is a heading, it's a new node
    if md#line#headingLevel(lnum)
      let node = s:newNode(lastNode.id + 1, lnum)
      call s:assignParent(node, lastNode)
      let nodes += [node]
      let lastNode = node
    else
      " otherwise we add the new line as content in the last node we added
      let lastNode.lnums += [lnum]
    endif
  endfor
  " return just the tree itself, since the rest of the state was only needed
  " for construction
  return { 'root': root, 'nodes': nodes }
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

" Wire a parent and child to each other during construction
function! s:addChild(parent, child)
  let a:parent.children += [a:child]
  let a:child.parent = a:parent
endfunction

" To assign a parent to a new node, we start with the last node we added and
" walk up the tree to find the first parent with a heading level low enough to
" add the new Node to it's children.
function! s:assignParent(newNode, candidateParent)
  let candidateParent = a:candidateParent
  while !s:canParent(candidateParent, a:newNode)
    if !md#node#hasParent(candidateParent)
      call md#node#debugPrint(a:newNode)
      throw "MDPP No parent found for newNode. This is a bug"
    endif
    let candidateParent = candidateParent.parent
  endwhile
  call s:addChild(candidateParent, a:newNode)
  return
endfunction

" parent must have a lower heading level than child (e.g. H2 cannot have an H1
" child)
function! s:canParent(parentNode, childNode)
  return a:parentNode.level < a:childNode.level
endfunction

"""""""""
" Getters
"""""""""

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

""""""""""""""""""
" Update functions
""""""""""""""""""

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

"""""""""""
" Debugging
"""""""""""

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
