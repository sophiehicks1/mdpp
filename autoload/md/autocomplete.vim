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
  " Build glob patterns based on prefix
  if empty(a:text)
    " No prefix: find all markdown files recursively
    let patterns = ['./**/*.md']
  else
    " With prefix: find files in current dir and subdirs that match prefix
    let patterns = ['./' . a:text . '*.md', './' . a:text . '*/**/*.md']
  endif
  
  " Collect files from all patterns
  let files = []
  for pattern in patterns
    " Use glob with list return if available, otherwise split string result
    if exists('*glob') && has('patch-7.4.279')
      call extend(files, glob(pattern, 0, 1))
    else
      call extend(files, split(glob(pattern), '\n'))
    endif
  endfor
  
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
  
  if exists('*glob') && has('patch-7.4.279')
    let dirs = glob(dir_pattern, 0, 1)
  else
    let dirs = split(glob(dir_pattern), '\n')
  endif
  
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
  " Check if autocomplete is disabled
  if !md#autocomplete#isEnabled()
    return -1
  endif
  
  if a:findstart
    " Find the start of the wikilink text
    let line = getline('.')
    let col = col('.') - 1  " Convert to 0-based
    let line_len = len(line)
    
    " Look backwards for [[
    let i = col - 1
    while i >= 0
      " Check if we can safely access line[i] and line[i+1]
      if i >= 0 && i < line_len && (i + 1) < line_len
        " Use safer string comparison with strpart
        if strpart(line, i, 2) ==# '[['
          " Return 1-based position after [[ for Vim
          return i + 3
        endif
        " If we hit a ], stop looking (we're not in a wikilink)
        if strpart(line, i, 1) ==# ']'
          break
        endif
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
