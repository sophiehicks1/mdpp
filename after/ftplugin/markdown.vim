" markdown.vim - Vim plugin for editing Markdown files

" TODO:
" - extend the dom model to account for references at the end
" - reimplement these
" - also implement links and checklists
" inoremap <buffer> <C-f> <C-o>:call md#core#footnote()<CR>
" inoremap <buffer> <C-l> <C-o>:call md#core#referenceLink()<CR>


" TODO: tree manipulation - Need to think about this one a little...
" - dec/inc heading, collect lnums from the tree and use setline()
" - nest section, inc heading, and use append() to add a new heading
" - raise section back
"   - find current section lnums from dom
"   - find parent start lnum from dom
"   - extract section lines
"   - delete section
"   - append() to parent start lnum - 1
" - raise section forward
"   - find current section lnums from dom
"   - find parent end lnum from dom
"   - extract section lines
"   - append() to parent end lnum
"   - delete section
" - move section forward / move section back - similar to above
" nnoremap <buffer> [h :call md#core#decHeading(1)<CR>
" nnoremap <buffer> ]h :call md#core#incHeading(1)<CR>
" nnoremap <buffer> [H :call md#core#decHeading(0)<CR>
" nnoremap <buffer> ]H :call md#core#incHeading(0)<CR>
" nnoremap <buffer> [m :call md#core#moveSectionBack()<CR>
" nnoremap <buffer> ]m :call md#core#moveSectionForward()<CR>
" nnoremap <buffer> [M :call md#core#raiseSectionBack()<CR>
" nnoremap <buffer> ]M :call md#core#raiseSectionForward()<CR>
" nnoremap <buffer> gR :call md#core#nestSection()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownBackToHeadingNormal :<C-u>call md#move#backToHeadingNormal()<cr>
vnoremap <buffer> <silent> <Plug>MarkdownBackToHeadingVisual :<C-u>call md#move#backToHeadingVisual()<cr>
onoremap <buffer> <silent> <Plug>MarkdownBackToHeadingVisual :<C-u>call md#move#backToHeadingVisual()<cr>
                          
nnoremap <buffer> <silent> <Plug>MarkdownForwardToHeadingNormal :<C-u>call md#move#forwardToHeadingNormal()<cr>
vnoremap <buffer> <silent> <Plug>MarkdownForwardToHeadingVisual :<C-u>call md#move#forwardToHeadingVisual()<cr>
onoremap <buffer> <silent> <Plug>MarkdownForwardToHeadingVisual :<C-u>call md#move#forwardToHeadingVisual()<cr>

nnoremap <buffer> <silent> <Plug>MarkdownBackToSiblingNormal :<C-u>call md#move#backToSiblingNormal()<cr>
vnoremap <buffer> <silent> <Plug>MarkdownBackToSiblingVisual :<C-u>call md#move#backToSiblingVisual()<cr>
onoremap <buffer> <silent> <Plug>MarkdownBackToSiblingVisual :<C-u>call md#move#backToSiblingVisual()<cr>

nnoremap <buffer> <silent> <Plug>MarkdownForwardToSiblingNormal :<C-u>call md#move#forwardToSiblingNormal()<cr>
vnoremap <buffer> <silent> <Plug>MarkdownForwardToSiblingVisual :<C-u>call md#move#forwardToSiblingVisual()<cr>
onoremap <buffer> <silent> <Plug>MarkdownForwardToSiblingVisual :<C-u>call md#move#forwardToSiblingVisual()<cr>

nnoremap <buffer> <silent> <Plug>MarkdownBackToParentNormal :<C-u>call md#move#backToParentNormal()<cr>
vnoremap <buffer> <silent> <Plug>MarkdownBackToParentVisual :<C-u>call md#move#backToParentVisual()<cr>
onoremap <buffer> <silent> <Plug>MarkdownBackToParentVisual :<C-u>call md#move#backToParentVisual()<cr>

nnoremap <buffer> <silent> <Plug>MarkdownForwardToFirstChildNormal :<C-u>call md#move#forwardToFirstChildNormal()<cr>
vnoremap <buffer> <silent> <Plug>MarkdownForwardToFirstChildVisual :<C-u>call md#move#forwardToFirstChildVisual()<cr>
onoremap <buffer> <silent> <Plug>MarkdownForwardToFirstChildVisual :<C-u>call md#move#forwardToFirstChildVisual()<cr>

if exists('g:mdpp_move_mappings') && g:mdpp_move_mappings == 0
  " If the user has disabled the movement mappings, don't set them.
else
  " Set the movement mappings for normal and visual modes.
  nmap <buffer> [[ <Plug>MarkdownBackToHeadingNormal
  vmap <buffer> [[ <Plug>MarkdownBackToHeadingVisual
  omap <buffer> [[ <Plug>MarkdownBackToHeadingVisual

  nmap <buffer> ]] <Plug>MarkdownForwardToHeadingNormal
  vmap <buffer> ]] <Plug>MarkdownForwardToHeadingVisual
  omap <buffer> ]] <Plug>MarkdownForwardToHeadingVisual

  nmap <buffer> [s <Plug>MarkdownBackToSiblingNormal
  vmap <buffer> [s <Plug>MarkdownBackToSiblingVisual
  omap <buffer> [s <Plug>MarkdownBackToSiblingVisual

  nmap <buffer> ]s <Plug>MarkdownForwardToSiblingNormal
  vmap <buffer> ]s <Plug>MarkdownForwardToSiblingVisual
  omap <buffer> ]s <Plug>MarkdownForwardToSiblingVisual

  nmap <buffer> ( <Plug>MarkdownBackToParentNormal
  vmap <buffer> ( <Plug>MarkdownBackToParentVisual
  omap <buffer> ( <Plug>MarkdownBackToParentVisual

  nmap <buffer> ) <Plug>MarkdownForwardToFirstChildNormal
  vmap <buffer> ) <Plug>MarkdownForwardToFirstChildVisual
  omap <buffer> ) <Plug>MarkdownForwardToFirstChildVisual
endif
