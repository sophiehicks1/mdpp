" Test suite for md#links module functions
" Tests the following functions:
" - md#links#findLinkAtCursor
" - md#links#findInlineLinksInLine
" - md#links#findReferenceLinksInLine
" - md#links#getLinkText
" - md#links#getLinkUrl
" - md#links#getLinkTextRange
" - md#links#getLinkUrlRange
" - md#links#getLinkFullRange

" Helper function to setup test buffer with links test data
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('links.md')
endfunction

function! s:run_tests()
  call test#framework#reset("links")
  
  call test#framework#write_info("Running tests for md#links module...")
  call test#framework#write_info("====================================")
  
  call s:test_findInlineLinksInLine()
  call s:test_findReferenceLinksInLine()
  call s:test_findLinkAtCursor()
  call s:test_getLinkText()
  call s:test_getLinkUrl()
  call s:test_getLinkTextRange()
  call s:test_getLinkUrlRange()
  call s:test_getLinkFullRange()
  call s:test_edge_cases()
  
  return test#framework#report_results("md#links")
endfunction

" Test md#links#findInlineLinksInLine function
function! s:test_findInlineLinksInLine()
  call test#framework#write_info("Testing md#links#findInlineLinksInLine...")
  
  call s:setup_test_buffer()
  
  " Test 1: Line with simple inline link  
  let line_num = 5
  let line_content = getline(5)  " Get actual line content from buffer
  let links = md#links#findInlineLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should find one inline link")
  if len(links) > 0
    call test#framework#assert_equal('inline', links[0].type, "Link type should be inline")
    call test#framework#assert_equal('example', links[0].text, "Link text should match")
    call test#framework#assert_equal('http://example.com', links[0].url, "Link URL should match")
    call test#framework#assert_equal(21, links[0].start_col, "Link start column should be correct")
    call test#framework#assert_equal(49, links[0].end_col, "Link end column should be correct")
  endif
  
  " Test 2: Line with multiple inline links
  let line_num = 8  " Update to correct line number
  let line_content = getline(8)  " Get actual line content from buffer
  let links = md#links#findInlineLinksInLine(line_num, line_content)
  call test#framework#assert_equal(2, len(links), "Should find two inline links")
  call test#framework#assert_equal('first', links[0].text, "First link text should match")
  call test#framework#assert_equal('http://first.com', links[0].url, "First link URL should match")
  call test#framework#assert_equal('second', links[1].text, "Second link text should match")
  call test#framework#assert_equal('http://second.com', links[1].url, "Second link URL should match")
  
  " Test 3: Line with complex text
  let line_num = 7  " Update to correct line number
  let line_content = getline(7)  " Get actual line content from buffer
  let links = md#links#findInlineLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should find one complex inline link")
  call test#framework#assert_equal('**bold text** and *italic*', links[0].text, "Complex text should be preserved")
  
  " Test 4: Line with no inline links
  let line_num = 42  " Update to a line with plain text
  let line_content = getline(42)  " Get actual line content from buffer
  let links = md#links#findInlineLinksInLine(line_num, line_content)
  call test#framework#assert_equal(0, len(links), "Should find no inline links in plain text")
  
  " Test 5: Line with nested brackets
  let line_num = 30  " Update to correct line number
  let line_content = getline(30)  " Get actual line content from buffer
  let links = md#links#findInlineLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should handle nested brackets")
  call test#framework#assert_equal('text with [brackets]', links[0].text, "Nested brackets should be preserved")
  
  " Test 6: Malformed link (no closing parenthesis)
  let line_num = 38  " Update to correct line number
  let line_content = getline(38)  " Get actual line content from buffer
  let links = md#links#findInlineLinksInLine(line_num, line_content)
  call test#framework#assert_equal(0, len(links), "Should not find malformed links")
endfunction

" Test md#links#findReferenceLinksInLine function
function! s:test_findReferenceLinksInLine()
  call test#framework#write_info("Testing md#links#findReferenceLinksInLine...")
  
  call s:setup_test_buffer()
  
  " Test 1: Line with simple reference link
  let line_num = 12  " Update to correct line number
  let line_content = getline(12)  " Get actual line content from buffer
  let links = md#links#findReferenceLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should find one reference link")
  call test#framework#assert_equal('reference', links[0].type, "Link type should be reference")
  call test#framework#assert_equal('example reference', links[0].text, "Reference text should match")
  call test#framework#assert_equal('ref1', links[0].reference, "Reference label should match")
  call test#framework#assert_equal('http://example.com', links[0].url, "Reference URL should be resolved")
  
  " Test 2: Line with implicit reference
  let line_num = 13  " Update to correct line number
  let line_content = getline(13)  " Get actual line content from buffer
  let links = md#links#findReferenceLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should find implicit reference link")
  call test#framework#assert_equal('example', links[0].text, "Implicit reference text should match")
  call test#framework#assert_equal('example', links[0].reference, "Implicit reference should use text as reference")
  call test#framework#assert_equal('http://implicit-example.com', links[0].url, "Implicit reference URL should be resolved")
  
  " Test 3: Line with complex text reference
  let line_num = 14  " Update to correct line number
  let line_content = getline(14)  " Get actual line content from buffer
  let links = md#links#findReferenceLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should find complex reference link")
  call test#framework#assert_equal('**bold** and *italic* text', links[0].text, "Complex reference text should be preserved")
  call test#framework#assert_equal('ref2', links[0].reference, "Complex reference label should match")
  
  " Test 4: Line with no reference links
  let line_num = 42  " Update to correct line number  
  let line_content = getline(42)  " Get actual line content from buffer
  let links = md#links#findReferenceLinksInLine(line_num, line_content)
  call test#framework#assert_equal(0, len(links), "Should find no reference links in plain text")
  
  " Test 5: Reference link with missing definition
  let line_num = 36  " Update to correct line number
  let line_content = getline(36)  " Get actual line content from buffer
  let links = md#links#findReferenceLinksInLine(line_num, line_content)
  call test#framework#assert_equal(1, len(links), "Should still find reference link structure")
  call test#framework#assert_equal('', links[0].url, "Missing reference should have empty URL")
endfunction

" Test md#links#findLinkAtCursor function
function! s:test_findLinkAtCursor()
  call test#framework#write_info("Testing md#links#findLinkAtCursor...")
  
  call s:setup_test_buffer()
  
  " Test 1: Cursor on inline link text
  call cursor(5, 25)  " Middle of [example] in "Simple inline link: [example](http://example.com)"
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal('inline', link.type, "Should find inline link at cursor")
  call test#framework#assert_equal('example', link.text, "Cursor on inline link should return correct text")
  call test#framework#assert_equal('http://example.com', link.url, "Cursor on inline link should return correct URL")
  
  " Test 2: Cursor on reference link text
  call cursor(12, 25)  " Middle of [example reference] in "Simple reference: [example reference][ref1]"
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal('reference', link.type, "Should find reference link at cursor")
  call test#framework#assert_equal('example reference', link.text, "Cursor on reference link should return correct text")
  call test#framework#assert_equal('ref1', link.reference, "Cursor on reference link should return correct reference")
  
  " Test 3: Cursor on reference definition
  call cursor(18, 5)  " On [ref1]: http://example.com
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal('reference', link.type, "Should find reference link that refers to this definition")
  call test#framework#assert_equal('ref1', link.reference, "Reference definition should return correct reference")
  call test#framework#assert_equal('http://example.com', link.url, "Reference definition should return correct URL")
  
  " Test 4: Cursor not on a link
  call cursor(1, 5)  " On "# Links Test Data"
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal({}, link, "Should return empty dict when cursor not on link")
  
  " Test 5: Cursor at link boundary
  call cursor(5, 21)  " At start of [example](http://example.com)
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal('inline', link.type, "Should find link at start boundary")
  
  call cursor(5, 49)  " At end of [example](http://example.com)
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal('inline', link.type, "Should find link at end boundary")
endfunction

" Test md#links#getLinkText function
function! s:test_getLinkText()
  call test#framework#write_info("Testing md#links#getLinkText...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get text from inline link
  call cursor(5, 25)
  let link = md#links#findLinkAtCursor()
  let text = md#links#getLinkText(link)
  call test#framework#assert_equal('example', text, "Should get correct text from inline link")
  
  " Test 2: Get text from reference link
  call cursor(12, 25)
  let link = md#links#findLinkAtCursor()
  let text = md#links#getLinkText(link)
  call test#framework#assert_equal('example reference', text, "Should get correct text from reference link")
  
  " Test 3: Get text from complex link
  call cursor(7, 30)
  let link = md#links#findLinkAtCursor()
  let text = md#links#getLinkText(link)
  call test#framework#assert_equal('**bold text** and *italic*', text, "Should preserve complex text formatting")
  
  " Test 4: Empty link_info
  let text = md#links#getLinkText({})
  call test#framework#assert_equal('', text, "Should return empty string for empty link_info")
endfunction

" Test md#links#getLinkUrl function
function! s:test_getLinkUrl()
  call test#framework#write_info("Testing md#links#getLinkUrl...")
  
  call s:setup_test_buffer()
  
  " Test 1: Get URL from inline link
  call cursor(5, 25)
  let link = md#links#findLinkAtCursor()
  let url = md#links#getLinkUrl(link)
  call test#framework#assert_equal('http://example.com', url, "Should get correct URL from inline link")
  
  " Test 2: Get URL from reference link
  call cursor(12, 25)
  let link = md#links#findLinkAtCursor()
  let url = md#links#getLinkUrl(link)
  call test#framework#assert_equal('http://example.com', url, "Should get resolved URL from reference link")
  
  " Test 3: Get URL from implicit reference
  call cursor(13, 25)
  let link = md#links#findLinkAtCursor()
  let url = md#links#getLinkUrl(link)
  call test#framework#assert_equal('http://implicit-example.com', url, "Should get resolved URL from implicit reference")
  
  " Test 4: Empty link_info
  let url = md#links#getLinkUrl({})
  call test#framework#assert_equal('', url, "Should return empty string for empty link_info")
endfunction

" Test md#links#getLinkTextRange function
function! s:test_getLinkTextRange()
  call test#framework#write_info("Testing md#links#getLinkTextRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: Text range for inline link
  call cursor(5, 25)
  let link = md#links#findLinkAtCursor()
  let range = md#links#getLinkTextRange(link)
  call test#framework#assert_equal([5, 22, 5, 28], range, "Should get correct text range for inline link")
  
  " Test 2: Text range for reference link
  call cursor(12, 25)
  let link = md#links#findLinkAtCursor()
  let range = md#links#getLinkTextRange(link)
  call test#framework#assert_equal([12, 20, 12, 36], range, "Should get correct text range for reference link")
  
  " Test 3: Empty link_info
  let range = md#links#getLinkTextRange({})
  call test#framework#assert_equal([], range, "Should return empty list for empty link_info")
endfunction

" Test md#links#getLinkUrlRange function
function! s:test_getLinkUrlRange()
  call test#framework#write_info("Testing md#links#getLinkUrlRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: URL range for inline link
  call cursor(5, 25)
  let link = md#links#findLinkAtCursor()
  let range = md#links#getLinkUrlRange(link)
  call test#framework#assert_equal([5, 31, 5, 48], range, "Should get correct URL range for inline link")
  
  " Test 2: URL range for reference link (should point to definition)
  call cursor(12, 25)
  let link = md#links#findLinkAtCursor()
  let range = md#links#getLinkUrlRange(link)
  call test#framework#assert_equal([18, 9, 18, 27], range, "Should get correct URL range for reference definition")
  
  " Test 3: Empty link_info
  let range = md#links#getLinkUrlRange({})
  call test#framework#assert_equal([], range, "Should return empty list for empty link_info")
endfunction

" Test md#links#getLinkFullRange function
function! s:test_getLinkFullRange()
  call test#framework#write_info("Testing md#links#getLinkFullRange...")
  
  call s:setup_test_buffer()
  
  " Test 1: Full range for inline link
  call cursor(5, 25)
  let link = md#links#findLinkAtCursor()
  let range = md#links#getLinkFullRange(link)
  call test#framework#assert_equal([5, 21, 5, 49], range, "Should get correct full range for inline link")
  
  " Test 2: Full range for reference link
  call cursor(12, 25)
  let link = md#links#findLinkAtCursor()
  let range = md#links#getLinkFullRange(link)
  call test#framework#assert_equal([12, 19, 12, 43], range, "Should get correct full range for reference link")
  
  " Test 3: Empty link_info
  let range = md#links#getLinkFullRange({})
  call test#framework#assert_equal([], range, "Should return empty list for empty link_info")
endfunction

" Test edge cases and error conditions
function! s:test_edge_cases()
  call test#framework#write_info("Testing edge cases...")
  
  " Test 1: Empty buffer
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
  
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal({}, link, "Empty buffer should return empty link")
  
  " Test 2: findInlineLinksInLine with empty line
  let links = md#links#findInlineLinksInLine(1, "")
  call test#framework#assert_equal(0, len(links), "Empty line should return no links")
  
  " Test 3: findReferenceLinksInLine with empty line
  let links = md#links#findReferenceLinksInLine(1, "")
  call test#framework#assert_equal(0, len(links), "Empty line should return no links")
  
  " Test 4: Test with buffer containing only reference definitions
  call test#framework#setup_buffer_with_content([
        \ '[ref1]: http://example.com',
        \ '[ref2]: http://another.com'
        \ ])
  
  call cursor(1, 5)  " On [ref1]: definition
  let link = md#links#findLinkAtCursor()
  call test#framework#assert_equal('reference_definition', link.type, "Should find reference definition")
  call test#framework#assert_equal('ref1', link.reference, "Should get correct reference name")
  call test#framework#assert_equal('http://example.com', link.url, "Should get correct reference URL")
endfunction

" Run the tests
call s:run_tests()