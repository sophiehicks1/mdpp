"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Autocomplete functionality for markdown wikilinks
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Check if wikilink autocomplete is enabled
function! md#autocomplete#isEnabled()
  if exists('g:mdpp_wikilink_autocomplete')
    return g:mdpp_wikilink_autocomplete
  endif
  
  " Default to enabled if vim-open is available, disabled otherwise
  return exists('g:loaded_vim_open') && g:loaded_vim_open
endfunction

" Get the completion function to use
function! s:getCompletionFunction()
  if exists('g:Mdpp_wikilink_completion_fn') && type(g:Mdpp_wikilink_completion_fn) == type(function('tr'))
    return g:Mdpp_wikilink_completion_fn
  endif
  return function('s:defaultCompletion')
endfunction

" Default completion function - finds markdown files relative to current directory
" Uses same semantics as the default wiki-link resolver
function! s:defaultCompletion(text)
  let pattern = './' . (empty(a:text) ? '*' : a:text . '*') . '.md'
  let files = glob(pattern, 0, 1)
  
  " Convert to relative paths and remove ./ prefix and .md suffix
  let completions = []
  for file in files
    if file =~ '^\./'
      let relative_path = file[2:]  " Remove './' prefix
      if relative_path =~ '\.md$'
        let completion = relative_path[:-4]  " Remove '.md' suffix
        call add(completions, completion)
      endif
    endif
  endfor
  
  " Also look for directories that might contain markdown files
  let dir_pattern = './' . (empty(a:text) ? '*' : a:text . '*')
  let dirs = glob(dir_pattern, 0, 1)
  for dir in dirs
    if isdirectory(dir) && dir =~ '^\./'
      let relative_path = dir[2:]  " Remove './' prefix
      " Only add if it contains markdown files
      if !empty(glob(dir . '/*.md'))
        call add(completions, relative_path)
      endif
    endif
  endfor
  
  return completions
endfunction

" Main completion function called by Vim's completion system
function! md#autocomplete#complete(findstart, base)
  if a:findstart
    " Find the start of the wikilink text
    let line = getline('.')
    let col = col('.') - 1  " Convert to 0-based
    
    " Look backwards for [[
    let i = col - 1
    while i >= 0
      if i >= 0 && (i+1) < len(line) && line[i] == '[' && line[i + 1] == '['
        " Return 1-based position after [[ for Vim
        return i + 3
      endif
      " If we hit a ], stop looking (we're not in a wikilink)  
      if i < len(line) && line[i] == ']'
        break
      endif
      let i -= 1
    endwhile
    
    return -1
  else
    " Return the list of completions
    let CompletionFn = s:getCompletionFunction()
    return CompletionFn(a:base)
  endif
endfunction

" Insert mode mapping function to trigger completion
function! md#autocomplete#triggerCompletion()
  " Insert the [[ characters
  let result = '[['
  
  " If autocomplete is enabled, trigger completion
  if md#autocomplete#isEnabled()
    let result .= "\<C-x>\<C-u>"
  endif
  
  return result
endfunction