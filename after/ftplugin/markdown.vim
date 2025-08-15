" markdown.vim - Vim plugin for editing Markdown files

" TODO reimplement <c-f> and <c-l> mappings
" - gf integration for links via (improved) open.vim

nnoremap <buffer> <silent> <Plug>MarkdownBackToHeadingNormal :<C-u>call md#move#backToHeadingNormal()<CR>
vnoremap <buffer> <silent> <Plug>MarkdownBackToHeadingVisual :<C-u>call md#move#backToHeadingVisual()<CR>
onoremap <buffer> <silent> <Plug>MarkdownBackToHeadingVisual :<C-u>call md#move#backToHeadingVisual()<CR>
                          
nnoremap <buffer> <silent> <Plug>MarkdownForwardToHeadingNormal :<C-u>call md#move#forwardToHeadingNormal()<CR>
vnoremap <buffer> <silent> <Plug>MarkdownForwardToHeadingVisual :<C-u>call md#move#forwardToHeadingVisual()<CR>
onoremap <buffer> <silent> <Plug>MarkdownForwardToHeadingVisual :<C-u>call md#move#forwardToHeadingVisual()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownBackToSiblingNormal :<C-u>call md#move#backToSiblingNormal()<CR>
vnoremap <buffer> <silent> <Plug>MarkdownBackToSiblingVisual :<C-u>call md#move#backToSiblingVisual()<CR>
onoremap <buffer> <silent> <Plug>MarkdownBackToSiblingVisual :<C-u>call md#move#backToSiblingVisual()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownForwardToSiblingNormal :<C-u>call md#move#forwardToSiblingNormal()<CR>
vnoremap <buffer> <silent> <Plug>MarkdownForwardToSiblingVisual :<C-u>call md#move#forwardToSiblingVisual()<CR>
onoremap <buffer> <silent> <Plug>MarkdownForwardToSiblingVisual :<C-u>call md#move#forwardToSiblingVisual()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownBackToParentNormal :<C-u>call md#move#backToParentNormal()<CR>
vnoremap <buffer> <silent> <Plug>MarkdownBackToParentVisual :<C-u>call md#move#backToParentVisual()<CR>
onoremap <buffer> <silent> <Plug>MarkdownBackToParentVisual :<C-u>call md#move#backToParentVisual()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownForwardToFirstChildNormal :<C-u>call md#move#forwardToFirstChildNormal()<CR>
vnoremap <buffer> <silent> <Plug>MarkdownForwardToFirstChildVisual :<C-u>call md#move#forwardToFirstChildVisual()<CR>
onoremap <buffer> <silent> <Plug>MarkdownForwardToFirstChildVisual :<C-u>call md#move#forwardToFirstChildVisual()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownDecrementHeadingLevelNoChildren :<C-u>call md#update#decHeadingLevel(0)<CR>
nnoremap <buffer> <silent> <Plug>MarkdownIncrementHeadingLevelNoChildren :<C-u>call md#update#incHeadingLevel(0)<CR>
nnoremap <buffer> <silent> <Plug>MarkdownDecrementHeadingLevelWithChildren :<C-u>call md#update#decHeadingLevel(1)<CR>
nnoremap <buffer> <silent> <Plug>MarkdownIncrementHeadingLevelWithChildren :<C-u>call md#update#incHeadingLevel(1)<CR>

nnoremap <buffer> <silent> <Plug>MarkdownNestSection :<C-u>call md#update#nestSection()<CR>A
nnoremap <buffer> <silent> <Plug>MarkdownMoveSectionBack :<C-u>call md#update#moveSectionBack()<CR>
nnoremap <buffer> <silent> <Plug>MarkdownMoveSectionForward :<C-u>call md#update#moveSectionForward()<CR>
nnoremap <buffer> <silent> <Plug>MarkdownRaiseSectionBack :<C-u>call md#update#raiseSectionBack()<CR>
nnoremap <buffer> <silent> <Plug>MarkdownRaiseSectionForward :<C-u>call md#update#raiseSectionForward()<CR>

nnoremap <buffer> <silent> <Plug>MarkdownCheckCheckbox :<C-u>call md#update#checkCheckbox()<CR>
nnoremap <buffer> <silent> <Plug>MarkdownUncheckCheckbox :<C-u>call md#update#uncheckCheckbox()<CR>

if exists('g:mdpp_default_mappings') && g:mdpp_default_mappings == 0
  " If the user has disabled the mappings, don't set them.
else
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

  nmap <buffer> [h <Plug>MarkdownDecrementHeadingLevelNoChildren
  nmap <buffer> ]h <Plug>MarkdownIncrementHeadingLevelNoChildren
  nmap <buffer> [H <Plug>MarkdownDecrementHeadingLevelWithChildren
  nmap <buffer> ]H <Plug>MarkdownIncrementHeadingLevelWithChildren

  nmap <buffer> gR <Plug>MarkdownNestSection
  nmap <buffer> [m <Plug>MarkdownMoveSectionBack
  nmap <buffer> ]m <Plug>MarkdownMoveSectionForward
  nmap <buffer> [M <Plug>MarkdownRaiseSectionBack
  nmap <buffer> ]M <Plug>MarkdownRaiseSectionForward
  
  nmap <buffer> [d <Plug>MarkdownUncheckCheckbox
  nmap <buffer> ]d <Plug>MarkdownCheckCheckbox
endif
