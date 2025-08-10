" TODO
" - ensure no mappings are overwritten

inoremap <buffer> <C-f> <C-o>:call md#core#footnote()<CR>
inoremap <buffer> <C-l> <C-o>:call md#core#referenceLink()<CR>

" operator pending mappings
onoremap <buffer> is :call md#core#insideSection()<CR>
onoremap <buffer> as :call md#core#aroundSection(1)<CR>
onoremap <buffer> it :call md#core#insideTree()<CR>
onoremap <buffer> at :call md#core#aroundTree()<CR>
onoremap <buffer> ih :call md#core#insideHeading()<CR>
onoremap <buffer> ah :call md#core#aroundHeading()<CR>

vnoremap <buffer> is :<C-u>call md#core#insideSection()<CR>
vnoremap <buffer> as :<C-u>call md#core#aroundSection(0)<CR>
vnoremap <buffer> it :<C-u>call md#core#insideTree()<CR>
vnoremap <buffer> at :<C-u>call md#core#aroundTree()<CR>
vnoremap <buffer> ih :<C-u>call md#core#insideHeading()<CR>
vnoremap <buffer> ah :<C-u>call md#core#aroundHeading()<CR>

" tree manipulation mappings
nnoremap <buffer> [h :call md#core#decHeading(1)<CR>
nnoremap <buffer> ]h :call md#core#incHeading(1)<CR>
nnoremap <buffer> [H :call md#core#decHeading(0)<CR>
nnoremap <buffer> ]H :call md#core#incHeading(0)<CR>
nnoremap <buffer> [m :call md#core#moveSectionBack()<CR>
nnoremap <buffer> ]m :call md#core#moveSectionForward()<CR>
nnoremap <buffer> [M :call md#core#raiseSectionBack()<CR>
nnoremap <buffer> ]M :call md#core#raiseSectionForward()<CR>
nnoremap <buffer> gR :call md#core#nestSection()<CR>

" movement mappings
nnoremap <buffer> [[ :call md#move#toPreviousHeading()<CR>
nnoremap <buffer> ][ :call md#move#toNextHeading()<CR>
nnoremap <buffer> [s :call md#move#toPreviousSibling()<CR>
nnoremap <buffer> ]s :call md#move#toNextSibling()<CR>
nnoremap <buffer> (  :call md#move#toParentHeading()<CR>
nnoremap <buffer> )  :call md#move#toFirstChildHeading()<CR>

" FIXME make these motions better (store V state, no yucky echom, etc.)
vnoremap <buffer> [[ :<C-u>call md#move#toPreviousHeading()<CR>
vnoremap <buffer> ][ :<C-u>call md#move#toNextHeading()<CR>
vnoremap <buffer> [s :<C-u>call md#move#toPreviousSibling()<CR>
vnoremap <buffer> ]s :<C-u>call md#move#toNextSibling()<CR>
vnoremap <buffer> (  :<C-u>call md#move#toParentHeading()<CR>
vnoremap <buffer> )  :<C-u>call md#move#toFirstChildHeading()<CR>
