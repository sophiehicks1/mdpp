"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-open integration for markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Default wiki link resolution function
" Takes a wiki link target and returns a file path
function! s:default_wiki_resolver(target)
  return a:target . '.md'
endfunction

" Get the configured wiki link resolver function
function! s:get_wiki_resolver()
  if exists('g:Mdpp_wiki_resolver') && type(g:Mdpp_wiki_resolver) == type(function('tr'))
    return g:Mdpp_wiki_resolver
  endif
  if exists('g:mdpp_wiki_resolver') && type(g:mdpp_wiki_resolver) == type(function('tr'))
    return g:mdpp_wiki_resolver
  endif
  return function('s:default_wiki_resolver')
endfunction

" Setup vim-open integration if the plugin is available
function! md#vimopen#setup()
  if !exists('g:loaded_vim_open')
    return
  endif
  
  " Add wiki link finder to vim-open FIRST (more specific)
  call gopher#add_finder(function('s:is_wiki_link'), function('s:extract_wiki_link'))
  
  " Add general markdown link finder to vim-open SECOND (more general)
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

" Check if the cursor is on a wiki link (separate from regular markdown links)
function! s:is_wiki_link(context)
  " Only apply to markdown files
  if a:context.filetype != 'markdown'
    return 0
  endif
  
  " Find wiki links specifically
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  
  if empty(link_info)
    return 0
  endif
  
  " Only return true for wiki links
  return link_info.type == 'wiki'
endfunction

" Extract the wiki link target and resolve it through the configured resolver
function! s:extract_wiki_link(context)
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  
  if empty(link_info) || link_info.type != 'wiki'
    return ''
  endif
  
  " Get the wiki target (not the display text)
  let target = link_info.target
  
  " Apply the wiki link resolver function
  let Resolver = s:get_wiki_resolver()
  return Resolver(target)
endfunction