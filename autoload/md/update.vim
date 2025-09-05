function! md#update#incHeadingLevel(withDescendents)
  call md#dom#refreshDocument()
  call md#dom#incDescendentHeadings('.', a:withDescendents)
endfunction

function! md#update#decHeadingLevel(withDescendents)
  call md#dom#refreshDocument()
  call md#dom#decDescendentHeadings('.', a:withDescendents)
endfunction

function! md#update#nestSection()
  call md#dom#refreshDocument()
  call md#dom#nestSection('.') 
  normal! k
endfunction

function! s:linesToMove(lnumsToMove)
  let firstLnum = a:lnumsToMove[0]
  let lastLnum = a:lnumsToMove[-1]
  return getline(firstLnum, a:lnumsToMove[-1])
endfunction

function! s:deleteLines(lnumsToMove)
  execute a:lnumsToMove[0] . "d" . (a:lnumsToMove[-1] - a:lnumsToMove[0] + 1)
endfunction

" Move the current section back to a:targetLnum. We get the lines, delete them
" from the buffer, and them append them at the target lnum higher up.
function! s:moveSectionBackwards(targetLnum)
  let lnumsToMove = md#dom#sectionLnums('.', 1)
  let linesToMove = s:linesToMove(lnumsToMove)
  call s:deleteLines(lnumsToMove)
  call append(a:targetLnum - 1, linesToMove)
  execute a:targetLnum
endfunction

function! md#update#moveSectionBack()
  call md#dom#refreshDocument()
  " we want to insert before the previous sibling
  let targetLnum = md#dom#siblingHeadingLnumBefore('.')
  if targetLnum == -1
    return
  endif
  call s:moveSectionBackwards(targetLnum)
endfunction

" Move the current section forward, appending it after a:appendToLnum. We get
" the lines, append them to the buffer at the target, and then delete the
" origin lines from higher up in the document.
function! s:moveSectionForwards(appendToLnum)
  let lnumsToMove = md#dom#sectionLnums('.', 1)
  let linesToMove = s:linesToMove(lnumsToMove)
  call append(a:appendToLnum, linesToMove)
  call s:deleteLines(lnumsToMove)
  let postMoveLnum = a:appendToLnum - len(lnumsToMove) + 1
  execute postMoveLnum
endfunction

function! md#update#moveSectionForward()
  call md#dom#refreshDocument()
  " we want to append the section after the last line of the next sibling
  let nextSibling = md#dom#siblingHeadingLnumAfter('.')
  if nextSibling == -1
    return
  endif
  let appendToLnum = md#dom#sectionLnums(nextSibling, 1)[-1]
  call s:moveSectionForwards(appendToLnum)
endfunction

" Pop the current section up a level in the document tree, so that it becomes
" a sibling to it's former parent, before the parent
function! md#update#raiseSectionBack()
  call md#dom#refreshDocument()
  " we want to move back to before the parent of the current section
  let sectionLnum = md#dom#sectionHeadingLnum('.')
  if sectionLnum == -1
    return
  endif
  let targetLnum = md#dom#parentHeadingLnum(sectionLnum)
  if targetLnum == -1
    return
  endif
  call s:moveSectionBackwards(targetLnum)
  call md#update#decHeadingLevel(1)
endfunction

" Pop the current section up a level in the document tree, so that it becomes
" a sibling to it's former parent, after the parent
function! md#update#raiseSectionForward()
  call md#dom#refreshDocument()
  " we want to append forward, to after the end of the last sibling to the current section
  let siblingHeadings = md#dom#siblingHeadingLnums('.')
  if len(siblingHeadings) == 1
    " there's only one sibling, which means we don't have to move it.
  else
    let lastSiblingLnums = md#dom#sectionLnums(siblingHeadings[-1], 1)
    let appendToLnum = lastSiblingLnums[-1]
    call s:moveSectionForwards(appendToLnum)
  endif
  call md#update#decHeadingLevel(1)
endfunction

" Check the checkbox at the current cursor position
function! md#update#checkCheckbox()
  call md#checkbox#checkCheckbox(line('.'))
endfunction

" Uncheck the checkbox at the current cursor position  
function! md#update#uncheckCheckbox()
  call md#checkbox#uncheckCheckbox(line('.'))
endfunction

" Add a new footnote at the current cursor position
function! md#update#addFootnote()
  " Get the current cursor position
  let current_line = line('.')
  let current_col = col('.')
  
  " Find the next available footnote ID
  let footnote_id = md#footnotes#findNextAvailableId()
  
  " Add the footnote reference at the current position
  call md#footnotes#addFootnoteReference(current_line, current_col, footnote_id)
  
  " Add the footnote definition at the end of the file
  let def_line = md#footnotes#addFootnoteDefinition(footnote_id)
  
  " Add current position to jump list before moving
  normal! m`
  
  " Move cursor to the footnote definition, positioning after the colon and space
  call cursor(def_line, len('[^' . footnote_id . ']: ') + 1)
  
  " Enter insert mode
  startinsert
endfunction
