"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown lists
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Check if a line contains an unordered list item (- or * followed by space)
" Returns 1 if the line matches the pattern: '^\s*[-*]\s'
function! s:isUnorderedListItem(lineStr)
  return a:lineStr =~ '^\s*[-*]\s'
endfunction

" Check if a line contains an ordered list item (number followed by . and space)
" Returns 1 if the line matches the pattern: '^\s*\d\+\.\s'
function! s:isOrderedListItem(lineStr)
  return a:lineStr =~ '^\s*\d\+\.\s'
endfunction

" Check if a line contains a checkbox list item (- followed by [x], [X], or [ ] and space)
" Returns 1 if the line matches the pattern: '^\s*-\s*\[[xX ]\]\s'
function! s:isCheckboxListItem(lineStr)
  return a:lineStr =~ '^\s*-\s*\[[xX ]\]\s'
endfunction

" Check if a line contains any type of list item
function! s:isAnyListItem(lineStr)
  return s:isUnorderedListItem(a:lineStr) || s:isOrderedListItem(a:lineStr) || s:isCheckboxListItem(a:lineStr)
endfunction

" Get the list type of a line
" Returns: 'unordered', 'ordered', 'checkbox', or '' if not a list item
function! s:getListType(lineStr)
  if s:isCheckboxListItem(a:lineStr)
    return 'checkbox'
  elseif s:isOrderedListItem(a:lineStr)
    return 'ordered'
  elseif s:isUnorderedListItem(a:lineStr)
    return 'unordered'
  else
    return ''
  endif
endfunction

" Extract the indentation from a list item line
function! s:getListIndent(lineStr)
  let match = matchstr(a:lineStr, '^\s*')
  return match
endfunction

" Extract the list marker from a list item line
function! s:getListMarker(lineStr)
  let listType = s:getListType(a:lineStr)
  if listType ==# 'checkbox'
    return matchstr(a:lineStr, '^\s*\zs-\s*\[[xX ]\]')
  elseif listType ==# 'ordered'
    return matchstr(a:lineStr, '^\s*\zs\d\+\.')
  elseif listType ==# 'unordered'
    return matchstr(a:lineStr, '^\s*\zs[-*]')
  else
    return ''
  endif
endfunction

" Check if the current line is within a list context
" This includes being on a list item line or a continuation line
function! md#lists#isInListContext()
  let currentLine = line('.')
  let lineStr = getline(currentLine)
  
  " Check if current line is a list item
  if s:isAnyListItem(lineStr)
    return 1
  endif
  
  " Check if current line is a continuation of a list item
  " Look backward to find a list item
  let searchLine = currentLine - 1
  while searchLine > 0
    let searchLineStr = getline(searchLine)
    
    " If we find a list item, check if current line is a continuation
    if s:isAnyListItem(searchLineStr)
      let listIndent = len(s:getListIndent(searchLineStr))
      let currentIndent = len(matchstr(lineStr, '^\s*'))
      
      " Current line is continuation if it's indented more than the list item
      " or if it's empty
      if lineStr =~ '^\s*$' || currentIndent > listIndent
        return 1
      else
        return 0
      endif
    endif
    
    " If we hit a non-empty, non-indented line, stop searching
    if searchLineStr !~ '^\s*$' && searchLineStr !~ '^\s\+'
      break
    endif
    
    let searchLine -= 1
  endwhile
  
  return 0
endfunction

" Generate a new list item based on the current context
" Returns the string to insert, or empty string if not in list context
function! md#lists#generateNewListItem()
  if !md#lists#isInListContext()
    return ''
  endif
  
  let currentLine = line('.')
  let lineStr = getline(currentLine)
  
  " Find the reference list item (current line or previous list item)
  let refLine = currentLine
  let refLineStr = lineStr
  
  if !s:isAnyListItem(refLineStr)
    " Look backward for the list item this line belongs to
    let searchLine = currentLine - 1
    while searchLine > 0
      let searchLineStr = getline(searchLine)
      if s:isAnyListItem(searchLineStr)
        let refLine = searchLine
        let refLineStr = searchLineStr
        break
      endif
      let searchLine -= 1
    endwhile
  endif
  
  if !s:isAnyListItem(refLineStr)
    return ''
  endif
  
  let listType = s:getListType(refLineStr)
  let indent = s:getListIndent(refLineStr)
  
  if listType ==# 'checkbox'
    return indent . '- [ ] '
  elseif listType ==# 'ordered'
    " Get the next number in sequence
    let currentNum = str2nr(matchstr(refLineStr, '^\s*\zs\d\+'))
    return indent . (currentNum + 1) . '. '
  elseif listType ==# 'unordered'
    let marker = s:getListMarker(refLineStr)
    return indent . marker . ' '
  endif
  
  return ''
endfunction

" Generate a continuation line for the current list item
" Returns the string to insert for proper indentation, or empty string if not in list context
function! md#lists#generateListContinuation()
  if !md#lists#isInListContext()
    return ''
  endif
  
  let currentLine = line('.')
  let lineStr = getline(currentLine)
  
  " Find the reference list item
  let refLine = currentLine
  let refLineStr = lineStr
  
  if !s:isAnyListItem(refLineStr)
    " Look backward for the list item this line belongs to
    let searchLine = currentLine - 1
    while searchLine > 0
      let searchLineStr = getline(searchLine)
      if s:isAnyListItem(searchLineStr)
        let refLine = searchLine
        let refLineStr = searchLineStr
        break
      endif
      let searchLine -= 1
    endwhile
  endif
  
  if !s:isAnyListItem(refLineStr)
    return ''
  endif
  
  " Calculate the indentation for content (after the list marker)
  let listType = s:getListType(refLineStr)
  let baseIndent = s:getListIndent(refLineStr)
  
  if listType ==# 'checkbox'
    " Content starts after "- [ ] " or "- [x] "
    let markerLength = len('- [ ] ')
  elseif listType ==# 'ordered'
    " Content starts after "1. " (variable length for different numbers)
    let marker = s:getListMarker(refLineStr)
    let markerLength = len(marker) + 1  " +1 for the space
  elseif listType ==# 'unordered'
    " Content starts after "- " or "* "
    let markerLength = 2
  else
    return ''
  endif
  
  " Return the indentation that aligns with the start of the content
  return baseIndent . repeat(' ', markerLength)
endfunction

" Handle Enter key in insert mode
" Returns the appropriate action based on context
function! md#lists#handleEnter()
  if md#lists#isInListContext()
    let newItem = md#lists#generateNewListItem()
    if !empty(newItem)
      return "\<CR>" . newItem
    endif
  endif
  
  " Default behavior - check if user has custom mapping
  if maparg('<CR>', 'i') !=# ''
    return "\<C-R>=pumvisible() ? \"\\<C-Y>\" : \"\\<CR>\"\<CR>"
  else
    return "\<CR>"
  endif
endfunction

" Handle Shift+Enter key in insert mode  
" Returns the appropriate action based on context
function! md#lists#handleShiftEnter()
  if md#lists#isInListContext()
    let continuation = md#lists#generateListContinuation()
    if !empty(continuation)
      return "\<CR>" . continuation
    endif
  endif
  
  " Default behavior - check if user has custom mapping
  if maparg('<S-CR>', 'i') !=# ''
    return maparg('<S-CR>', 'i')
  else
    return "\<CR>"
  endif
endfunction