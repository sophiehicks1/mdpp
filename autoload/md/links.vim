"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for parsing and handling markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Find the link that contains the cursor position
" Returns a dictionary with link information or {} if no link found
function! md#links#findLinkAtCursor()
  let cursor_pos = getpos('.')
  let line_num = cursor_pos[1]
  let col_num = cursor_pos[2]
  
  " First check if we're on a reference definition line
  let ref_def_info = s:findReferenceDefinitionAtPosition(line_num, col_num)
  if !empty(ref_def_info)
    " Find the first link that references this definition
    let referring_link = s:findFirstReferringLink(ref_def_info.reference)
    if !empty(referring_link)
      return referring_link
    endif
    " If no referring link found, fall back to treating as regular reference definition
    return ref_def_info
  endif
  
  " Try to find a wiki link
  let wiki_link = s:findWikiLinkAtPosition(line_num, col_num)
  if !empty(wiki_link)
    return wiki_link
  endif
  
  " Try to find an inline link
  let inline_link = s:findInlineLinkAtPosition(line_num, col_num)
  if !empty(inline_link)
    return inline_link
  endif
  
  " Try to find a reference link
  let reference_link = s:findReferenceLinkAtPosition(line_num, col_num)
  if !empty(reference_link)
    return reference_link
  endif
  
  return {}
endfunction

" Find inline link at the given position
" Returns link info dict or {} if none found
"
" Link info dictionary structure:
" {
"   'type': 'inline' | 'reference',
"   'line_num': line number where link starts,
"   'start_col': start column of the link (1-indexed),
"   'end_col': end column of the link (1-indexed),
"   'text': the link text (content between [...]),
"   'text_start_col': start column of link text,
"   'text_end_col': end column of link text,
"   'url': the URL (for inline) or resolved URL (for reference),
"   'url_start_col': start column of URL (inline only),
"   'url_end_col': end column of URL (inline only),
"   'reference': reference label (reference links only),
"   'full_start_col': start column of entire link,
"   'full_end_col': end column of entire link
" }
function! s:findInlineLinkAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  let links = md#links#findInlineLinksInLine(a:line_num, line_content)
  
  for link in links
    if a:col_num >= link.start_col && a:col_num <= link.end_col
      return link
    endif
  endfor
  
  return {}
endfunction

" Find wiki link at the given position
" Returns link info dict or {} if none found
function! s:findWikiLinkAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  let links = md#links#findWikiLinksInLine(a:line_num, line_content)
  
  for link in links
    if a:col_num >= link.start_col && a:col_num <= link.end_col
      return link
    endif
  endfor
  
  return {}
endfunction

" Find reference link at the given position
" Returns link info dict or {} if none found
function! s:findReferenceLinkAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  let links = md#links#findReferenceLinksInLine(a:line_num, line_content)
  
  for link in links
    if a:col_num >= link.start_col && a:col_num <= link.end_col
      return link
    endif
  endfor
  
  return {}
endfunction

" Find all inline links in a line - PUBLIC for testing
" Returns list of link info dictionaries
function! md#links#findInlineLinksInLine(line_num, line_content)
  let links = []
  let pos = 0
  
  while 1
    " Find the next [ character
    let bracket_start = stridx(a:line_content, '[', pos)
    if bracket_start == -1
      break
    endif
    
    " Find the matching ] character
    let bracket_end = s:findMatchingBracket(a:line_content, bracket_start)
    if bracket_end == -1
      let pos = bracket_start + 1
      continue
    endif
    
    " Check if this is followed by a ( for inline link
    let paren_start = bracket_end + 1
    if paren_start >= len(a:line_content) || a:line_content[paren_start] != '('
      let pos = bracket_start + 1
      continue
    endif
    
    " Find the matching ) character
    let paren_end = s:findMatchingParen(a:line_content, paren_start)
    if paren_end == -1
      let pos = bracket_start + 1
      continue
    endif
    
    " Extract link components
    let text = a:line_content[bracket_start + 1 : bracket_end - 1]
    let url = a:line_content[paren_start + 1 : paren_end - 1]
    
    let link_info = {
          \ 'type': 'inline',
          \ 'line_num': a:line_num,
          \ 'start_col': bracket_start + 1,
          \ 'end_col': paren_end + 1,
          \ 'text': text,
          \ 'text_start_col': bracket_start + 2,
          \ 'text_end_col': bracket_end,
          \ 'url': url,
          \ 'url_start_col': paren_start + 2,
          \ 'url_end_col': paren_end,
          \ 'full_start_col': bracket_start + 1,
          \ 'full_end_col': paren_end + 1
          \ }
    
    call add(links, link_info)
    let pos = paren_end + 1
  endwhile
  
  return links
endfunction

" Find all reference links in a line - PUBLIC for testing
" Returns list of link info dictionaries
function! md#links#findReferenceLinksInLine(line_num, line_content)
  let links = []
  let pos = 0
  
  while 1
    " Find the next [ character
    let bracket_start = stridx(a:line_content, '[', pos)
    if bracket_start == -1
      break
    endif
    
    " Find the matching ] character
    let bracket_end = s:findMatchingBracket(a:line_content, bracket_start)
    if bracket_end == -1
      let pos = bracket_start + 1
      continue
    endif
    
    " Check if this is followed by another [ for reference link
    let ref_start = bracket_end + 1
    if ref_start >= len(a:line_content) || a:line_content[ref_start] != '['
      " Check for implicit reference (just [text][])
      let pos = bracket_start + 1
      continue
    endif
    
    " Find the matching ] character for reference
    let ref_end = s:findMatchingBracket(a:line_content, ref_start)
    if ref_end == -1
      let pos = bracket_start + 1
      continue
    endif
    
    " Extract link components
    let text = a:line_content[bracket_start + 1 : bracket_end - 1]
    let reference = a:line_content[ref_start + 1 : ref_end - 1]
    
    " If reference is empty, use text as reference (implicit reference)
    if empty(reference)
      let reference = text
    endif
    
    " Find the reference definition
    let ref_url = s:findReferenceDefinition(reference)
    
    let link_info = {
          \ 'type': 'reference',
          \ 'line_num': a:line_num,
          \ 'start_col': bracket_start + 1,
          \ 'end_col': ref_end + 1,
          \ 'text': text,
          \ 'text_start_col': bracket_start + 2,
          \ 'text_end_col': bracket_end,
          \ 'reference': reference,
          \ 'url': ref_url,
          \ 'full_start_col': bracket_start + 1,
          \ 'full_end_col': ref_end + 1
          \ }
    
    call add(links, link_info)
    let pos = ref_end + 1
  endwhile
  
  return links
endfunction

" Find all wiki links in a line - PUBLIC for testing
" Returns list of link info dictionaries
function! md#links#findWikiLinksInLine(line_num, line_content)
  let links = []
  let pos = 0
  
  while 1
    " Find the next [[ sequence
    let wiki_start = stridx(a:line_content, '[[', pos)
    if wiki_start == -1
      break
    endif
    
    " Find the matching ]] sequence
    let wiki_end = stridx(a:line_content, ']]', wiki_start + 2)
    if wiki_end == -1
      let pos = wiki_start + 2
      continue
    endif
    
    " Extract the content between [[ and ]]
    let wiki_content = a:line_content[wiki_start + 2 : wiki_end - 1]
    
    " Parse target and alias
    let pipe_pos = stridx(wiki_content, '|')
    if pipe_pos != -1
      " Has alias: [[Target|Alias]]
      let target = wiki_content[0 : pipe_pos - 1]
      let alias = wiki_content[pipe_pos + 1 : -1]
      let display_text = alias
      let target_start_col = wiki_start + 3
      let target_end_col = wiki_start + 2 + pipe_pos
      let text_start_col = wiki_start + 3 + pipe_pos + 1
      let text_end_col = wiki_end
    else
      " No alias: [[Target]]
      let target = wiki_content
      let alias = ''
      let display_text = target
      let target_start_col = wiki_start + 3
      let target_end_col = wiki_end
      let text_start_col = wiki_start + 3
      let text_end_col = wiki_end
    endif
    
    let link_info = {
          \ 'type': 'wiki',
          \ 'line_num': a:line_num,
          \ 'start_col': wiki_start + 1,
          \ 'end_col': wiki_end + 2,
          \ 'text': display_text,
          \ 'text_start_col': text_start_col,
          \ 'text_end_col': text_end_col,
          \ 'target': target,
          \ 'target_start_col': target_start_col,
          \ 'target_end_col': target_end_col,
          \ 'alias': alias,
          \ 'url': target,
          \ 'full_start_col': wiki_start + 1,
          \ 'full_end_col': wiki_end + 2
          \ }
    
    call add(links, link_info)
    let pos = wiki_end + 2
  endwhile
  
  return links
endfunction

" Find matching bracket, handling nested brackets
function! s:findMatchingBracket(text, start_pos)
  let bracket_count = 1
  let pos = a:start_pos + 1
  
  while pos < len(a:text) && bracket_count > 0
    let char = a:text[pos]
    if char == '['
      let bracket_count += 1
    elseif char == ']'
      let bracket_count -= 1
    endif
    let pos += 1
  endwhile
  
  if bracket_count == 0
    return pos - 1
  else
    return -1
  endif
endfunction

" Find matching parenthesis, handling nested parentheses
function! s:findMatchingParen(text, start_pos)
  let paren_count = 1
  let pos = a:start_pos + 1
  
  while pos < len(a:text) && paren_count > 0
    let char = a:text[pos]
    if char == '('
      let paren_count += 1
    elseif char == ')'
      let paren_count -= 1
    endif
    let pos += 1
  endwhile
  
  if paren_count == 0
    return pos - 1
  else
    return -1
  endif
endfunction

" Find reference definition for a given reference label
" Returns the URL or empty string if not found
function! s:findReferenceDefinition(reference)
  let line_num = 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    " Match reference definition: [ref]: url
    let pattern = '^\s*\[' . escape(a:reference, '[]') . '\]:\s*\(\S\+\)'
    let match = matchlist(line_content, pattern)
    if !empty(match)
      return match[1]
    endif
    let line_num += 1
  endwhile
  
  return ''
endfunction

" Get the text content of a link (what's between the [])
function! md#links#getLinkText(link_info)
  if empty(a:link_info)
    return ''
  endif
  return a:link_info.text
endfunction

" Get the URL of a link
function! md#links#getLinkUrl(link_info)
  if empty(a:link_info)
    return ''
  endif
  return a:link_info.url
endfunction

" Get position range for link text selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkTextRange(link_info)
  if empty(a:link_info)
    return []
  endif
  return [a:link_info.line_num, a:link_info.text_start_col, a:link_info.line_num, a:link_info.text_end_col]
endfunction

" Get position range for link URL selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkUrlRange(link_info)
  if empty(a:link_info)
    return []
  endif
  
  if a:link_info.type == 'inline'
    return [a:link_info.line_num, a:link_info.url_start_col, a:link_info.line_num, a:link_info.url_end_col]
  elseif a:link_info.type == 'reference'
    " For reference links, find the definition line
    let def_range = s:findReferenceDefinitionRange(a:link_info.reference)
    return def_range
  elseif a:link_info.type == 'wiki'
    " For wiki links, return the target portion
    return [a:link_info.line_num, a:link_info.target_start_col, a:link_info.line_num, a:link_info.target_end_col]
  endif
  
  return []
endfunction

" Get position range for entire link selection
" Returns [start_line, start_col, end_line, end_col] or [] if no link
function! md#links#getLinkFullRange(link_info)
  if empty(a:link_info)
    return []
  endif
  return [a:link_info.line_num, a:link_info.full_start_col, a:link_info.line_num, a:link_info.full_end_col]
endfunction

" Find the range for a reference definition URL
function! s:findReferenceDefinitionRange(reference)
  let line_num = 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    " Match reference definition: [ref]: url
    let pattern = '^\s*\[' . escape(a:reference, '[]') . '\]:\s*\(\S\+\)'
    let match_start = match(line_content, pattern)
    if match_start != -1
      " Find the URL part
      let url_pattern = '^\s*\[' . escape(a:reference, '[]') . '\]:\s*'
      let url_start = match(line_content, url_pattern) + len(matchstr(line_content, url_pattern))
      let url_end = match(line_content, '\s', url_start)
      if url_end == -1
        let url_end = len(line_content)
      else
        let url_end = url_end - 1
      endif
      return [line_num, url_start + 1, line_num, url_end + 1]
    endif
    let line_num += 1
  endwhile
  
  return []
endfunction

" Find reference definition at the given position
" Returns reference definition info dict or {} if none found
function! s:findReferenceDefinitionAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  
  " Match reference definition: [ref]: url
  let pattern = '^\s*\[\([^\]]\+\)\]:\s*\(\S\+\)'
  let match = matchlist(line_content, pattern)
  if !empty(match)
    let reference = match[1]
    let url = match[2]
    
    " Check if cursor is within this definition
    let def_start = match(line_content, pattern)
    let def_end = def_start + len(match[0]) - 1
    
    if a:col_num >= def_start + 1 && a:col_num <= def_end + 1
      return {
            \ 'type': 'reference_definition',
            \ 'line_num': a:line_num,
            \ 'reference': reference,
            \ 'url': url,
            \ 'start_col': def_start + 1,
            \ 'end_col': def_end + 1
            \ }
    endif
  endif
  
  return {}
endfunction

" Find the first link that references the given reference label
" Returns link info dict or {} if none found
function! s:findFirstReferringLink(reference)
  let line_num = 1
  let last_line = line('$')
  
  while line_num <= last_line
    let line_content = getline(line_num)
    let links = md#links#findReferenceLinksInLine(line_num, line_content)
    
    for link in links
      if link.reference ==# a:reference
        return link
      endif
    endfor
    
    let line_num += 1
  endwhile
  
  return {}
endfunction