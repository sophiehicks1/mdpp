"""""""""""""""""""
" Movement mappings
"""""""""""""""""""

" All these functions use the md#dom API for everything. DO NOT USE s:
" functions

" move to the previous heading, regardless of level
function! md#move#backToHeading()
  call md#dom#refreshDocumentTree()
  let currentLine = line('.')
  let headings = md#dom#allHeadingLines()
  let previousHeading = filter(headings, 'v:val < currentLine')
  if empty(previousHeading)
    return
  endif
  let previousHeading = max(previousHeading)
  call cursor(previousHeading, 1) 
endfunction

" move to the next heading, regardless of level
function! md#move#forwardToHeading()
  call md#dom#refreshDocumentTree()
  let currentLine = line('.')
  let headings = md#dom#allHeadingLines()
  let nextHeading = filter(headings, 'v:val > currentLine')
  if empty(nextHeading)
    return
  endif
  let nextHeading = min(nextHeading)
  call cursor(nextHeading, 1)
endfunction
  
  
