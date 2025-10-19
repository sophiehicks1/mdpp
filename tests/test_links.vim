" Test suite for md#links module functions
" Tests the following functions:
" - md#links#findLinkAtPos
" - md#links#findInlineLinksInLine
" - md#links#findReferenceLinksInLine
" - md#links#getLinkText
" - md#links#getLinkUrl
" - md#links#getLinkTextRange
" - md#links#getLinkUrlRange
" - md#links#getLinkFullRange

" Helper function to setup main test buffer (comprehensive test case)
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('comprehensive_links.md')
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#links module...")
  call test#framework#write_info("==================================")
  
  call test#framework#run_test_function('test_twoWikiLinksOneLine', function('s:test_twoWikiLinksOneLine'))
  call test#framework#run_test_function('test_findInlineLinksInLine', function('s:test_findInlineLinksInLine'))
  call test#framework#run_test_function('test_findReferenceLinksInLine', function('s:test_findReferenceLinksInLine'))
  call test#framework#run_test_function('test_findLinkAtPos', function('s:test_findLinkAtPos'))
  call test#framework#run_test_function('test_getLinkText', function('s:test_getLinkText'))
  call test#framework#run_test_function('test_getLinkUrl', function('s:test_getLinkUrl'))
  call test#framework#run_test_function('test_getLinkTextRange', function('s:test_getLinkTextRange'))
  call test#framework#run_test_function('test_getLinkUrlRange', function('s:test_getLinkUrlRange'))
  call test#framework#run_test_function('test_getLinkFullRange', function('s:test_getLinkFullRange'))
  call test#framework#run_test_function('test_edge_cases', function('s:test_edge_cases'))
  call test#framework#run_test_function('test_multiline_links', function('s:test_multiline_links'))
  call test#framework#run_test_function('test_indented_wrapped_links', function('s:test_indented_wrapped_links'))
  
  return test#framework#report_results("md#links")
endfunction

" Test multiple wikilinks on the same line
function! s:test_twoWikiLinksOneLine()
  call test#framework#write_info("")
  call test#framework#write_info("Testing multiple wiki links on the same line...")

  call test#framework#setup_buffer_from_file('wikilinks.md')

  " Test 1: Fetch first link
  let link = md#links#findLinkAtPos([0, 1, 18, 0])
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "First link should be wiki type")
    call test#framework#assert_equal('first link', link.text, "First link text should be 'first link'")
  else
    call test#framework#assert_fail("First link not found")
  endif

  " Test 2: Fetch second link
  let link = md#links#findLinkAtPos([0, 1, 47, 0])
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "Second link should be wiki type")
    call test#framework#assert_equal('second link', link.text, "Second link text should be 'second link'")
  else
    call test#framework#assert_fail("Second link not found")
  endif

endfunction

" Test md#links#findInlineLinksInLine function
function! s:test_findInlineLinksInLine()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#findInlineLinksInLine...")
  
  call s:setup_test_buffer()
  
  " Test 1: Simple inline link on line 7
  let links = md#links#findInlineLinksInLine(7)
  call test#framework#assert_equal(1, len(links), "Should find one inline link on line 7")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Link should be inline type")
    call test#framework#assert_equal('Google', links[0].text, "Link text should be 'Google'")
    call test#framework#assert_equal('https://google.com', links[0].url, "Link URL should be correct")
  endif
  
  " Test 2: Multiple links on same line (line 11)
  let links = md#links#findInlineLinksInLine(11)
  call test#framework#assert_equal(2, len(links), "Should find two inline links on line 11")
  if len(links) >= 2
    call test#framework#assert_equal('First', links[0].text, "First link text should be 'First'")
    call test#framework#assert_equal('https://first.com', links[0].url, "First link URL should be correct")
    call test#framework#assert_equal('Second', links[1].text, "Second link text should be 'Second'")
    call test#framework#assert_equal('https://second.com', links[1].url, "Second link URL should be correct")
  endif
  
  " Test 3: Line with no inline links (reference link line)
  let links = md#links#findInlineLinksInLine(15)
  call test#framework#assert_equal(0, len(links), "Should find no inline links on reference link line")
  
  " Test 4: Line with nested brackets in text
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  let links = md#links#findInlineLinksInLine(5)
  call test#framework#assert_equal(1, len(links), "Should handle nested brackets in link text")
  if len(links) > 0
    call test#framework#assert_equal('Link with [[double]] nested brackets', links[0].text, "Should preserve nested brackets in text")
  endif
  
  " Test 5: Line with nested parentheses in URL
  let links = md#links#findInlineLinksInLine(6)
  call test#framework#assert_equal(1, len(links), "Should handle nested parentheses in URL")
  if len(links) > 0
    call test#framework#assert_equal('https://example.com/path(with)nested(parens)', links[0].url, "Should preserve nested parentheses in URL")
  endif
endfunction

" Test md#links#findReferenceLinksInLine function
function! s:test_findReferenceLinksInLine()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#findReferenceLinksInLine...")
  
  call s:setup_test_buffer()
  
  " Test 1: Simple reference link on line 15
  let links = md#links#findReferenceLinksInLine(15)
  call test#framework#assert_equal(1, len(links), "Should find one reference link on line 15")
  if len(links) > 0
    call test#framework#assert_equal('reference', links[0].type, "Link should be reference type")
    call test#framework#assert_equal('Google', links[0].text, "Link text should be 'Google'")
    call test#framework#assert_equal('google', links[0].reference, "Reference should be 'google'")
  endif
  
  " Test 2: Implicit reference link on line 16
  let links = md#links#findReferenceLinksInLine(16)
  call test#framework#assert_equal(1, len(links), "Should find one implicit reference link on line 16")
  if len(links) > 0
    call test#framework#assert_equal('GitHub', links[0].text, "Link text should be 'GitHub'")
    call test#framework#assert_equal('GitHub', links[0].reference, "Reference should be same as text for implicit reference")
  endif
  
  " Test 3: Multiple reference links on same line (line 19)
  let links = md#links#findReferenceLinksInLine(19)
  call test#framework#assert_equal(2, len(links), "Should find two reference links on line 19")
  if len(links) >= 2
    call test#framework#assert_equal('GitHub', links[0].text, "First reference link text should be 'GitHub'")
    call test#framework#assert_equal('Google', links[1].text, "Second reference link text should be 'Google'")
  endif
  
  " Test 4: Line with no reference links (inline link line)
  let links = md#links#findReferenceLinksInLine(7)
  call test#framework#assert_equal(0, len(links), "Should find no reference links on inline link line")
  
  " Test 5: Reference to undefined reference
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  let links = md#links#findReferenceLinksInLine(31)
  call test#framework#assert_equal(1, len(links), "Should find reference link even if undefined")
  if len(links) > 0
    call test#framework#assert_equal('Undefined Link', links[0].text, "Should get text correctly for undefined reference")
    call test#framework#assert_equal('nonexistent', links[0].reference, "Should get reference correctly")
    call test#framework#assert_equal('', links[0].url, "URL should be empty for undefined reference")
  endif
endfunction

" Test md#links#findLinkAtPos function
function! s:test_findLinkAtPos()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#findLinkAtPos...")
  
  call s:setup_test_buffer()
  
  " Test 1: Cursor on inline link text (line 7, column 24)
  call cursor(7, 24)  " Inside "Google"
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal('inline', link.type, "Should find inline link when cursor is on text")
  call test#framework#assert_equal('Google', link.text, "Should return correct link text")
  call test#framework#assert_equal('https://google.com', link.url, "Should return correct URL")
  
  " Test 2: Cursor on inline link URL (line 7, column 35)
  call cursor(7, 35)  " Inside URL part
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal('inline', link.type, "Should find inline link when cursor is on URL")
  call test#framework#assert_equal('Google', link.text, "Should return correct link text when cursor on URL")
  
  " Test 3: Cursor on reference link text (line 15, column 24)
  call cursor(15, 24)  " Inside "Google" of reference link
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal('reference', link.type, "Should find reference link when cursor is on text")
  call test#framework#assert_equal('Google', link.text, "Should return correct reference link text")
  call test#framework#assert_equal('google', link.reference, "Should return correct reference")
  
  " Test 4: Cursor on reference definition (line 23, column 10)
  call cursor(23, 10)  " Inside reference definition URL
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link when cursor is on definition")
  if !empty(link)
    call test#framework#assert_equal('reference', link.type, "Should find reference link when cursor is on definition")
    call test#framework#assert_equal('Google', link.text, "Should find referring link text from definition")
  endif
  
  " Test 5: Cursor not on any link (line 3, column 5)
  call cursor(3, 5)  " In regular text
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal({}, link, "Should return empty dict when cursor not on link")
  
  " Test 6: Cursor at start of link (line 7, column 22)
  call cursor(7, 21)  " At opening bracket
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link when cursor at start")
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "Should find link when cursor at start")
  endif
  
  " Test 7: Cursor at end of link (line 7, column 45)
  call cursor(7, 48)  " At closing parenthesis
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link when cursor at end")
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "Should find link when cursor at end")
  endif
endfunction

" Test md#links#getLinkText function
function! s:test_getLinkText()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkText...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get text from inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let text = md#links#getLinkText(link)
    call test#framework#assert_equal('Google', text, "Should return correct text for inline link")
  endif
  
  " Test 2: Get text from reference link
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let text = md#links#getLinkText(link)
    call test#framework#assert_equal('Google', text, "Should return correct text for reference link")
  endif
  
  " Test 3: Empty link info
  let text = md#links#getLinkText({})
  call test#framework#assert_equal('', text, "Should return empty string for empty link info")
  
  " Test 4: Link with empty text
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  call cursor(16, 5)  " Empty text link
  let links = md#links#findInlineLinksInLine(line('.'))
  call test#framework#assert_equal(1, len(links), "Should find one link with empty text")
  if len(links) > 0
    let text = md#links#getLinkText(links[0])
    call test#framework#assert_equal('', text, "Should handle empty link text")
    call test#framework#assert_equal(16, links[0].line_num, "Should return correct line number for empty text link")
  endif
endfunction

" Test md#links#getLinkUrl function
function! s:test_getLinkUrl()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkUrl...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get URL from inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let url = md#links#getLinkUrl(link)
    call test#framework#assert_equal('https://google.com', url, "Should return correct URL for inline link")
  endif
  
  " Test 2: Get URL from reference link (resolved)
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let url = md#links#getLinkUrl(link)
    call test#framework#assert_equal('https://google.com', url, "Should return resolved URL for reference link")
  endif
  
  " Test 3: Empty link info
  let url = md#links#getLinkUrl({})
  call test#framework#assert_equal('', url, "Should return empty string for empty link info")
  
  " Test 4: Reference link with no definition
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  let links = md#links#findReferenceLinksInLine(31)
  call test#framework#assert_equal(1, len(links), "Should find reference link even if undefined")
  if len(links) > 0
    let url = md#links#getLinkUrl(links[0])
    call test#framework#assert_equal('', url, "Should return empty string for undefined reference")
  endif
endfunction

" Test md#links#getLinkTextRange function
function! s:test_getLinkTextRange()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkTextRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get text range for inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let range = md#links#getLinkTextRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array")
    call test#framework#assert_equal(7, range[0], "Should return correct line number")
    call test#framework#assert_equal(7, range[2], "Should return same line for end")
    " Verify the range captures the text correctly
    let text_in_range = getline(range[0])[range[1]-1:range[3]-1]
    call test#framework#assert_equal('Google', text_in_range, "Range should capture the link text")
  endif
  
  " Test 2: Get text range for reference link
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let range = md#links#getLinkTextRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array for reference link")
    let text_in_range = getline(range[0])[range[1]-1:range[3]-1]
    call test#framework#assert_equal('Google', text_in_range, "Range should capture the reference link text")
  endif
  
  " Test 3: Empty link info
  let range = md#links#getLinkTextRange({})
  call test#framework#assert_equal([], range, "Should return empty array for empty link info")
endfunction

" Test md#links#getLinkUrlRange function
function! s:test_getLinkUrlRange()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkUrlRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get URL range for inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let range = md#links#getLinkUrlRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array for inline link")
    " Verify the range captures the URL correctly
    let url_in_range = getline(range[0])[range[1]-1:range[3]-1]
    call test#framework#assert_equal('https://google.com', url_in_range, "Range should capture the link URL")
  endif
  
  " Test 2: Get URL range for reference link (should point to definition)
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let range = md#links#getLinkUrlRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array for reference link")
    " The range should point to the definition line
    call test#framework#assert_equal(23, range[0], "Should point to definition line for reference link")
  endif
  
  " Test 3: Empty link info
  let range = md#links#getLinkUrlRange({})
  call test#framework#assert_equal([], range, "Should return empty array for empty link info")
  
  " Test 4: Reference link with no definition
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  call cursor(31, 5)  " Undefined reference
  let link = md#links#findLinkAtPos(getpos('.'))
  let range = md#links#getLinkUrlRange(link)
  call test#framework#assert_equal([], range, "Should return empty array for undefined reference")
endfunction

" Test md#links#getLinkFullRange function
function! s:test_getLinkFullRange()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkFullRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get full range for inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let range = md#links#getLinkFullRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array")
    " Verify the range captures the entire link
    let full_link = getline(range[0])[range[1]-1:range[3]-1]
    call test#framework#assert_equal('[Google](https://google.com)', full_link, "Range should capture the entire link")
  endif
  
  " Test 2: Get full range for reference link
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let range = md#links#getLinkFullRange(link)
    let full_link = getline(range[0])[range[1]-1:range[3]-1]
    call test#framework#assert_equal('[Google][google]', full_link, "Range should capture the entire reference link")
  endif
  
  " Test 3: Empty link info
  let range = md#links#getLinkFullRange({})
  call test#framework#assert_equal([], range, "Should return empty array for empty link info")
endfunction

" Test edge cases
function! s:test_edge_cases()
  call test#framework#write_info("")
  call test#framework#write_info("Testing edge cases...")
  
  " Test with buffer containing no links
  call test#framework#setup_buffer_from_file('no_links.md')
  
  " Test 1: findLinkAtPos in buffer with no links
  call cursor(1, 5)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal({}, link, "Should return empty dict when no links exist")
  
  " Test 2: findInlineLinksInLine with no links
  let links = md#links#findInlineLinksInLine(1)
  call test#framework#assert_equal(0, len(links), "Should return empty array when no inline links exist")
  
  " Test 3: findReferenceLinksInLine with no reference links
  let links = md#links#findReferenceLinksInLine(1)
  call test#framework#assert_equal(0, len(links), "Should return empty array when no reference links exist")
  
  " Test with empty buffer
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
  
  " Test 4: Functions with empty buffer
  call cursor(1, 1)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal({}, link, "Should handle empty buffer gracefully")
  
  let links = md#links#findInlineLinksInLine(1)
  call test#framework#assert_equal(0, len(links), "Should handle empty line gracefully")
  
  " Test edge cases with malformed links
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  
  " Test 5: Malformed links should not be detected
  let links = md#links#findInlineLinksInLine(10)
  call test#framework#assert_equal(0, len(links), "Should not detect malformed links (missing bracket)")
  
  let links = md#links#findInlineLinksInLine(11)
  call test#framework#assert_equal(0, len(links), "Should not detect malformed links (missing paren)")
  
  " Test 6: Links with special characters
  let links = md#links#findInlineLinksInLine(23)
  call test#framework#assert_equal(1, len(links), "Should handle unicode characters in link text")
  if len(links) > 0
    call test#framework#assert_equal('Link with émojis 🔗', links[0].text, "Should preserve unicode in link text")
  endif
  
  " Test 7: Links with query parameters and fragments
  let links = md#links#findInlineLinksInLine(24)
  call test#framework#assert_equal(1, len(links), "Should handle special characters in URL")
  if len(links) > 0
    call test#framework#assert_equal('https://example.com/path?query=value&other=true#fragment', links[0].url, "Should preserve special characters in URL")
  endif
endfunction

" Test multi-line link support
function! s:test_multiline_links()
  call test#framework#write_info("")
  call test#framework#write_info("Testing multi-line link support...")
  
  call test#framework#setup_buffer_from_file('multiline_links.md')
  
  " Test 1: Wiki link that wraps across lines (line 9-10)
  let links = md#links#findWikiLinksInLine(9)
  call test#framework#assert_equal(1, len(links), "Should find wiki link starting on line 9")
  if len(links) > 0
    call test#framework#assert_equal('wiki', links[0].type, "Should be wiki link type")
    call test#framework#assert_equal(9, links[0].line_num, "Should report correct starting line")
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
  endif
  
  " Test 2: Same wiki link found from continuation line (line 10)
  let links = md#links#findWikiLinksInLine(10)
  call test#framework#assert_equal(1, len(links), "Should find wiki link from continuation line 10")
  if len(links) > 0
    call test#framework#assert_equal(9, links[0].line_num, "Should report original starting line")
  endif
  
  " Test 3: Inline link with wrapped text (line 19-20)
  let links = md#links#findInlineLinksInLine(19)
  call test#framework#assert_equal(1, len(links), "Should find inline link with wrapped text on line 19")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Should be inline link type")
    call test#framework#assert_equal(19, links[0].line_num, "Should report correct starting line")
    call test#framework#assert_equal('http://example.com', links[0].url, "Should extract URL correctly")
  endif
  
  " Test 4: Inline link found from text continuation line
  let links = md#links#findInlineLinksInLine(20)
  call test#framework#assert_equal(1, len(links), "Should find inline link from text continuation line")
  if len(links) > 0
    call test#framework#assert_equal(19, links[0].line_num, "Should report original starting line")
  endif
  
  " Test 5: Reference link with wrapped text (line 36-37)
  let links = md#links#findReferenceLinksInLine(36)
  call test#framework#assert_equal(1, len(links), "Should find reference link with wrapped text")
  if len(links) > 0
    call test#framework#assert_equal('reference', links[0].type, "Should be reference link type")
    call test#framework#assert_equal('ref2', links[0].reference, "Should extract reference correctly")
    call test#framework#assert_equal('http://example.com/multiline', links[0].url, "Should resolve reference URL")
  endif
  
  " Test 6: Reference link found from continuation line
  let links = md#links#findReferenceLinksInLine(37)
  call test#framework#assert_equal(1, len(links), "Should find reference link from continuation line")
  
  " Test 7: Cursor in middle of wiki link text on first line
  call cursor(9, 75)  " In the wrapped wiki link
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor on first line of wrapped link")
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "Should find wiki link type")
  endif
  
  " Test 8: Cursor on continuation line of wiki link
  call cursor(10, 5)  " In "with 5 words" part
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor on continuation line")
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "Should find wiki link type from continuation")
  endif
  
  " Test 9: Cursor in middle of inline link text spanning lines
  call cursor(19, 50)  " In wrapped inline link text
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find inline link at cursor")
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "Should find inline link type")
  endif
  
  " Test 10: Cursor on inline link continuation line
  call cursor(20, 10)  " In continuation of inline link text
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find inline link from text continuation line")
  
  " Test 11: Multiple wrapped links on adjacent lines (line 56-58)
  let links = md#links#findInlineLinksInLine(56)
  call test#framework#assert_equal(1, len(links), "Should find first wrapped link")
  
  let links = md#links#findInlineLinksInLine(57)
  call test#framework#assert_equal(2, len(links), "Should find both links (end of first, start of second)")
  
  " Test 12: Ensure we don't pick up links from unrelated lines
  " Line 7 has a simple wiki link
  let links = md#links#findWikiLinksInLine(7)
  call test#framework#assert_equal(1, len(links), "Should only find the single-line wiki link on line 7")
  if len(links) > 0
    call test#framework#assert_equal('simple wiki', links[0].text, "Should be the simple wiki link")
  endif
  
  " Test 13: Text object selection for wrapped wiki link
  call cursor(9, 70)
  let link = md#links#findLinkAtPos(getpos('.'))
  if !empty(link)
    let range = md#links#getLinkTextRange(link)
    call test#framework#assert_equal(4, len(range), "Should return valid range for wrapped link text")
    call test#framework#assert_equal(link.line_num, range[0], "Range should start on correct line")
  endif
  
  " Test 14: Full range selection for wrapped inline link
  call cursor(19, 40)
  let link = md#links#findLinkAtPos(getpos('.'))
  if !empty(link)
    let range = md#links#getLinkFullRange(link)
    call test#framework#assert_equal(4, len(range), "Should return valid full range for wrapped link")
  endif
endfunction

" Test indented wrapped links
function! s:test_indented_wrapped_links()
  call test#framework#write_info("")
  call test#framework#write_info("Testing indented wrapped links...")
  
  call test#framework#setup_buffer_from_file('indented_wrapped_links.md')
  
  " Test 1: Wiki link in nested list item (line 8-9)
  " Line 8: "  * This is a modestly long nested list item that ends with a [[relatively short"
  " Line 9: "    link]]"
  " The link text should be "relatively short\nlink" but when joined should become
  " "relatively short link" (single space, not multiple spaces from indentation)
  let links = md#links#findWikiLinksInLine(8)
  call test#framework#assert_equal(1, len(links), "Should find wiki link on line 8")
  if len(links) > 0
    call test#framework#assert_equal('wiki', links[0].type, "Should be wiki link type")
    " The link text should NOT include extra spaces from the indentation
    call test#framework#assert_equal('relatively short link', links[0].text, 
          \ "Link text should not include indentation spaces")
    call test#framework#assert_equal('relatively short link', links[0].url, 
          \ "Link URL should match text without indentation spaces")
  endif
  
  " Test 2: Same link found from continuation line
  let links = md#links#findWikiLinksInLine(9)
  call test#framework#assert_equal(1, len(links), "Should find same link from continuation line")
  if len(links) > 0
    call test#framework#assert_equal('relatively short link', links[0].text, 
          \ "Link text should be consistent when found from continuation line")
  endif
  
  " Test 3: Inline link in nested list (line 10-11)
  let links = md#links#findInlineLinksInLine(10)
  call test#framework#assert_equal(1, len(links), "Should find inline link on line 10")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Should be inline link type")
    call test#framework#assert_equal('file link text that wraps', links[0].text,
          \ "Inline link text should not include indentation")
    call test#framework#assert_equal('./file.md', links[0].url,
          \ "Inline link URL should be correct")
  endif
  
  " Test 4: Deeply nested wiki link (line 17-18)
  let links = md#links#findWikiLinksInLine(17)
  call test#framework#assert_equal(1, len(links), "Should find deeply nested wiki link")
  if len(links) > 0
    call test#framework#assert_equal('deeply nested wrapped link', links[0].text,
          \ "Deeply nested link text should not include indentation")
  endif
  
  " Test 5: Deeply nested inline link (line 19-20)
  let links = md#links#findInlineLinksInLine(19)
  call test#framework#assert_equal(1, len(links), "Should find deeply nested inline link")
  if len(links) > 0
    call test#framework#assert_equal('inline link that spans lines', links[0].text,
          \ "Deeply nested inline link text should not include indentation")
  endif
  
  " Test 6: Wiki link in blockquote (line 24-25)
  let links = md#links#findWikiLinksInLine(24)
  call test#framework#assert_equal(1, len(links), "Should find wiki link in blockquote")
  if len(links) > 0
    call test#framework#assert_equal('wiki link that wraps', links[0].text,
          \ "Blockquote wiki link should not include continuation markers")
  endif
  
  " Test 7: Inline link in blockquote (line 27-28)
  let links = md#links#findInlineLinksInLine(27)
  call test#framework#assert_equal(1, len(links), "Should find inline link in blockquote")
  if len(links) > 0
    call test#framework#assert_equal('inline link that wraps', links[0].text,
          \ "Blockquote inline link should not include continuation markers")
  endif
  
  " Test 8: Reference link in list (line 40-41)
  let links = md#links#findReferenceLinksInLine(40)
  call test#framework#assert_equal(1, len(links), "Should find reference link in list")
  if len(links) > 0
    call test#framework#assert_equal('reference', links[0].type, "Should be reference link")
    call test#framework#assert_equal('reference link text', links[0].text,
          \ "Reference link text should not include indentation")
  endif
  
  " Test 9: Reference link in nested list (line 42-43)
  let links = md#links#findReferenceLinksInLine(42)
  call test#framework#assert_equal(1, len(links), "Should find reference link in nested list")
  if len(links) > 0
    call test#framework#assert_equal('another ref link', links[0].text,
          \ "Nested reference link text should not include indentation")
  endif
  
  " Test 10: Test cursor position in middle of wrapped link (critical for vim-open)
  " Position cursor in the middle of "relatively short" on line 8
  call cursor(8, 75)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position on first line")
  if !empty(link)
    call test#framework#assert_equal('relatively short link', link.text,
          \ "Should extract clean link text when cursor on first line")
  endif
  
  " Test 11: Test cursor position on continuation line with indentation
  " Position cursor on "link" text on line 9
  call cursor(9, 8)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position on continuation line")
  if !empty(link)
    call test#framework#assert_equal('relatively short link', link.text,
          \ "Should extract clean link text when cursor on continuation line")
  endif
endfunction

" Run all tests
" Initialize test framework with results file
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('links.txt')
  call s:run_tests()
endif
