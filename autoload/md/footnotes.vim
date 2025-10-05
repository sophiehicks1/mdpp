"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown footnotes
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Find the footnote reference that contains the cursor position
" Returns a dictionary with footnote information or {} if no footnote found
function! md#footnotes#findFootnoteAtPos(position)
  let line_num = a:position[1]
  let col_num = a:position[2]

  " First check if we're on a footnote definition line
  let def_info = s:findFootnoteDefinitionAtPosition(line_num, col_num)
  if !empty(def_info)
    return def_info
  endif

  " Check if we're on a continuation line of a footnote definition
  let continuation_info = s:findFootnoteContinuationAtPosition(line_num, col_num)
  if !empty(continuation_info)
    return continuation_info
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
  let footnotes = md#footnotes#findFootnoteReferencesInLine(a:line_num)

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
    " Check if cursor is within the footnote definition (marker or content)
    let def_start = match(line_content, '\[\^\([^]]\+\)\]:')
    let def_end = def_start + len('[^' . footnote_id . ']:')
    
    " First check if cursor is in the marker itself
    if a:col_num >= def_start + 1 && a:col_num <= def_end
      return footnote_info
    endif
    
    " Also check if cursor is in the content part of the definition
    if a:col_num >= def_end + 1 && a:col_num <= len(line_content)
      return footnote_info
    endif
  endif

  return {}
endfunction

" TODO refactor this so it's not a billion lines long
" Find all footnote references in a line - PUBLIC for testing
" Returns list of footnote info dictionaries
function! md#footnotes#findFootnoteReferencesInLine(line_num)
  let line_content = getline(a:line_num)
  let footnotes = []
  let pos = 0

  while 1
    " Find the next [^ pattern
    let start_pos = stridx(line_content, '[^', pos)
    if start_pos == -1
      break
    endif

    " Find the closing ]
    let end_pos = stridx(line_content, ']', start_pos + 2)
    if end_pos == -1
      let pos = start_pos + 2
      continue
    endif

    " Extract footnote ID
    let footnote_id = line_content[start_pos + 2 : end_pos - 1]

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
  let paragraphs = []
  let current_paragraph = []
  let line_num = a:def_line_num
  let last_line = line('$')

  " Get the first line content (after the [^id]: part)
  let first_line = getline(line_num)
  let pattern = '^\s*\[\^' . escape(a:footnote_id, '[]^$.*\~') . '\]:\s*\(.*\)$'
  let match = matchlist(first_line, pattern)
  if !empty(match) && !empty(trim(match[1]))
    call add(current_paragraph, match[1])
  endif

  " Look for continuation lines (indented lines that follow)
  let line_num += 1
  let saw_empty_line = 0
  while line_num <= last_line
    let line_content = getline(line_num)

    " Stop if we hit another footnote definition or non-indented content
    if line_content =~ '^\s*\[\^[^]]\+\]:' || (line_content !~ '^\s*$' && line_content !~ '^\s\+')
      break
    endif

    " Handle different line types
    if line_content =~ '^\s\+'
      " Indented continuation line
      let cleaned_line = substitute(line_content, '^\s\+', '', '')
      if !empty(trim(cleaned_line))
        " If we saw an empty line before this content line, it starts a new paragraph
        if saw_empty_line && !empty(current_paragraph)
          call add(paragraphs, join(current_paragraph, ' '))
          let current_paragraph = []
        endif
        call add(current_paragraph, cleaned_line)
        let saw_empty_line = 0
      endif
    elseif line_content =~ '^\s*$'
      " Empty line - flag that we saw it
      let saw_empty_line = 1
    else
      " Non-indented, non-empty line means end of footnote
      break
    endif

    let line_num += 1
  endwhile

  " Add final paragraph if exists
  if !empty(current_paragraph)
    call add(paragraphs, join(current_paragraph, ' '))
  endif

  " Join paragraphs with double newlines for proper paragraph separation
  " If we only have one paragraph, return it directly
  if len(paragraphs) == 1
    return paragraphs[0]
  endif

  " For multiple paragraphs, join with double newlines
  let result = join(paragraphs, "\n\n")
  " Remove trailing whitespace and newlines
  return substitute(result, '\s*\n*$', '', '')
endfunction

" Get the range of the footnote ID text (e.g., "1" in [^1])
" Returns [start_line, start_col, end_line, end_col] or empty array if not found
function! md#footnotes#getFootnoteTextRange(footnote_info)
  if empty(a:footnote_info) || a:footnote_info.type != 'reference'
    return []
  endif
  
  " For footnote references like [^1], the text is just the ID
  " start_col points to '[', so ID starts at start_col + 2
  let text_start_col = a:footnote_info.start_col + 2
  let text_end_col = a:footnote_info.end_col - 1
  
  return [a:footnote_info.line_num, text_start_col, a:footnote_info.line_num, text_end_col]
endfunction

" Get the range of the footnote definition content (everything after [^id]:)
" Returns [start_line, start_col, end_line, end_col] or empty array if not found
function! md#footnotes#getFootnoteDefinitionRange(footnote_info)
  if empty(a:footnote_info)
    return []
  endif
  
  if a:footnote_info.type == 'reference'
    " For references, find the definition and return its content range
    let def_line = s:findFootnoteDefinitionLine(a:footnote_info.id)
    if def_line == -1
      return []
    endif
    return s:getDefinitionContentRange(def_line, a:footnote_info.id)
  elseif a:footnote_info.type == 'definition'
    " For definitions, return the content range
    return s:getDefinitionContentRange(a:footnote_info.line_num, a:footnote_info.id)
  endif
  
  return []
endfunction

" Get the range of the entire footnote structure
" For references: [^id]
" For definitions: entire definition including continuation lines
function! md#footnotes#getFootnoteFullRange(footnote_info)
  if empty(a:footnote_info)
    return []
  endif
  
  if a:footnote_info.type == 'reference'
    " For references, return the entire [^id] range
    return [a:footnote_info.line_num, a:footnote_info.start_col, a:footnote_info.line_num, a:footnote_info.end_col]
  elseif a:footnote_info.type == 'definition'
    " For definitions, return the entire definition including continuation lines
    return s:getFullDefinitionRange(a:footnote_info.line_num, a:footnote_info.id)
  endif
  
  return []
endfunction

" Helper function to find the line number of a footnote definition
function! s:findFootnoteDefinitionLine(footnote_id)
  let line_num = 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    let pattern = '^\s*\[\^' . escape(a:footnote_id, '[]^$.*\~') . '\]:'
    if line_content =~ pattern
      return line_num
    endif
    let line_num += 1
  endwhile
  
  return -1
endfunction

" Helper function to get the content range of a footnote definition
function! s:getDefinitionContentRange(def_line_num, footnote_id)
  let line_content = getline(a:def_line_num)
  let pattern = '^\s*\[\^' . escape(a:footnote_id, '[]^$.*\~') . '\]:\s*\(.*\)$'
  let match = matchlist(line_content, pattern)
  
  if empty(match)
    return []
  endif
  
  " Find where the content starts on the first line
  let def_marker_end = match(line_content, '\]:\s*') + 2
  let content_start_col = def_marker_end + 1
  
  " If there's content on the first line, start there
  if !empty(match[1])
    let content_start_col = def_marker_end + 1
    while content_start_col <= len(line_content) && line_content[content_start_col - 1] == ' '
      let content_start_col += 1
    endwhile
  endif
  
  " Find the end of the definition content
  let end_line = a:def_line_num
  let last_line = line('$')
  
  " Look for continuation lines
  let line_num = a:def_line_num + 1
  let last_content_line = a:def_line_num
  while line_num <= last_line
    let line_content = getline(line_num)
    
    " Stop if we hit another footnote definition or non-indented content
    if line_content =~ '^\s*\[\^[^]]\+\]:' || (line_content !~ '^\s*$' && line_content !~ '^\s\+')
      break
    endif
    
    " Include indented lines and track the last line with actual content
    if line_content =~ '^\s\+'
      let end_line = line_num
      let last_content_line = line_num
    elseif line_content =~ '^\s*$'
      " Include empty lines within footnote, but don't update last_content_line
      let end_line = line_num
    else
      break
    endif
    
    let line_num += 1
  endwhile
  
  " Get the end column of the last line with actual content (excluding trailing blank lines)
  let actual_end_line = last_content_line
  let end_col = len(getline(actual_end_line))
  if end_col == 0
    let end_col = 1
  endif
  
  " Return range ending at the last line with content, not including trailing blank lines
  let end_line = actual_end_line
  
  return [a:def_line_num, content_start_col, end_line, end_col]
endfunction

" Helper function to get the full range of a footnote definition including the marker
function! s:getFullDefinitionRange(def_line_num, footnote_id)
  let content_range = s:getDefinitionContentRange(a:def_line_num, a:footnote_id)
  if empty(content_range)
    return []
  endif
  
  " Start from the beginning of the definition line
  return [a:def_line_num, 1, content_range[2], content_range[3]]
endfunction

" Find footnote continuation line at the given position
" Returns footnote definition info dict or {} if none found
function! s:findFootnoteContinuationAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  
  " Check if current line is an indented continuation line
  " Empty lines can be part of footnotes, but we need to verify they're actually within a footnote
  if line_content !~ '^\s\+' && line_content !~ '^\s*$'
    return {}
  endif
  
  " For empty lines, we need to be more careful - they should only match if they're 
  " truly within a footnote definition, not just any empty line
  let is_empty_line = line_content =~ '^\s*$'
  
  " Look backward to find the footnote definition this line belongs to
  let search_line = a:line_num - 1
  while search_line >= 1
    let search_content = getline(search_line)
    
    " Check if we found a footnote definition
    let pattern = '^\s*\[\^\([^]]\+\)\]:\s*\(.*\)$'
    let match = matchlist(search_content, pattern)
    if !empty(match)
      let footnote_id = match[1]
      
      " Verify that our line is part of this footnote's content
      if s:isLinePartOfFootnote(a:line_num, search_line, footnote_id)
        " For empty lines, also check if there's another footnote definition after our line
        " If so, this empty line is likely a separator, not part of the footnote
        if is_empty_line && s:hasFootnoteDefinitionAfter(a:line_num)
          break
        endif
        
        " Get full content including wrapped lines
        let full_content = s:getFootnoteDefinitionContent(search_line, footnote_id)
        
        return {
              \ 'type': 'definition',
              \ 'line_num': search_line,
              \ 'start_col': 1,
              \ 'end_col': len(search_content),
              \ 'id': footnote_id,
              \ 'content': full_content
              \ }
      else
        " This line is not part of the footnote, stop searching
        break
      endif
    endif
    
    " If we hit a non-indented, non-empty line that's not a footnote definition, stop
    if search_content !~ '^\s*$' && search_content !~ '^\s\+' && search_content !~ '^\s*\[\^[^]]\+\]:'
      break
    endif
    
    let search_line -= 1
  endwhile
  
  return {}
endfunction

" Helper function to check if a line is part of a footnote definition's content
function! s:isLinePartOfFootnote(line_num, def_line_num, footnote_id)
  let line_num = a:def_line_num + 1
  let last_line = line('$')
  
  while line_num <= last_line && line_num <= a:line_num
    let line_content = getline(line_num)
    
    " Stop if we hit another footnote definition
    if line_content =~ '^\s*\[\^[^]]\+\]:'
      return 0
    endif
    
    " Stop if we hit non-indented content (but allow empty lines)
    if line_content !~ '^\s*$' && line_content !~ '^\s\+'
      return 0
    endif
    
    " If this is our target line and we got here, it's part of the footnote
    if line_num == a:line_num
      return 1
    endif
    
    let line_num += 1
  endwhile
  
  return 0
endfunction

" Helper function to check if there's a footnote definition after a given line
function! s:hasFootnoteDefinitionAfter(line_num)
  let line_num = a:line_num + 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    
    " If we find a footnote definition, return true
    if line_content =~ '^\s*\[\^[^]]\+\]:'
      return 1
    endif
    
    " If we hit non-empty, non-indented content that's not a footnote, stop searching
    if line_content !~ '^\s*$' && line_content !~ '^\s\+'
      break
    endif
    
    let line_num += 1
  endwhile
  
  return 0
endfunction

" Find the next available integer footnote ID
" Returns the lowest integer not currently used as a footnote ID
function! md#footnotes#findNextAvailableId()
  " Collect all existing footnote IDs from both references and definitions
  let existing_ids = []
  let line_num = 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    
    " Check for footnote definitions
    let def_pattern = '^\s*\[\^\([^]]\+\)\]:'
    let def_match = matchlist(line_content, def_pattern)
    if !empty(def_match)
      call add(existing_ids, def_match[1])
    endif
    
    " Check for footnote references in the line
    let footnotes = md#footnotes#findFootnoteReferencesInLine(line_num)
    for footnote in footnotes
      call add(existing_ids, footnote.id)
    endfor
    
    let line_num += 1
  endwhile
  
  " Find the lowest integer ID not in use
  let next_id = 1
  while index(existing_ids, string(next_id)) != -1
    let next_id += 1
  endwhile
  
  return string(next_id)
endfunction

" Append a footnote reference at the specified position.
" Returns the footnote ID that was added
function! md#footnotes#addFootnoteReference(line_num, col_num, footnote_id)
  let line_content = getline(a:line_num)
  let reference = '[^' . a:footnote_id . ']'
  
  " Insert the reference at the specified position
  " col('.') is 1-based, but string slicing is 0-based
  " Special handling for insert mode: when using <C-o> in insert mode,
  " col('.') points to the NEXT character, except at end of line where it equals len(line)
  if a:col_num == len(line_content)
    " At end of line - insert after all content
    let before = line_content
    let after = ''
  else
    " In middle of line - insert before the character at col_num
    let before = line_content[:a:col_num - 2]
    let after = line_content[a:col_num - 1:]
  endif
  let new_line = before . reference . after
  
  call setline(a:line_num, new_line)
  
  return a:footnote_id
endfunction

" Add a footnote definition at the end of the file
" Returns the line number where the definition was added
function! md#footnotes#addFootnoteDefinition(footnote_id)
  let last_line = line('$')
  let definition = '[^' . a:footnote_id . ']: '
  
  " Add an empty line before the definition if the last line isn't empty
  if getline(last_line) !~ '^\s*$'
    call append(last_line, '')
    let last_line += 1
  endif
  
  " Add the footnote definition
  call append(last_line, definition)
  
  return last_line + 1
endfunction
