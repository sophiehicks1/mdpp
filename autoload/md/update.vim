function! md#update#incHeadingLevel()
  call md#dom#refreshDocument()
  call md#dom#incDescendentHeadings('.')
endfunction

function! md#update#decHeadingLevel()
  call md#dom#refreshDocument()
  call md#dom#decDescendentHeadings('.')
endfunction
