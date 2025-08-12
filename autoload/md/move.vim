"""""""""""""""""""
" Movement mappings
"""""""""""""""""""

function! s:restoreVisual(mode)
  if a:mode !=# 'n'
    normal! gv
  endif
endfunction

" v:count of 0 means no explicit count was passed, so count ahould be 1
function! s:normalizeCount()
  let count = v:count
  if v:count == 0
    let count = 1
  endif
  return count
endfunction

" push current position to the jumplist and then move to the new target line
function! s:goToLine(lnum)
  normal! m`
  call cursor(a:lnum, 1)
endfunction

" Movement command implementations

" Each of the movement actions follows the same pattern. Essentially they
" all move to X (where X is defined by a dom function), or leave the cursor
" where it is if X couldn't be found. Here's how it works step by step:
" - refresh the dom tree
" - restore the visual state (since it's lost when the command invokes the
"   function)
" - figure out how many times we need to execute the move. Each move is done
"   as follows:
"   - pass the current line to a dom function that returns a target line (or
"     -1 if there is no target, in which case we set the target to the current
"     line)
"   - move to the target line if one was found.
function! s:executeMove(domFunction, mode)
  call md#dom#refreshDocument()
  let count = s:normalizeCount()
  call s:restoreVisual(a:mode)
  for i in range(1, count)
    let l:TargetFinder = function("md#dom#" . a:domFunction, ['.'])
    let targetLnum = l:TargetFinder()
    if targetLnum != -1
      call s:goToLine(targetLnum)
    endif
  endfor
endfunction

" Create the command wrapper functions for normal and visual modes

let s:commands = [
      \ 'backToHeading',
      \ 'forwardToHeading',
      \ 'backToSibling',
      \ 'forwardToSibling',
      \ 'backToParent',
      \ 'forwardToFirstChild'
      \ ]

let s:domFunctions = {
      \ 'backToHeading': 'headingLnumBefore',
      \ 'forwardToHeading': 'headingLnumAfter',
      \ 'backToSibling': 'siblingHeadingLnumBefore',
      \ 'forwardToSibling': 'siblingHeadingLnumAfter',
      \ 'backToParent': 'parentHeadingLnum',
      \ 'forwardToFirstChild': 'firstChildHeadingLnum'
      \ }

let s:modes = {
      \ 'n': 'Normal',
      \ 'v': 'Visual'
      \ }

" Generate the function definitions for each command and mode
for command in s:commands
  for mode in keys(s:modes)
    let newFunctionName = 'md#move#' . command . s:modes[mode]
    let domFunction = s:domFunctions[command]
    execute "function! ". newFunctionName . "()\n" .
          \ "  call s:executeMove('" . domFunction . "', '" . mode . "')" . "\n" .
          \ "endfunction"
  endfor
endfor
