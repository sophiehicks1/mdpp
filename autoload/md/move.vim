"""""""""""""""""""
" Movement mappings
"""""""""""""""""""

" Utility functions

function! s:goTo(mode, lnum)
  if a:mode !=# 'n'
    normal! gv
  endif
  call cursor(a:lnum, 1)
endfunction

function! s:normalizeCount()
  let count = v:count
  if v:count == 0
    let count = 1
  endif
  return count
endfunction

" Movement command implementations

" Each of these movement actions follows the same pattern. Essentially they
" all move to X (where X is defined by a dom function), or leave the cursor
" where it is if X couldn't be found. Here's how it works step by step:
" - refresh the dom tree
" - get the current line as a number
" - pass that to a dom function that returns a target line (or -1 if there is
"   no target, in which case we set the target to the current line)
" - move to the target line
function! s:generateMoveFunctionImplementation(action, domFunction)
  return  "function! s:" . a:action . "(mode)\n" .
        \ "  call md#dom#refreshDocumentTree()\n" .
        \ "  let currentLnum = line('.')\n" .
        \ "  let targetLnum = md#dom#" . a:domFunction . "(currentLnum)\n" .
        \ "  if targetLnum == -1\n" .
        \ "    let targetLnum = currentLnum\n" .
        \ "  endif\n" .
        \ "  call s:goTo(a:mode, targetLnum)\n" .
        \ "endfunction"
endfunction

let s:implementations = [
      \ ['backToHeading', 'headingLnumBefore'],
      \ ['forwardToHeading', 'headingLnumAfter'],
      \ ['backToSibling', 'siblingHeadingLnumBefore'],
      \ ['forwardToSibling', 'siblingHeadingLnumAfter'],
      \ ['backToParent', 'parentHeadingLnum'],
      \ ['forwardToFirstChild', 'firstChildHeadingLnum']
      \ ]

for [action, domFunction] in s:implementations
  execute s:generateMoveFunctionImplementation(action, domFunction)
endfor

" Create the command wrapper functions for normal and visual modes

let s:modes = {
      \ 'n': 'Normal',
      \ 'v': 'Visual'
      \ }

let s:commands = [
      \ 'backToHeading',
      \ 'forwardToHeading',
      \ 'backToSibling',
      \ 'forwardToSibling',
      \ 'backToParent',
      \ 'forwardToFirstChild'
      \ ]

function! s:moveWrapperName(command, mode)
  return 'md#move#' . a:command . s:modes[a:mode]
endfunction

" Return an executable string that defines the entire function
function! s:generateMoveFunctionWrapper(command, mode)
  let modeName = s:modes[a:mode]
  let functionName = s:moveWrapperName(a:command, a:mode)
  return 'function! ' . functionName . '()' . "\n" .
        \ '  let count = s:normalizeCount()' . "\n" .
        \ '  for i in range(1, count)' . "\n" .
        \ '    call s:' . a:command . "('" . a:mode . "')" . "\n" .
        \ '  endfor' . "\n" .
        \ 'endfunction'
endfunction 

" Generate the function definitions for each command and mode
for command in s:commands
  for mode in keys(s:modes)
    execute s:generateMoveFunctionWrapper(command, mode)
  endfor
endfor
