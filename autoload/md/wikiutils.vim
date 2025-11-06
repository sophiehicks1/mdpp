" Get the root directory for wikilink resolution
function! md#wikiutils#getWikilinkRoot()
  if exists('g:mdpp_wikilink_root') && type(g:mdpp_wikilink_root) == type('')
    return g:mdpp_wikilink_root
  endif
  return '.'
endfunction
