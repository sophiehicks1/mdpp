" These functions exist for testing purposes only.
"
" Why they used to exist:
"
" Originally, MDPP links were parsed on demand by md#links#find___LinksInLine
" functions, which worked by joining the current line with the one before and
" the one after, scanning the combined string for its own type of link. The
" primary findLinkAtPos public api function therefore worked by running each
" of these find___LinksInLine functions in turn, filtering the results for a
" link matching the current position.
"
" In order to test each type of link separately these functions were made
" public, since they were the highest level internal function that explicitly
" handled a single link type.
"
" Why they're not needed any more
"
" This structure made it impossible to share the same link implementation
" between the on-demand implementation used for text objects (as described
" above) and a whole-file implementation used for link indexing across a wiki;
"
" When the links module changed to its current structure using the b:dom,
" these functions no longer needed to exist, however they were reimplemented
" on top of the new b:dom-backed API, to preserve the large suite of tests
" written against them.
"
"
" DO NOT USE THESE IN PRODUCTION CODE!

function! s:findLinksInLineWithType(line_num, link_type)
  call md#dom#refreshDocument()
  let links = md#dom#getLinksInLine(a:line_num)
  let results = []
  for link in links
    if link.type == a:link_type
      call add(results, link)
    endif
  endfor
  return results
endfunction

" Find all inline links in a line - PUBLIC for testing
function! md#links#testfns#findInlineLinksInLine(line_num)
  return s:findLinksInLineWithType(a:line_num, 'inline')
endfunction

" Find all reference links in a line - PUBLIC for testing
function! md#links#testfns#findReferenceLinksInLine(line_num)
  return s:findLinksInLineWithType(a:line_num, 'reference')
endfunction

" Find all wiki links in a line - PUBLIC for testing
function! md#links#testfns#findWikiLinksInLine(line_num)
  return s:findLinksInLineWithType(a:line_num, 'wiki')
endfunction

