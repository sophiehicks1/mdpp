function! md#str#isBlank(str)
  return match(a:str, '^[[:space:]]*$') != -1
endfunction

function! md#str#trim(str)
  return matchlist(a:str, '[[:space:]]*\(.\{-}\)[[:space:]]*$')[1]
endfunction

function! md#str#headingContent(heading)
  return substitute(a:heading, "^#* *", "", "")
endfunction

function! md#str#headingPrefix(heading)
  return matchstr(a:heading, "^#* *")
endfunction

" assumes a:str is only one line
function! md#str#indent(str, n)
  let counter = a:n
  let str = a:str
  while counter
    let str = ' ' . str
    let counter = counter - 1
  endwhile
  return str
endfunction
