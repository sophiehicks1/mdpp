"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-open integration for markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Setup vim-open integration if the plugin is available
function! md#vimopen#setup()
  if !exists('*gopher#add_finder')
    return
  endif
  
  " Add markdown link finder to vim-open
  call gopher#add_finder(function('s:is_markdown_link'), function('s:extract_markdown_link'))
endfunction

" Check if the cursor is on a markdown link that could be a file path
function! s:is_markdown_link(context)
  " Only apply to markdown files
  if a:context.filetype != 'markdown'
    return 0
  endif
  
  " Use existing link detection
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  
  if empty(link_info)
    return 0
  endif
  
  " Get the URL from the link
  let url = md#links#getLinkUrl(link_info)
  
  " Check if it looks like a file path (not a URL)
  return s:looks_like_file_path(url)
endfunction

" Extract the file path from a markdown link
function! s:extract_markdown_link(context)
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  
  if empty(link_info)
    return ''
  endif
  
  let url = md#links#getLinkUrl(link_info)
  
  " Clean up the URL to make it a proper file path
  return s:clean_file_path(url)
endfunction

" Check if a URL looks like a file path rather than a web URL
function! s:looks_like_file_path(url)
  if empty(a:url)
    return 0
  endif
  
  " Exclude web URLs
  if a:url =~? '^https\?://' || a:url =~? '^ftp://' || a:url =~? '^mailto:'
    return 0
  endif
  
  " Include things that look like file paths
  " - Relative paths: ./file.md, ../file.md, file.md
  " - Absolute paths: /path/to/file.md
  " - Home directory paths: ~/file.md
  " - Paths with common file extensions
  return a:url =~ '^\~/' || 
       \ a:url =~ '^\.\./' ||
       \ a:url =~ '^\.\/' ||
       \ a:url =~ '^/' ||
       \ a:url =~ '\.\w\+$' ||
       \ a:url !~ '://'
endfunction

" Clean up a URL to make it a proper file path
function! s:clean_file_path(url)
  let path = a:url
  
  " Remove URL fragments and query parameters
  let path = substitute(path, '[#?].*$', '', '')
  
  " URL decode common encoded characters
  let path = substitute(path, '%20', ' ', 'g')
  let path = substitute(path, '%23', '#', 'g')
  let path = substitute(path, '%25', '%', 'g')
  
  return path
endfunction