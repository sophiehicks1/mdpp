"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" vim-open integration for markdown links
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:get_markdown_link_extractor()
  if exists('g:Mdpp_vimopen_markdown_extractor') && type(g:Mdpp_vimopen_markdown_extractor) == type(function('tr'))
    return g:Mdpp_vimopen_markdown_extractor
  endif
  return function('s:extract_markdown_link')
endfunction

function! s:get_wiki_link_extractor()
  if exists('g:Mdpp_vimopen_wikilink_extractor') && type(g:Mdpp_vimopen_wikilink_extractor) == type(function('tr'))
    return g:Mdpp_vimopen_wikilink_extractor
  endif
  return function('s:extract_wiki_link')
endfunction

" Setup vim-open integration if the plugin is available
function! md#vimopen#setup()
  if !exists('g:loaded_vim_open')
    return
  endif

  if exists('g:mdpp_vimopen_integration') && g:mdpp_vimopen_integration == 0
    return
  endif
  
  " Add markdown link finder to vim-open
  call gopher#add_finder(function('s:is_markdown_link'), s:get_markdown_link_extractor())
  call gopher#add_finder(function('s:is_wiki_link'), s:get_wiki_link_extractor())
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
  
  " Get the target from the link
  let target = md#links#getLinkTarget(link_info)
  
  " Return true if we have any non-empty target/address
  return !empty(target)
endfunction

" Extract the link address from a link
function! s:extract_address_text(context)
  let pos = [0, a:context.lnum, a:context.col, 0]
  let link_info = md#links#findLinkAtPos(pos)
  if empty(link_info)
    return ''
  endif
  return md#links#getLinkTarget(link_info)
endfunction

" We pass markdown links directly to vim-open as raw text
function! s:extract_markdown_link(context)
  return s:extract_address_text(a:context)
endfunction

function! s:default_resolver(text)
  let root = md#wikiutils#getWikilinkRoot()
  return root . '/' . a:text . '.md'
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
