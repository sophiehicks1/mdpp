"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" See autoload/md/dom.vim for link parsing implementation, and link data
" structure

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
