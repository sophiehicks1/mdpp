" mdpp autocomplete setup for markdown files

" Only run once
if exists('b:mdpp_autocomplete_loaded')
  finish
endif
let b:mdpp_autocomplete_loaded = 1

" Setup autocomplete
setlocal completefunc=md#autocomplete#complete
inoremap <buffer> <expr> [[ md#autocomplete#triggerCompletion()