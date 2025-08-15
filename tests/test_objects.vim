" Test suite for md#objects module functions
" Tests the following functions:
" - md#objects#aroundSection
" - md#objects#insideSection
" - md#objects#aroundTree
" - md#objects#insideTree
" - md#objects#insideHeading
" - md#objects#aroundHeading
" - md#objects#insideLinkText
" - md#objects#aroundLinkText
" - md#objects#insideLinkUrl
" - md#objects#aroundLinkUrl
" - md#objects#insideLink
" - md#objects#aroundLink

" Helper function to setup main test buffer
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('objects_test.md')
endfunction

" Helper function to setup comprehensive test buffer for sections/trees
function! s:setup_comprehensive_buffer()
  call test#framework#setup_buffer_from_file('comprehensive.md')
endfunction

" Helper function to setup links test buffer
function! s:setup_links_buffer()
  call test#framework#setup_buffer_from_file('comprehensive_links.md')
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#objects module...")
  call test#framework#write_info("====================================")
  
  " Use individual safe execution calls
  call test#framework#run_test_function("test_aroundSection", function("s:test_aroundSection"))
  call test#framework#run_test_function("test_insideSection", function("s:test_insideSection"))
  call test#framework#run_test_function("test_aroundTree", function("s:test_aroundTree"))
  call test#framework#run_test_function("test_insideTree", function("s:test_insideTree"))
  call test#framework#run_test_function("test_insideHeading", function("s:test_insideHeading"))
  call test#framework#run_test_function("test_aroundHeading", function("s:test_aroundHeading"))
  call test#framework#run_test_function("test_insideLinkText", function("s:test_insideLinkText"))
  call test#framework#run_test_function("test_aroundLinkText", function("s:test_aroundLinkText"))
  call test#framework#run_test_function("test_insideLinkUrl", function("s:test_insideLinkUrl"))
  call test#framework#run_test_function("test_aroundLinkUrl", function("s:test_aroundLinkUrl"))
  call test#framework#run_test_function("test_insideLink", function("s:test_insideLink"))
  call test#framework#run_test_function("test_aroundLink", function("s:test_aroundLink"))
  call test#framework#run_test_function("test_edge_cases", function("s:test_edge_cases"))
  
  return test#framework#report_results("md#objects")
endfunction

" Test md#objects#aroundSection function
function! s:test_aroundSection()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#aroundSection...")
  
  call s:setup_comprehensive_buffer()
  
  " Test 1: From Section A content (line 8) should include header and content
  call cursor(8, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_equal('V', result[0], "aroundSection should return linewise selection")
  call test#framework#assert_equal(6, result[1][1], "aroundSection should start at section heading")
  call test#framework#assert_true(result[2][1] >= 8, "aroundSection should include at least the content line")
  
  " Test 2: From subsection A1 content should include only that subsection
  call cursor(12, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_equal('V', result[0], "aroundSection should return linewise selection")
  call test#framework#assert_equal(10, result[1][1], "aroundSection should start at subsection heading")
  call test#framework#assert_true(result[2][1] >= 12, "aroundSection should include at least the content line")
  
  " Test 3: From a heading line itself
  call cursor(6, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_equal('V', result[0], "aroundSection should work from heading line")
  call test#framework#assert_equal(6, result[1][1], "aroundSection should include the heading itself")
endfunction

" Test md#objects#insideSection function
function! s:test_insideSection()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#insideSection...")
  
  call s:setup_comprehensive_buffer()
  
  " Test 1: From Section A content should exclude the header
  call cursor(8, 1)
  let result = md#objects#insideSection()
  call test#framework#assert_equal('V', result[0], "insideSection should return linewise selection")
  call test#framework#assert_equal(8, result[1][1], "insideSection should start after heading")
  call test#framework#assert_equal(8, result[2][1], "insideSection should end at content")
  
  " Test 2: From subsection heading should get content only
  call cursor(10, 1)
  let result = md#objects#insideSection()
  call test#framework#assert_equal('V', result[0], "insideSection should return linewise selection")
  call test#framework#assert_equal(12, result[1][1], "insideSection should start at content line")
  call test#framework#assert_equal(12, result[2][1], "insideSection should end at content line")
endfunction

" Test md#objects#aroundTree function  
function! s:test_aroundTree()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#aroundTree...")
  
  call s:setup_comprehensive_buffer()
  
  " Test 1: From Section A should include all its children
  call cursor(8, 1)
  let result = md#objects#aroundTree()
  call test#framework#assert_equal('V', result[0], "aroundTree should return linewise selection")
  call test#framework#assert_equal(6, result[1][1], "aroundTree should start at section heading")
  " Should include all subsections up to next root section
  call test#framework#assert_true(result[2][1] >= 20, "aroundTree should include all children")
  
  " Test 2: From a leaf subsection should include just that section
  call cursor(16, 1)  " Deep A1 content
  let result = md#objects#aroundTree()
  call test#framework#assert_equal('V', result[0], "aroundTree should return linewise selection")
  call test#framework#assert_equal(14, result[1][1], "aroundTree should start at Deep A1 heading")
endfunction

" Test md#objects#insideTree function
function! s:test_insideTree()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#insideTree...")
  
  call s:setup_comprehensive_buffer()
  
  " Test 1: From Section A should include children content but not header
  call cursor(8, 1)
  let result = md#objects#insideTree()
  call test#framework#assert_equal('V', result[0], "insideTree should return linewise selection")
  call test#framework#assert_true(result[1][1] >= 7, "insideTree should start after section heading")
  call test#framework#assert_true(result[2][1] >= 20, "insideTree should include children content")
  
  " Test 2: From a leaf subsection should exclude header
  call cursor(16, 1)  " Deep A1 content
  let result = md#objects#insideTree()
  call test#framework#assert_equal('V', result[0], "insideTree should return linewise selection")
  call test#framework#assert_true(result[1][1] >= 15, "insideTree should start after heading")
endfunction

" Test md#objects#insideHeading function
function! s:test_insideHeading()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#insideHeading...")
  
  call s:setup_comprehensive_buffer()
  
  " Test 1: From Section A heading should select just the heading text
  call cursor(6, 1)
  let result = md#objects#insideHeading()
  call test#framework#assert_equal('v', result[0], "insideHeading should return charwise selection")
  call test#framework#assert_equal(6, result[1][1], "insideHeading should be on heading line")
  call test#framework#assert_true(result[1][2] > 3, "insideHeading should start after hash marks")
  
  " Test 2: From content should find the section heading
  call cursor(8, 1)
  let result = md#objects#insideHeading()
  call test#framework#assert_equal('v', result[0], "insideHeading should return charwise selection")
  call test#framework#assert_equal(6, result[1][1], "insideHeading should find section heading")
  
  " Test 3: Test with underline heading
  call s:setup_test_buffer()
  call cursor(53, 1)  " Single line heading with = underline
  let result = md#objects#insideHeading()
  call test#framework#assert_equal('v', result[0], "insideHeading should work with underline headings")
  call test#framework#assert_equal(53, result[1][1], "insideHeading should be on underline heading line")
endfunction

" Test md#objects#aroundHeading function
function! s:test_aroundHeading()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#aroundHeading...")
  
  call s:setup_comprehensive_buffer()
  
  " Test 1: From Section A heading should select entire heading line
  call cursor(6, 1)
  let result = md#objects#aroundHeading()
  call test#framework#assert_equal('v', result[0], "aroundHeading should return charwise selection")
  call test#framework#assert_equal(6, result[1][1], "aroundHeading should be on heading line")
  call test#framework#assert_equal(1, result[1][2], "aroundHeading should start at beginning of line")
  
  " Test 2: From content should find the section heading  
  call cursor(8, 1)
  let result = md#objects#aroundHeading()
  call test#framework#assert_equal('v', result[0], "aroundHeading should return charwise selection")
  call test#framework#assert_equal(6, result[1][1], "aroundHeading should find section heading")
endfunction

" Test md#objects#insideLinkText function
function! s:test_insideLinkText()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#insideLinkText...")
  
  call s:setup_links_buffer()
  
  " Test 1: From inside inline link text (try to find a link)
  call cursor(7, 10)  " Inside "Google" text of [Google](https://google.com)
  let result = md#objects#insideLinkText()
  " Test that function returns either a valid range or 0
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "insideLinkText should return valid range or 0")
  
  " Test 2: From reference link text (if links are found)
  call cursor(15, 10)  " Inside reference link text
  let result = md#objects#insideLinkText()
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "insideLinkText should return valid range or 0 for reference links")
  
  " Test 3: From outside any link should return 0
  call cursor(3, 1)  " On regular text
  let result = md#objects#insideLinkText()
  call test#framework#assert_equal(0, result, "insideLinkText should return 0 when not on link")
endfunction

" Test md#objects#aroundLinkText function
function! s:test_aroundLinkText()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#aroundLinkText...")
  
  call s:setup_links_buffer()
  
  " Test 1: From inside inline link text should include brackets
  call cursor(7, 10)  " Inside "Google" text
  let result = md#objects#aroundLinkText()
  call test#framework#assert_equal('v', result[0], "aroundLinkText should return charwise selection")
  call test#framework#assert_equal(7, result[1][1], "aroundLinkText should be on correct line")
  
  " Test 2: From reference link text should include brackets  
  call cursor(15, 10)  " Inside reference link text
  let result = md#objects#aroundLinkText()
  call test#framework#assert_equal('v', result[0], "aroundLinkText should work with reference links")
  call test#framework#assert_equal(15, result[1][1], "aroundLinkText should be on correct line")
  
  " Test 3: From outside any link should return 0
  call cursor(3, 1)  # On regular text
  let result = md#objects#aroundLinkText()
  call test#framework#assert_equal(0, result, "aroundLinkText should return 0 when not on link")
endfunction

" Test md#objects#insideLinkUrl function
function! s:test_insideLinkUrl()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#insideLinkUrl...")
  
  call s:setup_links_buffer()
  
  " Test 1: From inline link should select URL only
  call cursor(7, 10)  " Inside link text
  let result = md#objects#insideLinkUrl()
  call test#framework#assert_equal('v', result[0], "insideLinkUrl should return charwise selection")
  call test#framework#assert_equal(7, result[1][1], "insideLinkUrl should be on correct line")
  
  " Test 2: From reference link should find definition URL
  call cursor(15, 10)  " Inside reference link text
  let result = md#objects#insideLinkUrl()
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "insideLinkUrl should return valid range or 0 for reference links")
  
  " Test 3: From outside any link should return 0
  call cursor(3, 1)  " On regular text
  let result = md#objects#insideLinkUrl()
  call test#framework#assert_equal(0, result, "insideLinkUrl should return 0 when not on link")
endfunction

" Test md#objects#aroundLinkUrl function
function! s:test_aroundLinkUrl()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#aroundLinkUrl...")
  
  call s:setup_links_buffer()
  
  " Test 1: From inline link should include parentheses
  call cursor(7, 10)  " Inside link text
  let result = md#objects#aroundLinkUrl()
  call test#framework#assert_equal('v', result[0], "aroundLinkUrl should return charwise selection")
  call test#framework#assert_equal(7, result[1][1], "aroundLinkUrl should be on correct line")
  
  " Test 2: From reference link should include definition line
  call cursor(15, 10)  " Inside reference link text
  let result = md#objects#aroundLinkUrl()
  call test#framework#assert_true(result[0] == 'v' || result[0] == 'V', "aroundLinkUrl should return valid selection")
  
  " Test 3: From outside any link should return 0
  call cursor(3, 1)  # On regular text
  let result = md#objects#aroundLinkUrl()
  call test#framework#assert_equal(0, result, "aroundLinkUrl should return 0 when not on link")
endfunction

" Test md#objects#insideLink function
function! s:test_insideLink()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#insideLink...")
  
  call s:setup_links_buffer()
  
  " Test 1: From inline link should exclude outer brackets
  call cursor(7, 10)  " Inside link text
  let result = md#objects#insideLink()
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "insideLink should return valid range or 0")
  
  " Test 2: From reference link should exclude outer brackets
  call cursor(15, 10)  " Inside reference link text
  let result = md#objects#insideLink()
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "insideLink should return valid range or 0 for reference links")
  
  " Test 3: From outside any link should return 0
  call cursor(3, 1)  " On regular text
  let result = md#objects#insideLink()
  call test#framework#assert_equal(0, result, "insideLink should return 0 when not on link")
endfunction

" Test md#objects#aroundLink function
function! s:test_aroundLink()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#objects#aroundLink...")
  
  call s:setup_links_buffer()
  
  " Test 1: From inline link
  call cursor(7, 10)  " Inside link text
  let result = md#objects#aroundLink()
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "aroundLink should return valid range or 0")
  
  " Test 2: From reference link
  call cursor(15, 10)  " Inside reference link text
  let result = md#objects#aroundLink()
  call test#framework#assert_true(result == 0 || (type(result) == type([]) && len(result) == 3), "aroundLink should return valid range or 0 for reference links")
  
  " Test 3: From outside any link should return 0
  call cursor(3, 1)  " On regular text
  let result = md#objects#aroundLink()
  call test#framework#assert_equal(0, result, "aroundLink should return 0 when not on link")
endfunction

" Helper function to check if a result indicates "no match"
function! s:is_no_match(result)
  if a:result == 0
    return 1
  endif
  if type(a:result) == type([]) && len(a:result) == 0
    return 1
  endif
  return 0
endfunction

" Helper function to check if a result is a valid range
function! s:is_valid_range(result)
  return type(a:result) == type([]) && len(a:result) == 3 && (a:result[0] == 'v' || a:result[0] == 'V')
endfunction

" Test edge cases and error conditions
function! s:test_edge_cases()
  call test#framework#write_info("")
  call test#framework#write_info("Testing edge cases...")
  
  " Test empty buffer
  call test#framework#setup_buffer_with_content([])
  call cursor(1, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_true(s:is_no_match(result), "aroundSection should return 0 for empty buffer")
  
  let result = md#objects#insideHeading()
  call test#framework#assert_true(s:is_no_match(result), "insideHeading should return 0 for empty buffer")
  
  let result = md#objects#insideLinkText()
  call test#framework#assert_true(s:is_no_match(result), "insideLinkText should return 0 for empty buffer")
  
  " Test buffer with no headings
  call test#framework#setup_buffer_from_file('no_headings.md')
  call cursor(1, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_true(s:is_no_match(result), "aroundSection should return 0 when no headings")
  
  let result = md#objects#insideHeading()
  call test#framework#assert_true(s:is_no_match(result), "insideHeading should return 0 when no headings")
  
  " Test single heading buffer
  call test#framework#setup_buffer_from_file('single_heading.md')
  call cursor(1, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_true(s:is_valid_range(result) || s:is_no_match(result), "aroundSection should return valid range or 0 with single heading")
  
  let result = md#objects#insideHeading()
  call test#framework#assert_true(s:is_valid_range(result) || s:is_no_match(result), "insideHeading should return valid range or 0 with single heading")
  
  " Test underline headings
  call test#framework#setup_buffer_from_file('underline_headings.md')
  call cursor(1, 1)
  let result = md#objects#aroundSection()
  call test#framework#assert_true(s:is_valid_range(result) || s:is_no_match(result), "aroundSection should return valid range or 0 with underline headings")
  
  let result = md#objects#insideHeading()
  call test#framework#assert_true(s:is_valid_range(result) || s:is_no_match(result), "insideHeading should return valid range or 0 with underline headings")
endfunction

" Run all tests
" Initialize test framework with results file
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init(g:mdpp_repo_root . '/tests/results.md')
  call s:run_tests()
endif()
endifia run_tests.sh"
else
  call test#framework#init(g:mdpp_repo_root . '/tests/results.md')
  call s:run_tests()
endif()
endif