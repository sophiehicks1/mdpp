" Test suite for md#move module functions
" Tests the following functions:
" - md#move#backToHeading
" - md#move#forwardToHeading
" - md#move#backToSibling
" - md#move#backToParent
" - md#move#forwardToFirstChild

" Helper function to setup main test buffer (comprehensive test case)
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('comprehensive.md')
endfunction

function! s:run_tests()
  call test#framework#reset()

  call test#framework#write_info("Running tests for md#move module...")
  call test#framework#write_info("==================================")

  " Use individual safe execution calls
  call test#framework#run_test_function("test_backToHeading", function("s:test_backToHeading"))
  call test#framework#run_test_function("test_comprehensive_backward_navigation",
        \ function("s:test_comprehensive_backward_navigation"))
  call test#framework#run_test_function("test_forwardToHeading", function("s:test_forwardToHeading"))
  call test#framework#run_test_function("test_comprehensive_forward_navigation",
        \ function("s:test_comprehensive_forward_navigation"))
  call test#framework#run_test_function("test_backToSibling", function("s:test_backToSibling"))
  call test#framework#run_test_function("test_forwardToSibling", function("s:test_forwardToSibling"))
  call test#framework#run_test_function("test_backToParent", function("s:test_backToParent"))
  call test#framework#run_test_function("test_forwardToFirstChild", function("s:test_forwardToFirstChild"))
  call test#framework#run_test_function("test_edge_cases", function("s:test_edge_cases"))

  return test#framework#report_results("md#move")
endfunction

" Test md#move#backToHeading function
function! s:test_backToHeading()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#move#backToHeading...")

  call s:setup_test_buffer()

  " Test 1: From line 8 (Section A content) should go to line 6 (## Section A)
  call cursor(8, 1)
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(6, line('.'), "backToHeading from content should go to section heading")

  " Test 2: From line 6 (## Section A) should go to line 1 (# Root Heading)
  call cursor(6, 1)
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(1, line('.'), "backToHeading from section should go to previous heading")

  " Test 3: From line 1 (first heading) should stay at line 1 (no previous heading)
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "backToHeading from first heading should not move")

  " Test 4: From content before first heading should not move
  call test#framework#setup_buffer_from_file('content_before_heading.md')
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "backToHeading from before first heading should not move")
endfunction

" Comprehensive test for backward navigation across all heading levels
function! s:test_comprehensive_backward_navigation()
  call s:setup_test_buffer()

  " Build index of all headings in the document
  let heading_lines = []
  for lnum in range(1, line('$'))
    let line_text = getline(lnum)
    if line_text =~ '^#\+\s'
      call add(heading_lines, lnum)
    endif
  endfor
  let heading_lines = reverse(heading_lines)

  " Start on the last line
  call cursor(line('$'), 1)

  " Move backward through headings - test that we can navigate through multiple levels
  for i in range(0, len(heading_lines) - 1)
    call md#move#backToHeadingNormal()
    let expected_line = heading_lines[i]
    let current_line = line('.')

    " Should land on the expected heading
    call test#framework#assert_equal(expected_line, current_line,
          \ printf("Comprehensive backward step %d should reach heading at line %d",
          \        i, expected_line))
  endfor
endfunction

" Test md#move#forwardToHeading function
function! s:test_forwardToHeading()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#move#forwardToHeading...")

  call s:setup_test_buffer()

  " Test 1: From line 1 (# Root Heading) should go to line 6 (## Section A)
  call cursor(1, 1)
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(6, line('.'), "forwardToHeading from root should go to next heading")

  " Test 2: From line 3 (content) should go to line 6 (## Section A)
  call cursor(3, 1)
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(6, line('.'), "forwardToHeading from content should go to next heading")

  " Test 3: From last heading should not move
  call cursor(35, 1)
  let original_line = line('.')
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToHeading from last heading should not move")

  " Test 4: From content after last heading should not move
  call cursor(36, 1)
  let original_line = line('.')
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToHeading from content after last heading should not move")
endfunction

" Comprehensive test for forward navigation across all heading levels
function! s:test_comprehensive_forward_navigation()
  call s:setup_test_buffer()

  " Build index of all headings in the document
  let heading_lines = []
  for lnum in range(1, line('$'))
    let line_text = getline(lnum)
    if line_text =~ '^#\+\s'
      call add(heading_lines, lnum)
    endif
  endfor

  " Start from the beginning of the document and navigate forward through all headings
  call cursor(1, 1)

  " Move forward through all headings systematically
  for i in range(1, len(heading_lines) - 1)
    call md#move#forwardToHeadingNormal()
    let current_line = line('.')

    " Should land on the expected heading
    call test#framework#assert_equal(heading_lines[i], current_line,
          \ printf("Comprehensive forward step %d should reach heading at line %d",
          \        i, heading_lines[i]))
  endfor

  " One more move from the last heading should not move
  let last_heading_line = line('.')
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(last_heading_line, line('.'),
        \ "Final forward move from last heading should not move")
endfunction

" Test md#move#backToSibling function
function! s:test_backToSibling()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#move#backToSibling...")

  call s:setup_test_buffer()

  " Test 1: From ## Section B (line 22) should go to ## Section A (line 6)
  call cursor(22, 1)
  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(6, line('.'), "backToSibling should move to previous sibling")

  " Test 2: From ### Subsection A2 (line 18) should go to ### Subsection A1 (line 10)
  call cursor(18, 1)
  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(10, line('.'), "backToSibling should move to previous subsection sibling")

  " Test 3: From first sibling should not move
  call cursor(26, 1)  " ## Subsection B1 (first level 2 heading under Section B)
  let original_line = line('.')
  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(original_line, line('.'), "backToSibling from first sibling should not move")

  " Test 4: From content should work based on containing section
  call cursor(24, 1)  " Section B content
  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(22, line('.'), "backToSibling from content should go to current section heading")

  " Test 5: From section with no siblings should not move
  call cursor(14, 1)  " #### Deep A1 (only level 4 heading)
  let original_line = line('.')
  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(original_line, line('.'), "backToSibling with no siblings should not move")
endfunction

" Test md#move#forwardToSibling function
function! s:test_forwardToSibling()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#move#forwardToSibling...")

  call s:setup_test_buffer()

  " Test 1: From ## Section A (line 6) should go to ## Section B (line 22)
  call cursor(6, 1)
  call md#move#forwardToSiblingNormal()
  call test#framework#assert_equal(22, line('.'), "forwardToSibling should move to next sibling")

  " Test 2: From ### Subsection A1 (line 10) should go to ### Subsection A2 (line 18)
  call cursor(10, 1)
  call md#move#forwardToSiblingNormal()
  call test#framework#assert_equal(18, line('.'), "forwardToSibling should move to next subsection sibling")

  " Test 3: From ## Section B (line 22) should go to ## Section C (line 30)
  call cursor(22, 1)
  call md#move#forwardToSiblingNormal()
  call test#framework#assert_equal(30, line('.'), "forwardToSibling should move across multiple siblings")

  " Test 4: From last sibling should not move
  call cursor(18, 1)  " ## Subsection A2 (last level 2 heading under Section A)
  let original_line = line('.')
  call md#move#forwardToSiblingNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToSibling from last sibling should not move")

  " Test 5: From content should work based on containing section
  call cursor(8, 1)  " Section A content
  call md#move#forwardToSiblingNormal()
  call test#framework#assert_equal(22, line('.'), "forwardToSibling from content should go to next sibling of current section")

  " Test 6: From section with no siblings should not move
  call cursor(14, 1)  " #### Deep A1 (only level 4 heading)
  let original_line = line('.')
  call md#move#forwardToSiblingNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToSibling with no siblings should not move")
endfunction

" Test md#move#backToParent function
function! s:test_backToParent()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#move#backToParent...")

  call s:setup_test_buffer()

  " Test 1: From ### Subsection A1 (line 10) should go to ## Section A (line 6)
  call cursor(10, 1)
  call md#move#backToParentNormal()
  call test#framework#assert_equal(6, line('.'), "backToParent should move to parent heading")

  " Test 2: From #### Deep A1 (line 14) should go to ### Subsection A1 (line 10)
  call cursor(14, 1)
  call md#move#backToParentNormal()
  call test#framework#assert_equal(10, line('.'), "backToParent should move to immediate parent")

  " Test 3: From content should go to section heading
  call cursor(12, 1)  " Subsection A1 content
  call md#move#backToParentNormal()
  call test#framework#assert_equal(10, line('.'), "backToParent from content should go to section heading")

  " Test 4: From root heading should not move (no parent)
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToParentNormal()
  call test#framework#assert_equal(original_line, line('.'), "backToParent from root heading should not move")

  " Test 5: From content under root heading should go to root heading
  call cursor(3, 1)  " Root content line 1
  call md#move#backToParentNormal()
  call test#framework#assert_equal(1, line('.'), "backToParent from root content should go to root heading")

  " Test 6: backToParent should skip siblings to find parent (from line 22 to line 1)
  call cursor(22, 1)  " ## Section B
  call md#move#backToParentNormal()
  call test#framework#assert_equal(1, line('.'), "backToParent should skip siblings and go to parent (# Root Heading)")

  " Test 7: From content before root heading should not move
  call test#framework#setup_buffer_from_file('content_before_heading.md')
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToParentNormal()
  call test#framework#assert_equal(original_line, line('.'), "backToParent from before root heading should not move")
endfunction

" Test md#move#forwardToFirstChild function
function! s:test_forwardToFirstChild()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#move#forwardToFirstChild...")

  call s:setup_test_buffer()

  " Test 1: From ## Section A (line 6) should go to ### Subsection A1 (line 10)
  call cursor(6, 1)
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(10, line('.'), "forwardToFirstChild should move to first child heading")

  " Test 2: From ### Subsection A1 (line 10) should go to #### Deep A1 (line 14)
  call cursor(10, 1)
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(14, line('.'), "forwardToFirstChild should move to deeper child")

  " Test 3: From heading with no children should not move
  call cursor(14, 1)  " #### Deep A1 (no children)
  let original_line = line('.')
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToFirstChild with no children should not move")

  " Test 4: From content should work based on containing section
  call cursor(8, 1)  " Section A content
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(10, line('.'), "forwardToFirstChild from content should use containing section")

  " Test 5: From content before root heading, should move to root heading if
  " any
  call test#framework#setup_buffer_from_file('content_before_heading.md')
  call cursor(1, 1)
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(2, line('.'), "forwardToFirstChild from before root heading should go to root heading if exists")

  " Test 6: From content with no headings should not move
  call test#framework#setup_buffer_from_file('no_headings.md')
  call cursor(2, 1)
  let original_line = line('.')
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToFirstChild with no headings should not move")
endfunction

" TODO make sure this actually makes sense
" Test edge cases
function! s:test_edge_cases()
  call test#framework#write_info("")
  call test#framework#write_info("Testing edge cases...")

  " Test with empty buffer
  call test#framework#setup_buffer_from_lines([])

  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "Empty buffer: backToHeading should not move")

  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "Empty buffer: forwardToHeading should not move")

  " Test with only content, no headings
  call test#framework#setup_buffer_from_file('no_headings.md')

  call cursor(2, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "No headings: backToHeading should not move")

  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "No headings: forwardToHeading should not move")

  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(original_line, line('.'), "No headings: backToSibling should not move")

  call md#move#backToParentNormal()
  call test#framework#assert_equal(original_line, line('.'), "No headings: backToParent should not move")

  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(original_line, line('.'), "No headings: forwardToFirstChild should not move")

  " Test with single heading
  call test#framework#setup_buffer_from_file('single_heading.md')

  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "Single heading: backToHeading should not move")

  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "Single heading: forwardToHeading should not move")

  call md#move#backToSiblingNormal()
  call test#framework#assert_equal(original_line, line('.'), "Single heading: backToSibling should not move")

  call md#move#backToParentNormal()
  call test#framework#assert_equal(original_line, line('.'), "Single heading: backToParent should not move")

  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(original_line, line('.'), "Single heading: forwardToFirstChild should not move")

  " Test underline-style headings
  call test#framework#setup_buffer_from_file('underline_headings.md')

  call cursor(4, 1)
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(1, line('.'), "Underline headings: backToHeading should work")

  call cursor(1, 1)
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(6, line('.'), "Underline headings: forwardToHeading should work")
endfunction

" Run all tests
" Initialize test framework with results file
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('move.txt')
  call s:run_tests()
endif
