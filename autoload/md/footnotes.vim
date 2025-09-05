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

    " Check if cursor is within the footnote definition
    let def_start = match(line_content, '\[\^\([^]]\+\)\]:')
    let def_end = def_start + len('[^' . footnote_id . ']:')
    if a:col_num >= def_start + 1 && a:col_num <= def_end
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

  " Debug output for testing
  " echom "DEBUG: paragraphs = " . string(paragraphs)

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
