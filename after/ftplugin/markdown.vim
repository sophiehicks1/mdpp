" TODO: make all these customizable

" TODO:
" - extend the dom model to account for references at the end
" - reimplement these
" inoremap <buffer> <C-f> <C-o>:call md#core#footnote()<CR>
" inoremap <buffer> <C-l> <C-o>:call md#core#referenceLink()<CR>


" TODO: Text objects - reimplement these using vim-textobj-user
" onoremap <buffer> is :call md#core#insideSection()<CR>
" onoremap <buffer> as :call md#core#aroundSection(1)<CR>
" onoremap <buffer> it :call md#core#insideTree()<CR>
" onoremap <buffer> at :call md#core#aroundTree()<CR>
" onoremap <buffer> ih :call md#core#insideHeading()<CR>
" onoremap <buffer> ah :call md#core#aroundHeading()<CR>
" vnoremap <buffer> is :<C-u>call md#core#insideSection()<CR>
" vnoremap <buffer> as :<C-u>call md#core#aroundSection(0)<CR>
" vnoremap <buffer> it :<C-u>call md#core#insideTree()<CR>
" vnoremap <buffer> at :<C-u>call md#core#aroundTree()<CR>
" vnoremap <buffer> ih :<C-u>call md#core#insideHeading()<CR>
" vnoremap <buffer> ah :<C-u>call md#core#aroundHeading()<CR>

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

" TODO: movement mappings - Just get the value from the dom, and go straight there
nnoremap <buffer> [[ :call md#move#backToHeading()<CR>
nnoremap <buffer> ]] :call md#move#forwardToHeading()<CR>
" nnoremap <buffer> [s :call md#move#toPreviousSibling()<CR>
" nnoremap <buffer> ]s :call md#move#toNextSibling()<CR>
" nnoremap <buffer> (  :call md#move#toParentHeading()<CR>
" nnoremap <buffer> )  :call md#move#toFirstChildHeading()<CR>
" vnoremap <buffer> [[ :<C-u>call md#move#toPreviousHeading()<CR>
" vnoremap <buffer> ][ :<C-u>call md#move#toNextHeading()<CR>
" vnoremap <buffer> [s :<C-u>call md#move#toPreviousSibling()<CR>
" vnoremap <buffer> ]s :<C-u>call md#move#toNextSibling()<CR>
" vnoremap <buffer> (  :<C-u>call md#move#toParentHeading()<CR>
" vnoremap <buffer> )  :<C-u>call md#move#toFirstChildHeading()<CR>
