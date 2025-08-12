" Coerce lnum to an integer
function! md#line#lineAsNum(line)
  if type(a:line) ==# 0
    return a:line
  else
    return line(a:line)
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""
" functions for parsing individual lines
""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Check if the line is empty or contains only whitespace.
function! s:strIsEmpty(lineStr)
  return a:lineStr =~ '^\s*$'
endfunction

" Check if the line starts with a hash followed by spaces.
function! s:strIsHashHeading(lineStr)
  return a:lineStr =~ '^##*\s'
endfunction

" Check if the line is a heading underline (either == or --).
function! s:strIsHeadingUnderline(lineStr)
  return a:lineStr =~ '^[=-][=-]*$'
endfunction

" Check if the line is a list item (starts with - or * followed by space).
function! s:strIsListItem(lineStr)
  return a:lineStr =~ '^\s*[-*]\s'
endfunction

" FIXME I REALLY WANT TO MOVE THIS OUT
" Get the heading level of the line at line (i.e. 1 for '# foo', 2 for '## foo', etc.
" Returns 0 if the line is not a heading.
function! md#line#headingLevel(line)
  let lineStr = getline(a:line)
  " Check if the lineStr is a hash heading (##, ###, etc.), and return the count
  " of hashes if it is
  if s:strIsHashHeading(lineStr)
    return len(matchstr(lineStr, '^##*\ze\s'))
  endif
  " Check if the lineStr is a heading underline (either == or --).
  if !(s:strIsEmpty(lineStr) || s:strIsListItem(lineStr))
    let nextLine = getline(md#line#lineAsNum(a:line) + 1)
    if s:strIsHeadingUnderline(nextLine)
      " This is a heading underline, so we return the level based on the
      " underline character used.
      return lineStr[0] ==# '=' ? 1 : 2
    endif
  endif
  " If we get here, it's not a heading.
  return 0
endfunction
