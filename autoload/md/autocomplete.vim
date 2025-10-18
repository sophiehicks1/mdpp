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
  " Collect files using globpath for better compatibility
  let files = []
  
  if empty(a:text)
    " No prefix: find all markdown files recursively using globpath
    if has('patch-7.4.279')
      let files = globpath('.', '**/*.md', 0, 1)
    else
      let files = split(globpath('.', '**/*.md'), '\n')
    endif
  else
    " With prefix: find files in current dir and subdirs that match prefix
    " Use two separate patterns to avoid issues with ** wildcard
    let pattern1 = a:text . '*.md'
    let pattern2 = a:text . '*/**/*.md'
    
    if has('patch-7.4.279')
      call extend(files, globpath('.', pattern1, 0, 1))
      call extend(files, globpath('.', pattern2, 0, 1))
    else
      call extend(files, split(globpath('.', pattern1), '\n'))
      call extend(files, split(globpath('.', pattern2), '\n'))
    endif
  endif
  
  " Convert to relative paths and remove ./ prefix and .md suffix
  let completions = []
  for file in files
    if file =~# '^\./'
      " Use strpart for safer string manipulation - remove './' prefix (2 chars)
      let relative_path = strpart(file, 2)
      if relative_path =~# '\.md$'
        " Remove '.md' suffix (3 characters from the end)
        let path_len = len(relative_path)
        let completion = strpart(relative_path, 0, path_len - 3)
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
    if isdirectory(dir) && dir =~# '^\./'
      " Use strpart for safer string manipulation
      let relative_path = strpart(dir, 2)  " Remove './' prefix
      " Only add if it contains markdown files - check safely
      let dir_glob_result = glob(dir . '/*.md')
      if !empty(dir_glob_result)
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
