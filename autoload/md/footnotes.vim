"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown footnotes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Find the footnote reference that contains the cursor position
" Returns a dictionary with footnote information or {} if no footnote found
function! md#footnotes#findFootnoteAtCursor()
  let cursor_pos = getpos('.')
  let line_num = cursor_pos[1]
  let col_num = cursor_pos[2]
  
  " First check if we're on a footnote definition line
  let def_info = s:findFootnoteDefinitionAtPosition(line_num, col_num)
  if !empty(def_info)
    return def_info
  endif
  
  " Try to find a footnote reference
  let ref_info = s:findFootnoteReferenceAtPosition(line_num, col_num)
  if !empty(ref_info)
    return ref_info
  endif
  
  return {}
endfunction

" Find footnote reference at the given position
" Returns footnote info dict or {} if none found
function! s:findFootnoteReferenceAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  let footnotes = md#footnotes#findFootnoteReferencesInLine(a:line_num, line_content)
  
  for footnote in footnotes
    if a:col_num >= footnote.start_col && a:col_num <= footnote.end_col
      return footnote
    endif
  endfor
  
  return {}
endfunction

" Find footnote definition at the given position
" Returns footnote definition info dict or {} if none found
function! s:findFootnoteDefinitionAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  
  " Match footnote definition: [^id]: content
  let pattern = '^\s*\[\^\([^]]\+\)\]:\s*\(.*\)$'
  let match = matchlist(line_content, pattern)
  if !empty(match)
    let footnote_id = match[1]
    let content = match[2]
    
    " Get full content including wrapped lines
    let full_content = s:getFootnoteDefinitionContent(a:line_num, footnote_id)
    
    let footnote_info = {
          \ 'type': 'definition',
          \ 'line_num': a:line_num,
          \ 'start_col': 1,
          \ 'end_col': len(line_content),
          \ 'id': footnote_id,
          \ 'content': full_content
          \ }
    
    " Check if cursor is within the footnote definition
    let def_start = match(line_content, '\[\^\([^]]\+\)\]:')
    let def_end = def_start + len('[^' . footnote_id . ']:')
    if a:col_num >= def_start + 1 && a:col_num <= def_end
      return footnote_info
    endif
  endif
  
  return {}
endfunction

" Find all footnote references in a line - PUBLIC for testing
" Returns list of footnote info dictionaries
function! md#footnotes#findFootnoteReferencesInLine(line_num, line_content)
  let footnotes = []
  let pos = 0
  
  while 1
    " Find the next [^ pattern
    let start_pos = stridx(a:line_content, '[^', pos)
    if start_pos == -1
      break
    endif
    
    " Find the closing ]
    let end_pos = stridx(a:line_content, ']', start_pos + 2)
    if end_pos == -1
      let pos = start_pos + 2
      continue
    endif
    
    " Extract footnote ID
    let footnote_id = a:line_content[start_pos + 2 : end_pos - 1]
    
    " Skip if the ID is empty or contains invalid characters
    if empty(footnote_id) || footnote_id =~ '[[\]]'
      let pos = start_pos + 2
      continue
    endif
    
    " Find the footnote definition
    let definition_content = s:findFootnoteDefinition(footnote_id)
    
    let footnote_info = {
          \ 'type': 'reference',
          \ 'line_num': a:line_num,
          \ 'start_col': start_pos + 1,
          \ 'end_col': end_pos + 1,
          \ 'id': footnote_id,
          \ 'content': definition_content
          \ }
    
    call add(footnotes, footnote_info)
    let pos = end_pos + 1
  endwhile
  
  return footnotes
endfunction

" Find footnote definition by ID
" Returns the content of the footnote definition or empty string if not found
function! s:findFootnoteDefinition(footnote_id)
  let line_num = 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    let pattern = '^\s*\[\^' . escape(a:footnote_id, '[]^$.*\~') . '\]:\s*\(.*\)$'
    let match = matchlist(line_content, pattern)
    if !empty(match)
      return s:getFootnoteDefinitionContent(line_num, a:footnote_id)
    endif
    let line_num += 1
  endwhile
  
  return ''
endfunction

" Get the full content of a footnote definition, including wrapped lines
" Returns the complete footnote content as a string
function! s:getFootnoteDefinitionContent(def_line_num, footnote_id)
  let content_lines = []
  let line_num = a:def_line_num
  let last_line = line('$')
  
  " Get the first line content (after the [^id]: part)
  let first_line = getline(line_num)
  let pattern = '^\s*\[\^' . escape(a:footnote_id, '[]^$.*\~') . '\]:\s*\(.*\)$'
  let match = matchlist(first_line, pattern)
  if !empty(match)
    call add(content_lines, match[1])
  endif
  
  " Look for continuation lines (indented lines that follow)
  let line_num += 1
  while line_num <= last_line
    let line_content = getline(line_num)
    
    " Stop if we hit another footnote definition or non-indented content
    if line_content =~ '^\s*\[\^[^]]\+\]:' || (line_content !~ '^\s*$' && line_content !~ '^\s\+')
      break
    endif
    
    " Add indented continuation lines
    if line_content =~ '^\s\+'
      call add(content_lines, substitute(line_content, '^\s\+', '', ''))
    elseif line_content =~ '^\s*$'
      " Add empty lines within the footnote
      call add(content_lines, '')
    else
      " Non-indented, non-empty line means end of footnote
      break
    endif
    
    let line_num += 1
  endwhile
  
  " Join all content lines with newlines and trim trailing whitespace/newlines
  let result = join(content_lines, "\n")
  " Remove trailing whitespace and newlines
  return substitute(result, '\s*\n*$', '', '')
endfunction

" Show footnote content in a floating window (Neovim only)
function! md#footnotes#showFootnoteInFloat()
  " Check if we're in Neovim
  if !has('nvim')
    echohl WarningMsg
    echo "Footnote floating windows are only supported in Neovim"
    echohl None
    return
  endif
  
  " Find footnote at cursor
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  if empty(footnote_info)
    echohl WarningMsg
    echo "No footnote found at cursor position"
    echohl None
    return
  endif
  
  " Close any existing footnote window
  call s:closeFootnoteWindow()
  
  " Prepare content for display
  let content = footnote_info.content
  if empty(content)
    echohl WarningMsg
    echo "Footnote definition not found for: " . footnote_info.id
    echohl None
    return
  endif
  
  " Split content into lines and add footnote ID header
  let lines = ['[^' . footnote_info.id . ']:']
  call extend(lines, split(content, "\n"))
  
  " Apply ellision for content that's too long
  let max_width = 70
  let max_height = 11
  
  " Ellide lines that are too long
  for i in range(len(lines))
    if len(lines[i]) > max_width
      let lines[i] = lines[i][0:max_width-4] . '...'
    endif
  endfor
  
  " Ellide if there are too many lines
  if len(lines) > max_height
    let lines = lines[0:max_height-1]
    if len(lines[max_height-1]) > max_width - 3
      let lines[max_height-1] = lines[max_height-1][0:max_width-4] . '...'
    else
      let lines[max_height-1] = lines[max_height-1] . '...'
    endif
  endif
  
  " Calculate window dimensions
  let width = min([max_width, max(map(copy(lines), 'len(v:val)'))])
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