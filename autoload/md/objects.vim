" Text objects functions for use with vim-textobj-user

" return a position, using the same format returned by getpos()
" line lnum
" column cnum
function! s:position(lnum, cnum)
  return [bufnr('.'), a:lnum, a:cnum, 0]
endfunction

" return a position for the start of line lnum, using the same format returned by getpos()
function! s:startOfLine(lnum)
  return s:position(a:lnum, col('.'))
endfunction

" return a range in the format expected by vim-textobj-user, for a linewise
" range
" first and last are both line numbers, and the range returned is inclusive.
function! s:lineRange(first, last)
  return ['V', s:startOfLine(a:first), s:startOfLine(a:last)]
endfunction

" return a range in the format expected by vim-textobj-user, for a charwise
" range from position nead to position tail.
"
" head and tail are both line number / col number pairs
function! s:charRange(head, tail)
  return ['v', s:position(a:head[0], a:head[1]), s:position(a:tail[0], a:tail[1])]
endfunction

" Returns a vim-textobj-user style range for the section including the current
" line, not including the children, but including the header line.
function! md#objects#aroundSection()
  call md#dom#refreshDocument()
  let lines = md#dom#sectionLnums('.', 0)
  return s:lineRange(min(lines), max(lines))
endfunction

" Returns a vim-textobj-user style range for the section including the current
" line, not including the children or the header line.
function! md#objects#insideSection()
  call md#dom#refreshDocument()
  let lines = md#dom#contentLnums('.', 0)
  return s:lineRange(min(lines), max(lines))
endfunction

" Returns a vim-textobj-user style range for the section including the current
" line, including the children and the header line.
function! md#objects#aroundTree()
  call md#dom#refreshDocument()
  let lines = md#dom#sectionLnums('.', 1)
  return s:lineRange(min(lines), max(lines))
endfunction

" Returns a vim-textobj-user style range for the section including the current
" line, including the children but not the header line.
function! md#objects#insideTree()
  call md#dom#refreshDocument()
  let lines = md#dom#contentLnums('.', 1)
  return s:lineRange(min(lines), max(lines))
endfunction

" TODO FIX THIS FOR underlines

" Returns a vim-textobj-user style range for the current section header content
function! md#objects#insideHeading()
  call md#dom#refreshDocument()
  let headingLine = md#dom#sectionHeadingLnum('.')
  if headingLine != -1
    let startPair = md#line#headingInsideObjectStartPair(headingLine)
    let endPair = md#line#headingInsideObjectEndPair(headingLine)
    return s:charRange(startPair, endPair)
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the whole current section header line
function! md#objects#aroundHeading()
  call md#dom#refreshDocument()
  let headingLine = md#dom#sectionHeadingLnum('.')
  if headingLine != -1
    let startPair = md#line#headingAroundObjectStartPair(headingLine)
    let endPair = md#line#headingAroundObjectEndPair(headingLine)
    return s:charRange(startPair, endPair)
  endif
  return 0
endfunction
