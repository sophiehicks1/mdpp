" Show footnote content in a floating window (Neovim only)
function! md#ux#showFootnoteInFloat()
  " Check if we're in Neovim
  if !has('nvim')
    echohl WarningMsg
    echo "Footnote floating windows are only supported in Neovim"
    echohl None
    return
  endif
  
  " Find footnote at cursor
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  if empty(footnote_info)
    echohl WarningMsg
    echo "No footnote found at cursor position"
    echohl None
    return
  endif
  
  " Close any existing footnote window
  call s:closeFootnoteWindow()
  
  " Prepare content for display
  let content_string = footnote_info.content
  if empty(content_string)
    echohl WarningMsg
    echo "Footnote definition not found for: " . footnote_info.id
    echohl None
    return
  endif
  
  let max_window = {'width': 70, 'height': 11}
  let lines = md#ux#prepareContentForFloatingWindow(max_window, footnote_info.id, content_string)
  
  " Calculate window dimensions
  let width = min([max_window.width, max(map(copy(lines), 'len(v:val)'))])
  let height = len(lines)
  
  " Get cursor position for positioning the float
  let cursor_pos = screenpos(0, line('.'), col('.'))
  let row = cursor_pos.row - 1
  let col = cursor_pos.col
  
  " Adjust position to keep window on screen
  let screen_width = &columns
  let screen_height = &lines
  
  if col + width > screen_width
    let col = screen_width - width - 1
  endif
  
  if row + height + 2 > screen_height
    let row = row - height - 2
  endif
  
  " Create buffer with content
  let buf = nvim_create_buf(v:false, v:true)
  call nvim_buf_set_lines(buf, 0, -1, v:true, lines)
  call nvim_buf_set_option(buf, 'filetype', 'markdown')
  call nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  " Configure window options
  let opts = {
        \ 'relative': 'editor',
        \ 'width': width,
        \ 'height': height,
        \ 'row': row,
        \ 'col': col,
        \ 'style': 'minimal',
        \ 'border': 'single'
        \ }
  
  " Create the floating window
  let s:footnote_winid = nvim_open_win(buf, 0, opts)
  
  " Set window-local options
  call nvim_win_set_option(s:footnote_winid, 'wrap', v:true)
  call nvim_win_set_option(s:footnote_winid, 'cursorline', v:false)
  
  " Auto-close the window when cursor moves or insert mode is entered
  autocmd CursorMoved,CursorMovedI,InsertEnter * ++once call s:closeFootnoteWindow()
endfunction

" Close the footnote floating window if it exists
function! s:closeFootnoteWindow()
  if exists('s:footnote_winid') && nvim_win_is_valid(s:footnote_winid)
    call nvim_win_close(s:footnote_winid, v:true)
    unlet s:footnote_winid
  endif
endfunction

" Prepare content for the floating window, by wrapping the text of each line, and elliding the last line if
" necessary
function! md#ux#prepareContentForFloatingWindow(max_window, footnote_id, content_string)
  let max_width = a:max_window.width
  let max_height = a:max_window.height
  
  " Start with footnote ID header
  let lines = ['[^' . a:footnote_id . ']:']
  
  " Wrap the content_string text within max_width
  let wrapped_content = md#line#wrapText(a:content_string, max_width)
  call extend(lines, wrapped_content)
  
  " Only apply ellision if there are too many lines after wrapping
  if len(lines) > max_height
    let lines = lines[0:max_height-1]
    " Add ellision to the last line
    if len(lines[max_height-1]) > max_width - 3
      let lines[max_height-1] = lines[max_height-1][0:max_width-4] . '...'
    else
      let lines[max_height-1] = lines[max_height-1] . '...'
    endif
  endif
  return lines
endfunction
