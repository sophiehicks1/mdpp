function! md#update#incHeadingLevel(withDescendents)
  call md#dom#refreshDocument()
  call md#dom#incDescendentHeadings('.', a:withDescendents)
endfunction

function! md#update#decHeadingLevel(withDescendents)
  call md#dom#refreshDocument()
  call md#dom#decDescendentHeadings('.', a:withDescendents)
endfunction

function! md#update#nestSection()
  call md#dom#refreshDocument()
  call md#dom#nestSection('.') 
  normal! k
endfunction
