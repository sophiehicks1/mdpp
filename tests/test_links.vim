" Helper function to setup main test buffer (comprehensive test case)
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('comprehensive_links.md')
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#links module...")
  call test#framework#write_info("==================================")
  
  call test#framework#run_test_function('test_multipleLinksOnLine', function('s:test_multipleLinksOnLine'))
  call test#framework#run_test_function('test_findInlineLinksInLine', function('s:test_findInlineLinksInLine'))
  call test#framework#run_test_function('test_findReferenceLinksInLine', function('s:test_findReferenceLinksInLine'))
  call test#framework#run_test_function('test_findLinkAtPos', function('s:test_findLinkAtPos'))
  call test#framework#run_test_function('test_getLinkText', function('s:test_getLinkText'))
  call test#framework#run_test_function('test_getLinkTarget', function('s:test_getLinkTarget'))
  call test#framework#run_test_function('test_getLinkTextRange', function('s:test_getLinkTextRange'))
  call test#framework#run_test_function('test_getLinkTargetRange', function('s:test_getLinkTargetRange'))
  call test#framework#run_test_function('test_getLinkFullRange', function('s:test_getLinkFullRange'))
  call test#framework#run_test_function('test_edge_cases', function('s:test_edge_cases'))
  call test#framework#run_test_function('test_multiline_links', function('s:test_multiline_links'))
  call test#framework#run_test_function('test_indented_wrapped_links', function('s:test_indented_wrapped_links'))
  
  return test#framework#report_results("md#links")
endfunction

" Test multiple links on the same line
function! s:test_multipleLinksOnLine()
  call test#framework#write_info("")
  call test#framework#write_info("Testing multiple wiki links on the same line...")

  call test#framework#setup_buffer_from_file('multi_links_on_line.md')

  " Test 1: Fetch first wiki link
  let link = md#links#findLinkAtPos([0, 3, 1, 0])
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "First wiki link should be wiki type")
    call test#framework#assert_equal('very very long first link', link.text, "First wiki link text should be 'very very long first link'")
  else
    call test#framework#assert_true(v:false, "First wiki link not found")
  endif

  " Test 2: Fetch second wiki link
  let link = md#links#findLinkAtPos([0, 3, 20, 0])
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "Second wiki link should be wiki type")
    call test#framework#assert_equal('second link', link.text, "Second wiki link text should be 'second link'")
  else
    call test#framework#assert_true(v:false, "Second wiki link not found")
  endif

  " Test 3: Fetch third wiki link
  let link = md#links#findLinkAtPos([0, 3, 50, 0])
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "Third wiki link should be wiki type")
    call test#framework#assert_equal('third link', link.text, "Third wiki link text should be 'third link'")
  else
    call test#framework#assert_true(v:false, "Third wiki link not found")
  endif

  " Test 4: Fetch fourth wiki link
  let link = md#links#findLinkAtPos([0, 3, 78, 0])
  if !empty(link)
    call test#framework#assert_equal('wiki', link.type, "Fourth wiki link should be wiki type")
    call test#framework#assert_equal('very very long fourth link', link.text, "Fourth wiki link text should be 'very very long fourth link'")
  else
    call test#framework#assert_true(v:false, "Fourth wiki link not found")
  endif

  " Test 5: Fetch first inline link
  let link = md#links#findLinkAtPos([0, 8, 1, 0])
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "First inline link should be inline type")
    call test#framework#assert_equal('very very long first link', link.text, "First inline link text should be 'very very long first link'")
  else
    call test#framework#assert_true(v:false, "First inline link not found")
  endif

  " Test 6: Fetch second inline link
  let link = md#links#findLinkAtPos([0, 8, 28, 0])
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "Second link should be inline type")
    call test#framework#assert_equal('second link', link.text, "Second inline link text should be 'second link'")
  else
    call test#framework#assert_true(v:false, "Second inline link not found")
  endif

  " Test 7: Fetch third inline link
  let link = md#links#findLinkAtPos([0, 8, 57, 0])
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "Third link should be inline type")
    call test#framework#assert_equal('third link', link.text, "Third inline link text should be 'third link'")
  else
    call test#framework#assert_true(v:false, "Third inline link not found")
  endif

  " Test 8: Fetch fourth inline link
  let link = md#links#findLinkAtPos([0, 8, 81, 0])
  if !empty(link)
    call test#framework#assert_equal('inline', link.type, "Fourth link should be inline type")
    call test#framework#assert_equal('very very long fourth link', link.text, "Fourth inline link text should be 'very very long fourth link'")
  else
    call test#framework#assert_true(v:false, "Fourth inline link not found")
  endif

  " Test 9: Fetch first reference link
  let link = md#links#findLinkAtPos([0, 13, 1, 0])
  if !empty(link)
    call test#framework#assert_equal('reference', link.type, "First reference link should be reference type")
    call test#framework#assert_equal('very very long first link', link.text, "First reference link text should be 'very very long first link'")
  else
    call test#framework#assert_true(v:false, "First reference link not found")
  endif

  " Test 10: Fetch second reference link
  let link = md#links#findLinkAtPos([0, 13, 20, 0])
  if !empty(link)
    call test#framework#assert_equal('reference', link.type, "Second link should be reference type")
    call test#framework#assert_equal('second link', link.text, "Second reference link text should be 'second link'")
  else
    call test#framework#assert_true(v:false, "Second reference link not found")
  endif

  " Test 11: Fetch third reference link
  let link = md#links#findLinkAtPos([0, 13, 51, 0])
  if !empty(link)
    call test#framework#assert_equal('reference', link.type, "Third link should be reference type")
    call test#framework#assert_equal('third link', link.text, "Third reference link text should be 'third link'")
  else
    call test#framework#assert_true(v:false, "Third reference link not found")
  endif

  " Test 12: Fetch fourth reference link
  let link = md#links#findLinkAtPos([0, 13, 77, 0])
  if !empty(link)
    call test#framework#assert_equal('reference', link.type, "Fourth link should be reference type")
    call test#framework#assert_equal('very very long fourth link', link.text, "Fourth reference link text should be 'very very long fourth link'")
  else
    call test#framework#assert_true(v:false, "Fourth reference link not found")
  endif
endfunction

" Test md#links#testfns#findInlineLinksInLine function
function! s:test_findInlineLinksInLine()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#testfns#findInlineLinksInLine...")
  
  call s:setup_test_buffer()
  
  " Test 1: Simple inline link on line 7
  let links = md#links#testfns#findInlineLinksInLine(7)
  call test#framework#assert_equal(1, len(links), "Should find one inline link on line 7")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Link should be inline type")
    call test#framework#assert_equal('Google', links[0].text, "Link text should be 'Google'")
    call test#framework#assert_equal('https://google.com', links[0].target, "Link target should be correct")
  endif
  
  " Test 2: Multiple links on same line (line 11)
  let links = md#links#testfns#findInlineLinksInLine(11)
  call test#framework#assert_equal(2, len(links), "Should find two inline links on line 11")
  if len(links) >= 2
    call test#framework#assert_equal('First', links[0].text, "First link text should be 'First'")
    call test#framework#assert_equal('https://first.com', links[0].target, "First link target should be correct")
    call test#framework#assert_equal('Second', links[1].text, "Second link text should be 'Second'")
    call test#framework#assert_equal('https://second.com', links[1].target, "Second link target should be correct")
  endif
  
  " Test 3: Line with no inline links (reference link line)
  let links = md#links#testfns#findInlineLinksInLine(15)
  call test#framework#assert_equal(0, len(links), "Should find no inline links on reference link line")
  
  " Test 4: Line with nested brackets in text
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  let links = md#links#testfns#findInlineLinksInLine(5)
  call test#framework#assert_equal(1, len(links), "Should handle nested brackets in link text")
  if len(links) > 0
    call test#framework#assert_equal('Link with [[double]] nested brackets', links[0].text, "Should preserve nested brackets in text")
  endif
  
  " Test 5: Line with nested parentheses in target
  let links = md#links#testfns#findInlineLinksInLine(6)
  call test#framework#assert_equal(1, len(links), "Should handle nested parentheses in target")
  if len(links) > 0
    call test#framework#assert_equal('https://example.com/path(with)nested(parens)', links[0].target, "Should preserve nested parentheses in target")
  endif
endfunction

" Test md#links#testfns#findReferenceLinksInLine function
function! s:test_findReferenceLinksInLine()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#testfns#findReferenceLinksInLine...")
  
  call s:setup_test_buffer()
  
  " Test 1: Simple reference link on line 15
  let links = md#links#testfns#findReferenceLinksInLine(15)
  call test#framework#assert_equal(1, len(links), "Should find one reference link on line 15")
  if len(links) > 0
    call test#framework#assert_equal('reference', links[0].type, "Link should be reference type")
    call test#framework#assert_equal('Google', links[0].text, "Link text should be 'Google'")
    call test#framework#assert_equal('google', links[0].reference, "Reference should be 'google'")
  endif
  
  " Test 2: Implicit reference link on line 16
  let links = md#links#testfns#findReferenceLinksInLine(16)
  call test#framework#assert_equal(1, len(links), "Should find one implicit reference link on line 16")
  if len(links) > 0
    call test#framework#assert_equal('GitHub', links[0].text, "Link text should be 'GitHub'")
    call test#framework#assert_equal('GitHub', links[0].reference, "Reference should be same as text for implicit reference")
  endif
  
  " Test 3: Multiple reference links on same line (line 19)
  let links = md#links#testfns#findReferenceLinksInLine(19)
  call test#framework#assert_equal(2, len(links), "Should find two reference links on line 19")
  if len(links) >= 2
    call test#framework#assert_equal('GitHub', links[0].text, "First reference link text should be 'GitHub'")
    call test#framework#assert_equal('Google', links[1].text, "Second reference link text should be 'Google'")
  endif
  
  " Test 4: Line with no reference links (inline link line)
  let links = md#links#testfns#findReferenceLinksInLine(7)
  call test#framework#assert_equal(0, len(links), "Should find no reference links on inline link line")
  
  " Test 5: Reference to undefined reference
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  let links = md#links#testfns#findReferenceLinksInLine(31)
  call test#framework#assert_equal(1, len(links), "Should find reference link even if undefined")
  if len(links) > 0
    call test#framework#assert_equal('Undefined Link', links[0].text, "Should get text correctly for undefined reference")
    call test#framework#assert_equal('nonexistent', links[0].reference, "Should get reference correctly")
    call test#framework#assert_equal('', links[0].target, "target should be empty for undefined reference")
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
  call test#framework#assert_equal('https://google.com', link.target, "Should return correct target")
  
  " Test 2: Cursor on inline link target (line 7, column 35)
  call cursor(7, 35)  " Inside target part
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal('inline', link.type, "Should find inline link when cursor is on target")
  call test#framework#assert_equal('Google', link.text, "Should return correct link text when cursor on target")
  
  " Test 3: Cursor on reference link text (line 15, column 24)
  call cursor(15, 24)  " Inside "Google" of reference link
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_equal('reference', link.type, "Should find reference link when cursor is on text")
  call test#framework#assert_equal('Google', link.text, "Should return correct reference link text")
  call test#framework#assert_equal('google', link.reference, "Should return correct reference")
  
  " Test 4: Cursor on reference definition (line 23, column 10)
  call cursor(23, 10)  " Inside reference definition target
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
  let links = md#links#testfns#findInlineLinksInLine(line('.'))
  call test#framework#assert_equal(1, len(links), "Should find one link with empty text")
  if len(links) > 0
    let text = md#links#getLinkText(links[0])
    call test#framework#assert_equal('', text, "Should handle empty link text")
    call test#framework#assert_equal(16, links[0].line_num, "Should return correct line number for empty text link")
  endif
endfunction

" Test md#links#getLinkTarget function
function! s:test_getLinkTarget()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkTarget...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get target from inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let target = md#links#getLinkTarget(link)
    call test#framework#assert_equal('https://google.com', target, "Should return correct target for inline link")
  endif
  
  " Test 2: Get target from reference link (resolved)
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let target = md#links#getLinkTarget(link)
    call test#framework#assert_equal('https://google.com', target, "Should return resolved target for reference link")
  endif
  
  " Test 3: Empty link info
  let target = md#links#getLinkTarget({})
  call test#framework#assert_equal('', target, "Should return empty string for empty link info")
  
  " Test 4: Reference link with no definition
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  let links = md#links#testfns#findReferenceLinksInLine(31)
  call test#framework#assert_equal(1, len(links), "Should find reference link even if undefined")
  if len(links) > 0
    let target = md#links#getLinkTarget(links[0])
    call test#framework#assert_equal('', target, "Should return empty string for undefined reference")
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

" Test md#links#getLinkTargetRange function
function! s:test_getLinkTargetRange()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#links#getLinkTargetRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get target range for inline link
  call cursor(7, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find link at cursor position")
  if !empty(link)
    let range = md#links#getLinkTargetRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array for inline link")
    " Verify the range captures the target correctly
    let target_in_range = getline(range[0])[range[1]-1:range[3]-1]
    call test#framework#assert_equal('https://google.com', target_in_range, "Range should capture the link target")
  endif
  
  " Test 2: Get target range for reference link (should point to definition)
  call cursor(15, 24)
  let link = md#links#findLinkAtPos(getpos('.'))
  call test#framework#assert_not_empty(link, "Should find reference link at cursor position")
  if !empty(link)
    let range = md#links#getLinkTargetRange(link)
    call test#framework#assert_equal(4, len(range), "Should return 4-element range array for reference link")
    " The range should point to the definition line
    call test#framework#assert_equal(23, range[0], "Should point to definition line for reference link")
  endif
  
  " Test 3: Empty link info
  let range = md#links#getLinkTargetRange({})
  call test#framework#assert_equal([], range, "Should return empty array for empty link info")
  
  " Test 4: Reference link with no definition
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  call cursor(31, 5)  " Undefined reference
  let link = md#links#findLinkAtPos(getpos('.'))
  let range = md#links#getLinkTargetRange(link)
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
  let links = md#links#testfns#findInlineLinksInLine(1)
  call test#framework#assert_equal(0, len(links), "Should return empty array when no inline links exist")
  
  " Test 3: findReferenceLinksInLine with no reference links
  let links = md#links#testfns#findReferenceLinksInLine(1)
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
  
  let links = md#links#testfns#findInlineLinksInLine(1)
  call test#framework#assert_equal(0, len(links), "Should handle empty line gracefully")
  
  " Test edge cases with malformed links
  call test#framework#setup_buffer_from_file('links_edge_cases.md')
  
  " Test 5: Malformed links should not be detected
  let links = md#links#testfns#findInlineLinksInLine(10)
  call test#framework#assert_equal(0, len(links), "Should not detect malformed links (missing bracket)")
  
  let links = md#links#testfns#findInlineLinksInLine(11)
  call test#framework#assert_equal(0, len(links), "Should not detect malformed links (missing paren)")
  
  " Test 6: Links with special characters
  let links = md#links#testfns#findInlineLinksInLine(23)
  call test#framework#assert_equal(1, len(links), "Should handle unicode characters in link text")
  if len(links) > 0
    call test#framework#assert_equal('Link with émojis 🔗', links[0].text, "Should preserve unicode in link text")
  endif
  
  " Test 7: Links with query parameters and fragments
  let links = md#links#testfns#findInlineLinksInLine(24)
  call test#framework#assert_equal(1, len(links), "Should handle special characters in target")
  if len(links) > 0
    call test#framework#assert_equal('https://example.com/path?query=value&other=true#fragment', links[0].target, "Should preserve special characters in target")
  endif
endfunction

" Test multi-line link support
function! s:test_multiline_links()
  call test#framework#write_info("")
  call test#framework#write_info("Testing multi-line link support...")
  
  call test#framework#setup_buffer_from_file('multiline_links.md')
  
  " Test 1: Wiki link that wraps across lines (line 9-10)
  let links = md#links#testfns#findWikiLinksInLine(9)
  call test#framework#assert_equal(1, len(links), "Should find wiki link starting on line 9")
  if len(links) > 0
    call test#framework#assert_equal('wiki', links[0].type, "Should be wiki link type")
    call test#framework#assert_equal(9, links[0].line_num, "Should report correct starting line")
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
    " The text should be correct
    call test#framework#assert_equal('modest link with 5 words', links[0].text, "Should have correct link text")
  endif
  
  " Test 2: Same wiki link found from continuation line (line 10)
  let links = md#links#testfns#findWikiLinksInLine(10)
  call test#framework#assert_equal(1, len(links), "Should find wiki link from continuation line 10")
  if len(links) > 0
    call test#framework#assert_equal(9, links[0].line_num, "Should report original starting line")
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
    " The text should be correct
    call test#framework#assert_equal('modest link with 5 words', links[0].text, "Should have correct link text")
  endif
  
  " Test 3: Inline link with wrapped text (line 19-20)
  let links = md#links#testfns#findInlineLinksInLine(19)
  call test#framework#assert_equal(1, len(links), "Should find inline link with wrapped text on line 19")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Should be inline link type")
    call test#framework#assert_equal(19, links[0].line_num, "Should report correct starting line")
    call test#framework#assert_equal('http://example.com', links[0].target, "Should extract target correctly")
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
    " The text should be correct
    call test#framework#assert_equal('this is a link that spans multiple lines', links[0].text, "Should have correct link text")
  endif
  
  " Test 4: Inline link found from text continuation line
  let links = md#links#testfns#findInlineLinksInLine(20)
  call test#framework#assert_equal(1, len(links), "Should find inline link from text continuation line")
  if len(links) > 0
    call test#framework#assert_equal(19, links[0].line_num, "Should report original starting line")
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
    " The text should be correct
    call test#framework#assert_equal('this is a link that spans multiple lines', links[0].text, "Should have correct link text")
  endif
  
  " Test 5: Reference link with wrapped text (line 36-37)
  let links = md#links#testfns#findReferenceLinksInLine(36)
  call test#framework#assert_equal(1, len(links), "Should find reference link with wrapped text")
  if len(links) > 0
    call test#framework#assert_equal('reference', links[0].type, "Should be reference link type")
    call test#framework#assert_equal('ref2', links[0].reference, "Should extract reference correctly")
    call test#framework#assert_equal('http://example.com/multiline', links[0].target, "Should resolve reference target")
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
    " The text should be correct
    call test#framework#assert_equal('this reference text spans multiple lines', links[0].text, "Should have correct link text")
  endif
  
  " Test 6: Reference link found from continuation line
  let links = md#links#testfns#findReferenceLinksInLine(37)
  call test#framework#assert_equal(1, len(links), "Should find reference link from continuation line")
  if len(links) > 0
    " The text will be concatenated without newlines
    call test#framework#assert_true(len(links[0].text) > 0, "Should have link text")
    " The text should be correct
    call test#framework#assert_equal('this reference text spans multiple lines', links[0].text, "Should have correct link text")
  endif
  
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
  let links = md#links#testfns#findInlineLinksInLine(56)
  call test#framework#assert_equal(1, len(links), "Should find first wrapped link")
  
  let links = md#links#testfns#findInlineLinksInLine(57)
  call test#framework#assert_equal(2, len(links), "Should find both links (end of first, start of second)")
  
  " Test 12: Ensure we don't pick up links from unrelated lines
  " Line 7 has a simple wiki link
  let links = md#links#testfns#findWikiLinksInLine(7)
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

function! s:assert_link_position(link, key, expected, descriptor)
  call test#framework#assert_true(has_key(a:link, a:key), a:descriptor . " should have '" . a:key . "'")
  if has_key(a:link, a:key)
    let actual = a:link[a:key]
    call test#framework#assert_equal(a:expected, actual, a:descriptor . " " . a:key 
          \ . " should be " . string(a:expected) . ", but was " . string(actual))
  endif
endfunction

" This is just for use in test_indented_wrapped_links
" start_pos is [line, col] for start of full link
" end_pos is [line, col] for end of full link
" desc is the descriptive name which will show up in assertion failure
" messages
function! s:assert_fulllink_positions(link, start_pos, end_pos, desc)
  call s:assert_link_position(a:link, 'full_start_line', a:start_pos[0], a:desc)
  call s:assert_link_position(a:link, 'full_start_col', a:start_pos[1], a:desc)
  call s:assert_link_position(a:link, 'full_end_line', a:end_pos[0], a:desc)
  call s:assert_link_position(a:link, 'full_end_col', a:end_pos[1], a:desc)
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
  let links = md#links#testfns#findWikiLinksInLine(8)
  call test#framework#assert_equal(1, len(links), "Should find wiki link on line 8")
  if len(links) > 0
    call test#framework#assert_equal('wiki', links[0].type, "Should be wiki link type")
    " The link text should NOT include extra spaces from the indentation
    call test#framework#assert_equal('relatively short link', links[0].text, 
          \ "Link text should not include indentation spaces")
    call test#framework#assert_equal('relatively short link', links[0].target, 
          \ "Link target should match text without indentation spaces")
    call s:assert_fulllink_positions(links[0], [8, 63], [9, 10], 'First')
  endif
  
  " Test 2: Same link found from continuation line
  let links = md#links#testfns#findWikiLinksInLine(9)
  call test#framework#assert_equal(1, len(links), "Should find same link from continuation line")
  if len(links) > 0
    call test#framework#assert_equal('relatively short link', links[0].text, 
          \ "Link text should be consistent when found from continuation line")
    call s:assert_fulllink_positions(links[0], [8, 63], [9, 10], 'First (from second line)')
  endif
  
  " Test 3: Inline link in nested list (line 10-11)
  let links = md#links#testfns#findInlineLinksInLine(10)
  call test#framework#assert_equal(1, len(links), "Should find inline link on line 10")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Should be inline link type")
    call test#framework#assert_equal('file link text that wraps', links[0].text,
          \ "Inline link text should not include indentation")
    call test#framework#assert_equal('./file.md', links[0].target,
          \ "Inline link target should be correct")
    call s:assert_fulllink_positions(links[0], [10, 40], [11, 21], 'Second')
  endif

  " Test 3b: same link from continuation line
  let links = md#links#testfns#findInlineLinksInLine(11)
  call test#framework#assert_equal(1, len(links), "Should find inline link on line 11")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Should be inline link type")
    call test#framework#assert_equal('file link text that wraps', links[0].text,
          \ "Inline link text should not include indentation")
    call test#framework#assert_equal('./file.md', links[0].target,
          \ "Inline link target should be correct")
    call s:assert_fulllink_positions(links[0], [10, 40], [11, 21], 'Second (from second line)')
  endif
  
  " Test 4: Deeply nested wiki link (line 17-18)
  let links = md#links#testfns#findWikiLinksInLine(17)
  call test#framework#assert_equal(1, len(links), "Should find deeply nested wiki link")
  if len(links) > 0
    call test#framework#assert_equal('deeply nested wrapped link', links[0].text,
          \ "Deeply nested link text should not include indentation")
    call s:assert_fulllink_positions(links[0], [17, 22], [18, 20], 'Third')
  endif
  
  " Test 5: Deeply nested inline link (line 19-20)
  let links = md#links#testfns#findInlineLinksInLine(19)
  call test#framework#assert_equal(1, len(links), "Should find deeply nested inline link")
  if len(links) > 0
    call test#framework#assert_equal('inline link that spans lines', links[0].text,
          \ "Deeply nested inline link text should not include indentation")
    call s:assert_fulllink_positions(links[0], [19, 30], [20, 38], 'Fourth')
  endif
  
  " Test 6: Wiki link in blockquote (line 24-25)
  let links = md#links#testfns#findWikiLinksInLine(24)
  call test#framework#assert_equal(1, len(links), "Should find wiki link in blockquote")
  if len(links) > 0
    call test#framework#assert_equal('wiki link that wraps', links[0].text,
          \ "Blockquote wiki link should not include continuation markers")
    call s:assert_fulllink_positions(links[0], [24, 26], [25, 14], 'Fifth')
  endif
  
  " Test 7: Inline link in blockquote (line 27-28)
  let links = md#links#testfns#findInlineLinksInLine(27)
  call test#framework#assert_equal(1, len(links), "Should find inline link in blockquote")
  if len(links) > 0
    call test#framework#assert_equal('inline link that wraps', links[0].text,
          \ "Blockquote inline link should not include continuation markers")
    call s:assert_fulllink_positions(links[0], [27, 25], [28, 31], 'Sixth')
  endif
  
  " Test 8: Reference link in list (line 40-41)
  let links = md#links#testfns#findReferenceLinksInLine(40)
  call test#framework#assert_equal(1, len(links), "Should find reference link in list")
  if len(links) > 0
    call test#framework#assert_equal('reference', links[0].type, "Should be reference link")
    call test#framework#assert_equal('reference link text', links[0].text,
          \ "Reference link text should not include indentation")
    call s:assert_fulllink_positions(links[0], [40, 13], [41, 13], 'Seventh')
  endif
  
  " Test 9: Reference link in nested list (line 42-43)
  let links = md#links#testfns#findReferenceLinksInLine(42)
  call test#framework#assert_equal(1, len(links), "Should find reference link in nested list")
  if len(links) > 0
    call test#framework#assert_equal('another ref link', links[0].text,
          \ "Nested reference link text should not include indentation")
    call s:assert_fulllink_positions(links[0], [42, 17], [43, 15], 'Seventh')
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

  " Test 12: Non indented wiki link (lines 50-51)
  let links = md#links#testfns#findWikiLinksInLine(50)
  call test#framework#assert_equal(1, len(links), "Should find wiki link on line 50")
  if len(links) > 0
    let link = links[0]
    call test#framework#assert_equal('spans two lines', link.text, "Should correctly concatenate wiki link text across lines")
    call s:assert_fulllink_positions(link, [50, 75], [51, 11], 'Eighth')
  endif

  " Test 12b: Same link from next line
  let links = md#links#testfns#findWikiLinksInLine(51)
  call test#framework#assert_equal(1, len(links), "Should find wiki link on line 51")
  if len(links) > 0
    let link = links[0]
    call test#framework#assert_equal('spans two lines', link.text, "Should correctly concatenate wiki link text across lines from second line")
    call s:assert_fulllink_positions(link, [50, 75], [51, 11], 'Eighth (from second line)')
  endif

  " Test 13: Non indented inline link (lines 53-54)
  let links = md#links#testfns#findInlineLinksInLine(53)
  call test#framework#assert_equal(1, len(links), "Should find inline link on line 53")
  if len(links) > 0
    let link = links[0]
    call test#framework#assert_equal('an inline link', link.text, "Should correctly concatenate inline link text across lines")
    call s:assert_fulllink_positions(link, [53, 77], [54, 32], 'Ninth')
  endif

  " Test 13b: Same link from next line
  let links = md#links#testfns#findInlineLinksInLine(54)
  call test#framework#assert_equal(1, len(links), "Should find inline link on line 54")
  if len(links) > 0
    let link = links[0]
    call test#framework#assert_equal('an inline link', link.text, "Should correctly concatenate inline link text across lines from second line")
    call s:assert_fulllink_positions(link, [53, 77], [54, 32], 'Ninth (from second line)')
  endif

  " Test 14: Non indented inline link (lines 56-57)
  let links = md#links#testfns#findReferenceLinksInLine(56)
  call test#framework#assert_equal(1, len(links), "Should find reference link on line 56")
  if len(links) > 0
    let link = links[0]
    call test#framework#assert_equal('a reference link', link.text, "Should correctly concatenate reference link text across lines")
    call s:assert_fulllink_positions(link, [56, 75], [57, 21], 'Tenth')
  endif

  " Test 14b: Same link from next line
  let links = md#links#testfns#findReferenceLinksInLine(57)
  call test#framework#assert_equal(1, len(links), "Should find reference link on line 57")
  if len(links) > 0
    let link = links[0]
    call test#framework#assert_equal('a reference link', link.text, "Should correctly concatenate reference link text across lines from second line")
    call s:assert_fulllink_positions(link, [56, 75], [57, 21], 'Tenth (from second line)')
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
