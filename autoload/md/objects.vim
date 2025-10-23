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
  let link_info = md#links#findLinkAtPos(getpos('.'))
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
  let link_info = md#links#findLinkAtPos(getpos('.'))
  if !empty(link_info)
    let range = md#links#getLinkTextRange(link_info)
    if !empty(range)
      if link_info.type == 'wiki'
        " For wiki links, just return the text range since there are no dedicated brackets around the display text
        return s:charRange([range[0], range[1]], [range[2], range[3]])
      else
        " For regular links, extend range to include the brackets
        return s:charRange([range[0], range[1] - 1], [range[2], range[3] + 1])
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the target inside a markdown link
function! md#objects#insideLinkTarget()
  let link_info = md#links#findLinkAtPos(getpos('.'))
  if !empty(link_info)
    let range = md#links#getLinkTargetRange(link_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the target of a markdown link (including parens/definition)
function! md#objects#aroundLinkTarget()
  let link_info = md#links#findLinkAtPos(getpos('.'))
  if !empty(link_info)
    let range = md#links#getLinkTargetRange(link_info)
    if !empty(range)
      if link_info.type == 'inline'
        " Extend range to include the parentheses
        return s:charRange([range[0], range[1] - 1], [range[2], range[3] + 1])
      elseif link_info.type == 'reference'
        " For reference links, include the entire definition line
        return ['V', s:startOfLine(range[0]), s:startOfLine(range[2])]
      elseif link_info.type == 'wiki'
        " For wiki links, around the target means just the target since there are no dedicated brackets around it
        return s:charRange([range[0], range[1]], [range[2], range[3]])
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the entire markdown link
function! md#objects#insideLink()
  let link_info = md#links#findLinkAtPos(getpos('.'))
  if !empty(link_info)
    let range = md#links#getLinkFullRange(link_info)
    if !empty(range)
      " For inside, exclude the outer brackets
      if link_info.type == 'inline'
        return s:charRange([range[0], range[1] + 1], [range[2], range[3] - 1])
      elseif link_info.type == 'reference'
        return s:charRange([range[0], range[1] + 1], [range[2], range[3] - 1])
      elseif link_info.type == 'wiki'
        return s:charRange([range[0], range[1] + 2], [range[2], range[3] - 2])
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the entire markdown link
function! md#objects#aroundLink()
  let link_info = md#links#findLinkAtPos(getpos('.'))
  if !empty(link_info)
    let range = md#links#getLinkFullRange(link_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the text inside a checkbox item
function! md#objects#insideCheckbox()
  let contentRange = md#checkbox#getInsideContentRange(line('.'))
  if empty(contentRange)
    return 0
  endif
  
  return s:charRange([contentRange.start_line, contentRange.start_col], 
                   \ [contentRange.end_line, contentRange.end_col])
endfunction

" Returns a vim-textobj-user style range around the entire checkbox item
function! md#objects#aroundCheckbox()
  let checkboxRange = md#checkbox#findCheckboxRange(line('.'))
  if empty(checkboxRange)
    return 0
  endif
  
  return s:lineRange(checkboxRange.start_line, checkboxRange.end_line)
endfunction

" Returns a vim-textobj-user style range for the text inside a footnote reference
function! md#objects#insideFootnoteText()
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if !empty(footnote_info) && footnote_info.type == 'reference'
    let range = md#footnotes#getFootnoteTextRange(footnote_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the text of a footnote reference (including brackets)
function! md#objects#aroundFootnoteText()
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if !empty(footnote_info) && footnote_info.type == 'reference'
    let range = md#footnotes#getFootnoteTextRange(footnote_info)
    if !empty(range)
      " Extend range to include the [^ and ]
      return s:charRange([range[0], range[1] - 2], [range[2], range[3] + 1])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the content inside a footnote definition
function! md#objects#insideFootnoteDefinition()
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if !empty(footnote_info)
    let range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
    if !empty(range)
      return s:charRange([range[0], range[1]], [range[2], range[3]])
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the entire footnote definition (including marker)
function! md#objects#aroundFootnoteDefinition()
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if !empty(footnote_info)
    if footnote_info.type == 'definition'
      " For definitions, use line-wise selection to include the entire definition
      let range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
      if !empty(range)
        return s:lineRange(range[0], range[2])
      endif
    elseif footnote_info.type == 'reference'
      " For references, find the definition and select it
      let range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
      if !empty(range)
        return s:lineRange(range[0], range[2])
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range for the entire footnote structure (inside)
function! md#objects#insideFootnote()
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if !empty(footnote_info)
    let range = md#footnotes#getFootnoteFullRange(footnote_info)
    if !empty(range)
      if footnote_info.type == 'reference'
        " For references, exclude the outer [^ and ]
        return s:charRange([range[0], range[1] + 2], [range[2], range[3] - 1])
      elseif footnote_info.type == 'definition'
        " For definitions, exclude the [^id]: part
        let def_range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
        if !empty(def_range)
          return s:charRange([def_range[0], def_range[1]], [def_range[2], def_range[3]])
        endif
      endif
    endif
  endif
  return 0
endfunction

" Returns a vim-textobj-user style range around the entire footnote structure
function! md#objects#aroundFootnote()
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if !empty(footnote_info)
    let range = md#footnotes#getFootnoteFullRange(footnote_info)
    if !empty(range)
      if footnote_info.type == 'reference'
        " For references, include the entire [^id]
        return s:charRange([range[0], range[1]], [range[2], range[3]])
      elseif footnote_info.type == 'definition'
        " For definitions, use line-wise selection
        return s:lineRange(range[0], range[2])
      endif
    endif
  endif
  return 0
endfunction
