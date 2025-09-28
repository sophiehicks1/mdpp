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
  call gopher#add_finder(function('s:is_wiki_link'), function('s:extract_wiki_link'))
endfunction

function! s:is_wiki_link(context)
  return s:is_link_with_type(a:context, 'wiki')
endfunction

function! s:is_markdown_link(context)
  return s:is_link_with_type(a:context, 'inline')
        \ || s:is_link_with_type(a:context, 'reference')
        \ || s:is_link_with_type(a:context, 'reference_definition')
endfunction

function! s:is_link_with_type(context, link_type)
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

  " Check link type
  if link_info.type !=# a:link_type
    return 0
  endif
  
  " Get the URL from the link
  let url = md#links#getLinkUrl(link_info)
  
  " Return true if we have any non-empty URL/address
  return !empty(url)
endfunction

" Extract the link address from a link
function! s:extract_address_text(context)
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  if empty(link_info)
    return ''
  endif
  return md#links#getLinkUrl(link_info)
endfunction

" We pass markdown links directly to vim-open as raw text
function! s:extract_markdown_link(context)
  return s:extract_address_text(a:context)
endfunction

function! s:default_resolver(text)
  return './' . a:text . '.md'
endfunction

function! s:get_wiki_link_resolver()
  if exists('g:Mdpp_wiki_resolver') && type(g:Mdpp_wiki_resolver) == type(function('tr'))
    return g:Mdpp_wiki_resolver
  endif
  return function('s:default_resolver')
endfunction

" We pass wiki links through a resolver before passing them to vim-open
function! s:extract_wiki_link(context)
  let address_text = s:extract_address_text(a:context)
  let Resolver = s:get_wiki_link_resolver()
  return Resolver(address_text)
endfunction
