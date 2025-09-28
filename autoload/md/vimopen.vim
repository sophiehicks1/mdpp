"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-open integration for markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Setup vim-open integration if the plugin is available
function! md#vimopen#setup()
  if !exists('g:loaded_vim_open')
    return
  endif
  
  " Add markdown link finder to vim-open
  call gopher#add_finder(function('s:is_markdown_link'), function('s:extract_markdown_link'))
endfunction

" Check if the cursor is on a markdown link
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
  
  " Return true if we have any non-empty URL/address
  return !empty(url)
endfunction

" Extract the link address from a markdown link
function! s:extract_markdown_link(context)
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  
  if empty(link_info)
    return ''
  endif
  
  " Return the raw URL/address - let vim-open decide how to handle it
  return md#links#getLinkUrl(link_info)
endfunction