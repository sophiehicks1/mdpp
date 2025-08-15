"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin functionality for markdown link text objects and operations
"
" This module provides the user-facing plugin functionality for working with
" markdown links. It calls into the semantic parsing module md#parse for the
" heavy lifting of understanding markdown syntax.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Find the link that contains the cursor position
" Returns a dictionary with link information or {} if no link found
function! md#links#findLinkAtCursor()
  let cursor_pos = getpos('.')
  let line_num = cursor_pos[1]
  let col_num = cursor_pos[2]
  
  " First check if we're on a reference definition line
  let ref_def_info = md#parse#referenceDefinitionAtPosition(line_num, col_num)
  if !empty(ref_def_info)
    " Find the first link that references this definition
    let referring_link = md#parse#findFirstReferringLink(ref_def_info.reference)
    if !empty(referring_link)
      " Add the URL from the definition to the referring link
      let referring_link.url = ref_def_info.url
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
function! s:findInlineLinkAtPosition(line_num, col_num)
  let line_content = getline(a:line_num)
  let links = md#parse#inlineLinksInLine(a:line_num, line_content)
  
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
  let links = md#parse#wikiLinksInLine(a:line_num, line_content)
  
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
  let links = md#parse#referenceLinksInLine(a:line_num, line_content)
  
  for link in links
    if a:col_num >= link.start_col && a:col_num <= link.end_col
      " Resolve the URL for reference links
      let link.url = md#parse#findReferenceDefinition(link.reference)
      return link
    endif
  endfor
  
  return {}
endfunction

" Find all inline links in a line - PUBLIC for testing
" Delegates to semantic parser
function! md#links#findInlineLinksInLine(line_num, line_content)
  return md#parse#inlineLinksInLine(a:line_num, a:line_content)
endfunction

" Find all reference links in a line - PUBLIC for testing  
" Delegates to semantic parser
function! md#links#findReferenceLinksInLine(line_num, line_content)
  let links = md#parse#referenceLinksInLine(a:line_num, a:line_content)
  
  " Resolve URLs for reference links
  for link in links
    let link.url = md#parse#findReferenceDefinition(link.reference)
  endfor
  
  return links
endfunction

" Find all wiki links in a line - PUBLIC for testing
" Delegates to semantic parser
function! md#links#findWikiLinksInLine(line_num, line_content)
  return md#parse#wikiLinksInLine(a:line_num, a:line_content)
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
    let def_range = md#parse#findReferenceDefinitionRange(a:link_info.reference)
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

