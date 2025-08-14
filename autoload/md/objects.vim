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

" Returns a vim-textobj-user style range for the text inside a markdown link
function! md#objects#insideLinkText()
  " FIXME this should pass in '.', not assume it
  let link_info = md#links#findLinkAtCursor()
  if !empty(link_info)
    let range = md#links#getLinkTextRange(link_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the text of a markdown link (including brackets)
function! md#objects#aroundLinkText()
  let link_info = md#links#findLinkAtCursor()
  if !empty(link_info)
    let range = md#links#getLinkTextRange(link_info)
    if !empty(range)
      " Extend range to include the brackets
      return s:charRange([range[0], range[1] - 1], [range[2], range[3] + 1])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the URL inside a markdown link
function! md#objects#insideLinkUrl()
  let link_info = md#links#findLinkAtCursor()
  if !empty(link_info)
    let range = md#links#getLinkUrlRange(link_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the URL of a markdown link (including parens/definition)
function! md#objects#aroundLinkUrl()
  let link_info = md#links#findLinkAtCursor()
  if !empty(link_info)
    if link_info.type == 'inline'
      let range = md#links#getLinkUrlRange(link_info)
      if !empty(range)
        " Extend range to include the parentheses
        return s:charRange([range[0], range[1] - 1], [range[2], range[3] + 1])
      endif
    elseif link_info.type == 'reference'
      " For reference links, include the entire definition line
      let range = md#links#getLinkUrlRange(link_info)
      if !empty(range)
        " For reference definitions, select the entire line
        return ['V', s:startOfLine(range[0]), s:startOfLine(range[2])]
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the entire markdown link
function! md#objects#insideLink()
  let link_info = md#links#findLinkAtCursor()
  if !empty(link_info)
    let range = md#links#getLinkFullRange(link_info)
    if !empty(range)
      " For inside, exclude the outer brackets
      if link_info.type == 'inline'
        return s:charRange([range[0], range[1] + 1], [range[2], range[3] - 1])
      elseif link_info.type == 'reference'
        return s:charRange([range[0], range[1] + 1], [range[2], range[3] - 1])
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the entire markdown link
function! md#objects#aroundLink()
  let link_info = md#links#findLinkAtCursor()
  if !empty(link_info)
    let range = md#links#getLinkFullRange(link_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Check if a line is a checkbox item
function! s:isCheckboxLine(lineStr)
  return a:lineStr =~ '^\s*-\s*\[[xX ]\]\s'
endfunction

" Find the start of a checkbox item from the current line
function! s:findCheckboxStart()
  let lnum = line('.')
  let current_line = lnum
  
  " Move up to find the start of the checkbox item  
  while current_line > 1
    let lineStr = getline(current_line)
    if s:isCheckboxLine(lineStr)
      return current_line
    endif
    " If we hit a non-continuation line, stop
    if lineStr !~ '^\s*$' && lineStr !~ '^\s\+\S'
      break
    endif
    let current_line -= 1
  endwhile
  
  " Check if current line is a checkbox
  let lineStr = getline(lnum)
  if s:isCheckboxLine(lineStr)
    return lnum
  endif
  
  return -1
endfunction

" Find the end of a checkbox item (including continuation lines)
function! s:findCheckboxEnd(start_line)
  let lnum = a:start_line
  let last_line = line('$')
  let start_lineStr = getline(lnum)
  let base_indent = match(start_lineStr, '\S')
  
  let current_line = lnum + 1
  while current_line <= last_line
    let lineStr = getline(current_line)
    
    " Empty lines continue the checkbox item
    if lineStr =~ '^\s*$'
      let current_line += 1
      continue
    endif
    
    " Check if this line is a continuation (indented more than the checkbox)
    let line_indent = match(lineStr, '\S')
    if line_indent > base_indent
      let current_line += 1
      continue
    endif
    
    " If it's another list item or heading at same/lower level, stop
    if lineStr =~ '^\s*[-*#]' || line_indent <= base_indent
      break
    endif
    
    let current_line += 1
  endwhile
  
  " Go back to find the last non-empty line
  let end_line = current_line - 1
  while end_line > lnum && getline(end_line) =~ '^\s*$'
    let end_line -= 1
  endwhile
  
  return end_line
endfunction

" Returns a vim-textobj-user style range for the text inside a checkbox item
function! md#objects#insideCheckbox()
  let start_line = s:findCheckboxStart()
  if start_line == -1
    return 0
  endif
  
  let end_line = s:findCheckboxEnd(start_line)
  let start_lineStr = getline(start_line)
  
  " Find where the checkbox content starts (after the checkbox prefix)
  let checkbox_match = matchlist(start_lineStr, '^\(\s*-\s*\[[xX ]\]\s*\)\(.*\)$')
  if empty(checkbox_match)
    return 0
  endif
  
  let prefix_len = len(checkbox_match[1])
  let start_col = prefix_len + 1
  
  " Handle empty checkbox content
  if len(checkbox_match[2]) == 0 && start_line == end_line
    return 0
  endif
  
  " For multi-line, end at the end of the last line
  let end_col = len(getline(end_line))
  if end_col == 0
    let end_col = 1
  endif
  
  return s:charRange([start_line, start_col], [end_line, end_col])
endfunction

" Returns a vim-textobj-user style range around the entire checkbox item
function! md#objects#aroundCheckbox()
  let start_line = s:findCheckboxStart()
  if start_line == -1
    return 0
  endif
  
  let end_line = s:findCheckboxEnd(start_line)
  
  return s:lineRange(start_line, end_line)
endfunction
