""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown checkboxes
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Check if a line contains a checkbox item
" Returns 1 if the line matches the pattern: '^\s*-\s*\[[xX ]\]\s'
function! s:isCheckboxLine(lineStr)
  return a:lineStr =~ '^\s*-\s*\[[xX ]\]\s'
endfunction

" Check if a line is a continuation of a list item
" A continuation line is indented more than the base indentation
function! s:isContinuationLine(lineStr, baseIndent)
  if a:lineStr =~ '^\s*$'
    return 1  " Empty lines continue the item
  endif
  
  let lineIndent = match(a:lineStr, '\S')
  return lineIndent > a:baseIndent
endfunction

" Check if a line is another list item or structural element
" Returns 1 if the line starts a new item that would end the current checkbox
function! s:isStructuralBreak(lineStr, baseIndent)
  let lineIndent = match(a:lineStr, '\S')
  
  " If it's another list item or heading at same/lower level
  if a:lineStr =~ '^\s*[-*#]' || lineIndent <= a:baseIndent
    return 1
  endif
  
  return 0
endfunction

" Find the starting line number of a checkbox item containing the given line
" Returns the line number of the checkbox start, or -1 if not found
function! s:findCheckboxStartFromLine(targetLine)
  let currentLine = a:targetLine
  
  " First check if we're already on a checkbox line
  let lineStr = getline(currentLine)
  if s:isCheckboxLine(lineStr)
    return currentLine
  endif
  
  " Move up to find the start of the checkbox item  
  while currentLine > 1
    let currentLine -= 1
    let lineStr = getline(currentLine)
    
    " If we find a checkbox line, we found our start
    if s:isCheckboxLine(lineStr)
      return currentLine
    endif
    
    " If we hit a structural element (not a continuation), stop searching
    if lineStr !~ '^\s*$' && lineStr !~ '^\s\+\S'
      break
    endif
  endwhile
  
  return -1
endfunction

" Find the ending line number of a checkbox item starting at the given line
" Returns the line number where the checkbox item ends (inclusive)
function! s:findCheckboxEndFromStart(startLine)
  let lastLine = line('$')
  let startLineStr = getline(a:startLine)
  let baseIndent = match(startLineStr, '\S')
  
  let currentLine = a:startLine + 1
  while currentLine <= lastLine
    let lineStr = getline(currentLine)
    
    " Continue if it's a continuation line
    if s:isContinuationLine(lineStr, baseIndent)
      let currentLine += 1
      continue
    endif
    
    " Stop if we hit a structural break
    if s:isStructuralBreak(lineStr, baseIndent)
      break
    endif
    
    let currentLine += 1
  endwhile
  
  " Go back to find the last non-empty line
  let endLine = currentLine - 1
  while endLine > a:startLine && getline(endLine) =~ '^\s*$'
    let endLine -= 1
  endwhile
  
  return endLine
endfunction

" Parse the checkbox prefix and content from a checkbox line
" Returns a dictionary with 'prefix' and 'content' keys
" Returns empty dict if the line is not a valid checkbox
function! s:parseCheckboxLine(lineStr)
  let checkboxMatch = matchlist(a:lineStr, '^\(\s*-\s*\[[xX ]\]\s*\)\(.*\)$')
  if empty(checkboxMatch)
    return {}
  endif
  
  return {
    \ 'prefix': checkboxMatch[1],
    \ 'content': checkboxMatch[2]
    \ }
endfunction

" Find the full range of a checkbox item from the current cursor position
" Returns a dictionary with 'start_line' and 'end_line' keys, or empty dict if not in a checkbox
function! md#checkbox#findCheckboxRange()
  let startLine = s:findCheckboxStartFromLine(line('.'))
  if startLine == -1
    return {}
  endif
  
  let endLine = s:findCheckboxEndFromStart(startLine)
  
  return {
    \ 'start_line': startLine,
    \ 'end_line': endLine
    \ }
endfunction

" Get the content range for inside checkbox text object
" Returns a dictionary with start/end line/column positions, or empty dict if invalid
function! md#checkbox#getInsideContentRange()
  let checkboxRange = md#checkbox#findCheckboxRange()
  if empty(checkboxRange)
    return {}
  endif
  
  let startLine = checkboxRange.start_line
  let endLine = checkboxRange.end_line
  let startLineStr = getline(startLine)
  
  let parsed = s:parseCheckboxLine(startLineStr)
  if empty(parsed)
    return {}
  endif
  
  let prefixLen = len(parsed.prefix)
  let startCol = prefixLen + 1
  
  " Handle empty checkbox content
  if len(parsed.content) == 0 && startLine == endLine
    return {}
  endif
  
  " For multi-line, end at the end of the last line
  let endCol = len(getline(endLine))
  if endCol == 0
    let endCol = 1
  endif
  
  return {
    \ 'start_line': startLine,
    \ 'start_col': startCol,
    \ 'end_line': endLine,
    \ 'end_col': endCol
    \ }
endfunction

" Check if the current position is within a checkbox item
" Returns 1 if in a checkbox, 0 otherwise
function! md#checkbox#isInCheckbox()
  let checkboxRange = md#checkbox#findCheckboxRange()
  return !empty(checkboxRange)
endfunction

" Check the checkbox at the current cursor position
" Works regardless of where cursor is within the checkbox item
function! md#checkbox#checkCheckbox()
  let checkboxRange = md#checkbox#findCheckboxRange()
  if empty(checkboxRange)
    return
  endif
  
  let startLine = checkboxRange.start_line
  let lineStr = getline(startLine)
  
  " Parse the checkbox line to get the components
  let parsed = s:parseCheckboxLine(lineStr)
  if empty(parsed)
    return
  endif
  
  " Replace the checkbox state with checked 'x'
  let newPrefix = substitute(parsed.prefix, '\[[xX ]\]', '[x]', '')
  let newLine = newPrefix . parsed.content
  
  " Update the line in the buffer
  call setline(startLine, newLine)
endfunction

" Uncheck the checkbox at the current cursor position  
" Works regardless of where cursor is within the checkbox item
function! md#checkbox#uncheckCheckbox()
  let checkboxRange = md#checkbox#findCheckboxRange()
  if empty(checkboxRange)
    return
  endif
  
  let startLine = checkboxRange.start_line
  let lineStr = getline(startLine)
  
  " Parse the checkbox line to get the components
  let parsed = s:parseCheckboxLine(lineStr)
  if empty(parsed)
    return
  endif
  
  " Replace the checkbox state with unchecked ' '
  let newPrefix = substitute(parsed.prefix, '\[[xX ]\]', '[ ]', '')
  let newLine = newPrefix . parsed.content
  
  " Update the line in the buffer
  call setline(startLine, newLine)
endfunction