"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Markdown link info structure:
" {
"   'type': 'wiki' | 'inline' | 'reference' | 'reference_definition',
"   'line_num': <line number where link starts>,
"   'end_line': <line number where link ends>,
"   'start_col': <1-indexed column where link starts>,
"   'end_col': <1-indexed column where link ends>,
"   'text': <display text of the link>,
"   'text_start_line': <line number where link text starts>,
"   'text_end_line': <line number where link text ends>,
"   'text_start_col': <1-indexed column where link text starts>,
"   'text_end_col': <1-indexed column where link text ends>,
"   'target': <target of the link>,
"   'target_start_line': <line number where link target starts>,
"   'target_end_line': <line number where link target ends>,
"   'target_start_col': <1-indexed column where link target starts>,
"   'target_end_col': <1-indexed column where link target ends>,
"   'full_start_line': <line number where full link starts>,
"   'full_end_line': <line number where full link ends>,
"   'full_start_col': <1-indexed column where full link starts>,
"   'full_end_col': <1-indexed column where full link ends>
" }
"
" All these fields are always present, although reference-style links may have
" target set to empty string or target-related lines/cols set to -1 if no
" reference definition is found.

" Find the link that contains the given position
" Returns a dictionary with link information or {} if no link found
function! md#links#findLinkAtPos(pos)
  call md#dom#refreshDocument()
  return md#dom#findLinkAtPos(a:pos)
endfunction

" Get the text content of a link (what's between the [])
function! md#links#getLinkText(link_info)
  if empty(a:link_info)
    return ''
  endif
  return a:link_info.text
endfunction

" Get the target of a link
function! md#links#getLinkTarget(link_info)
  if empty(a:link_info)
    return ''
  endif
  return a:link_info.target
endfunction

" Get position range for link text selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkTextRange(link_info)
  if empty(a:link_info)
    return []
  endif
  return [
        \ a:link_info.text_start_line, a:link_info.text_start_col,
        \ a:link_info.text_end_line, a:link_info.text_end_col
        \ ]
endfunction

" Get position range for link target selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkTargetRange(link_info)
  if empty(a:link_info) || a:link_info.target_start_line == -1 || a:link_info.target_end_line == -1
    return []
  endif

  let start_line = a:link_info.target_start_line
  let end_line = a:link_info.target_end_line
  return [start_line, a:link_info.target_start_col, end_line, a:link_info.target_end_col]
endfunction

" Get position range for entire link selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkFullRange(link_info)
  if empty(a:link_info)
    return []
  endif
  return [
        \ a:link_info.full_start_line, a:link_info.full_start_col,
        \ a:link_info.full_end_line, a:link_info.full_end_col
        \ ]
endfunction

" }}}
