"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Functions for handling heading lines, mostly for handling the complexity of
" Underline headings
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Coerce lnum to an integer
function! md#line#lineAsNum(line)
  if type(a:line) ==# 0
    return a:line
  else
    return line(a:line)
  endif
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Meta function, to handle hash headings and underline headings seperately
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Check if the line is empty or contains only whitespace.
function! s:strIsEmpty(lineStr)
  return a:lineStr =~ '^\s*$'
endfunction

" Check if the line starts with a hash followed by spaces.
function! s:strIsHashHeading(lineStr)
  return a:lineStr =~ '^##*\s'
endfunction

" Check if the line is a heading underline (either == or --).
function! s:strIsHeadingUnderline(lineStr)
  return a:lineStr =~ '^[=-][=-]*$'
endfunction

" Check if the line is a list item (starts with - or * followed by space).
function! s:strIsListItem(lineStr)
  return a:lineStr =~ '^\s*[-*]\s'
endfunction

" Generic handler for functions that have different logic for hash headings
" and underline headings.
function! s:handleHeadingTypes(hashHeadingHandler, underlineHeadingHandler, default, line)
  let lineStr = getline(a:line)
  if s:strIsHashHeading(lineStr)
    return a:hashHeadingHandler(lineStr)
  endif
  if !(s:strIsEmpty(lineStr) || s:strIsListItem(lineStr))
    let nextLine = getline(md#line#lineAsNum(a:line) + 1)
    if s:strIsHeadingUnderline(nextLine)
      return a:underlineHeadingHandler(lineStr, nextLine)
    endif
  endif
  return a:default
endfunction

"""""""""""""""""""
" Get heading level
"""""""""""""""""""

" Count hash characters
function! s:countHashChars(lineStr)
  return len(matchstr(a:lineStr, '^##*\ze\s'))
endfunction

" Convert underline str to heading level
function! s:underlineType(_, nextLine)
  return a:nextLine[0] ==# '=' ? 1 : 2
endfunction

" Get the heading level of the line at line (i.e. 1 for '# foo', 2 for '## foo', etc.
" Returns 0 if the line is not a heading.
function! md#line#headingLevel(line)
  let l:HashHeadingLevelCounter = function('s:countHashChars')
  let l:UnderlineLevelCounter = function('s:underlineType')
  return s:handleHeadingTypes(l:HashHeadingLevelCounter, l:UnderlineLevelCounter, 0, a:line)
endfunction

"""""""""""""""""""""
" Get heading content
"""""""""""""""""""""

function! s:hashHeadingContent(lineStr)
  return matchstr(a:lineStr, '^##*\s\s*\zs.*')
endfunction

function! s:underlineContent(lineStr, _)
  return a:lineStr
endfunction

function! md#line#getHeadingText(line)
  let l:HashHeadingContent = function('s:hashHeadingContent')
  let l:UnderlineHeadingContent = function('s:underlineContent')
  return s:handleHeadingTypes(l:HashHeadingContent, l:UnderlineHeadingContent, 0, a:line)
endfunction

"""""""""""""""""""""
" Set heading content
"""""""""""""""""""""

function! s:repeatChar(char, num)
  let s = ''
  for i in range(1, a:num)
    let s = s . a:char
  endfor
  return s
endfunction

function! s:makeHashHeadingLine(level, text)
  return s:repeatChar('#', a:level) . ' ' . a:text
endfunction

function! s:makeUnderlineHeadingLines(level, text)
  if a:level == 1
    return [a:text, s:repeatChar('=', len(a:text))]
  endif
  if a:level == 2
    return [a:text, s:repeatChar('-', len(a:text))]
  endif
  return [s:makeHashHeadingLine(a:level, a:text)]
endfunction

" We need the extra _1, _2 args, because this is used as an UnderlineHandler which is expecting lineStr
" and nextLine
function! s:setUnderlineHeadingLines(level, text, line, _1, _2)
  let lnum = md#line#lineAsNum(a:line)
  execute lnum . 'd2'
  call append(lnum - 1, s:makeUnderlineHeadingLines(a:level, a:text))
  execute 'normal! ' . lnum . 'gg'
endfunction

" We need the extra _ arg, necause this is used as a HashHandler which is expecting lineStr
function! s:setHashHeadingLine(level, text, line, _)
  call setline(a:line, s:makeHashHeadingLine(a:level, a:text))
endfunction

function! md#line#setHeadingAtLine(line, level, text)
  " The handlers are expecting totally different arguments, so we need to build partials
  let l:HashHeadingHandler = function('s:setHashHeadingLine', [a:level, a:text, a:line])
  let l:UnderlineHeadingHandler = function('s:setUnderlineHeadingLines', [a:level, a:text, a:line])
  return s:handleHeadingTypes(l:HashHeadingHandler, l:UnderlineHeadingHandler, 0, a:line)
endfunction

"""""""""""""""""""""
" Insert heading line
"""""""""""""""""""""
function! md#line#insertHeading(lnum, level, text)
  call append(a:lnum - 1, [s:makeHashHeadingLine(a:level, a:text)])
endfunction

""""""""""""""""""""""
" Heading text objects
""""""""""""""""""""""

function! s:hashHeadingInsideObjectStartPair(line, lineStr)
  return [a:line, s:countHashChars(a:lineStr) + 2]
endfunction

function! s:underlineHeadingObjectStartPair(line, _1, _2)
  return [a:line, 1]
endfunction

function! md#line#headingInsideObjectStartPair(line)
  let l:HashHeadingInsideObjectStartPair = function('s:hashHeadingInsideObjectStartPair', [a:line])
  let l:UnderlineHeadingObjectStartPair = function('s:underlineHeadingObjectStartPair', [a:line])
  return s:handleHeadingTypes(l:HashHeadingInsideObjectStartPair, l:UnderlineHeadingObjectStartPair, 0, a:line)
endfunction

function! s:hashHeadingAroundObjectStartPair(line, _)
  return [a:line, 1]
endfunction

function! md#line#headingAroundObjectStartPair(line)
  let l:HashHeadingAroundObjectStartPair = function('s:hashHeadingAroundObjectStartPair', [a:line])
  let l:UnderlineHeadingObjectStartPair = function('s:underlineHeadingObjectStartPair', [a:line])
  return s:handleHeadingTypes(l:HashHeadingAroundObjectStartPair, l:UnderlineHeadingObjectStartPair, 0, a:line)
endfunction

function! s:hashHeadingObjectEndPair(line, lineStr)
  return [a:line, len(a:lineStr)]
endfunction

function! s:underlineHeadingInsideObjectEndPair(line, lineStr, _)
  return [a:line, len(a:lineStr)]
endfunction

function! md#line#headingInsideObjectEndPair(line)
  let l:HashHeadingObjectEndPair = function('s:hashHeadingObjectEndPair', [a:line])
  let l:UnderlineHeadingObjectEndPair = function('s:underlineHeadingInsideObjectEndPair', [a:line])
  return s:handleHeadingTypes(l:HashHeadingObjectEndPair, l:UnderlineHeadingObjectEndPair, 0, a:line)
endfunction

function! s:underlineHeadingAroundObjectEndPair(line, _, nextStr)
  return [a:line + 1, len(a:nextStr)]
endfunction

function! md#line#headingAroundObjectEndPair(line)
  let l:HashHeadingObjectEndPair = function('s:hashHeadingObjectEndPair', [a:line])
  let l:UnderlineHeadingObjectEndPair = function('s:underlineHeadingAroundObjectEndPair', [a:line])
  return s:handleHeadingTypes(l:HashHeadingObjectEndPair, l:UnderlineHeadingObjectEndPair, 0, a:line)
endfunction

" Wrap text to fit within specified width, preserving existing line breaks
" Returns a list of lines that fit within the width
function md#line#wrapText(text, width)
  let lines = []
  let text_lines = split(a:text, "\n")
  
  for line in text_lines
    " If line is empty, add it as-is
    if empty(line)
      call add(lines, '')
      continue
    endif
    
    " If line fits within width, add it as-is
    if len(line) <= a:width
      call add(lines, line)
      continue
    endif
    
    " Need to wrap the line
    let remaining = line
    while len(remaining) > a:width
      " Find the best break point (prefer spaces)
      let break_point = a:width
      
      " Look for a space before the width limit
      let space_pos = strridx(remaining[0:a:width-1], ' ')
      if space_pos > 0
        let break_point = space_pos
      endif
      
      " Extract the part that fits
      let part = remaining[0:break_point-1]
      call add(lines, part)
      
      " Continue with the remaining text, skip the space if we broke on one
      if break_point < len(remaining) && remaining[break_point] == ' '
        let remaining = remaining[break_point+1:]
      else
        let remaining = remaining[break_point:]
      endif
    endwhile
    
    " Add the final part if there's anything left
    if !empty(remaining)
      call add(lines, remaining)
    endif
  endfor
  
  return lines
endfunction
