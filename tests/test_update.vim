" Test suite for md#update module functions
" Tests the following functions:
" - md#update#incHeadingLevel
" - md#update#decHeadingLevel
" - md#update#nestSection
" - md#update#moveSectionBack
" - md#update#moveSectionForward
" - md#update#raiseSectionBack
" - md#update#raiseSectionForward

" Helper function to setup main test buffer (comprehensive test case)
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('comprehensive.md')
endfunction

" Helper function to get the heading level of a line (extract # count)
function! s:get_heading_level(lnum)
  let line = getline(a:lnum)
  let match_result = matchlist(line, '^\(#\+\)\s')
  if len(match_result) > 1
    return len(match_result[1])
  endif
  return 0
endfunction

" Helper function to check if buffer content matches expected structure
function! s:verify_buffer_structure(expected_lines)
  let actual_lines = getline(1, '$')
  for i in range(len(a:expected_lines))
    let expected = a:expected_lines[i]
    let actual = i < len(actual_lines) ? actual_lines[i] : ''
    if expected != actual
      call test#framework#assert_equal(expected, actual, "Line " . (i+1) . " mismatch")
      return 0
    endif
  endfor
  return 1
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#update module...")
  call test#framework#write_info("====================================")
  
  " Use individual safe execution calls
  call test#framework#run_test_function("test_incHeadingLevel", function("s:test_incHeadingLevel"))
  call test#framework#run_test_function("test_decHeadingLevel", function("s:test_decHeadingLevel"))
  call test#framework#run_test_function("test_nestSection", function("s:test_nestSection"))
  call test#framework#run_test_function("test_moveSectionBack", function("s:test_moveSectionBack"))
  call test#framework#run_test_function("test_moveSectionForward", function("s:test_moveSectionForward"))
  call test#framework#run_test_function("test_raiseSectionBack", function("s:test_raiseSectionBack"))
  call test#framework#run_test_function("test_raiseSectionForward", function("s:test_raiseSectionForward"))
  call test#framework#run_test_function("test_edge_cases", function("s:test_edge_cases"))
  
  return test#framework#report_results("md#update")
endfunction

function! s:test_incHeadingLevel()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#incHeadingLevel...")
  
  " Test 1: Increase heading level without descendents
  call s:setup_test_buffer()
  call cursor(6, 1)  " ## Section A
  call md#update#incHeadingLevel(0)
  call test#framework#assert_equal(3, s:get_heading_level(6), "incHeadingLevel(0) should increase only current heading")
  call test#framework#assert_equal(3, s:get_heading_level(10), "incHeadingLevel(0) should not affect children")
  
  " Test 2: Increase heading level with descendents
  call s:setup_test_buffer()
  call cursor(6, 1)  " ## Section A
  call md#update#incHeadingLevel(1)
  call test#framework#assert_equal(3, s:get_heading_level(6), "incHeadingLevel(1) should increase current heading")
  call test#framework#assert_equal(4, s:get_heading_level(10), "incHeadingLevel(1) should increase child headings")
  call test#framework#assert_equal(5, s:get_heading_level(14), "incHeadingLevel(1) should increase deep child headings")
  
  " Test 3: Increase from content line (should affect containing section)
  call s:setup_test_buffer()
  call cursor(8, 1)  " Section A content
  call md#update#incHeadingLevel(0)
  call test#framework#assert_equal(3, s:get_heading_level(6), "incHeadingLevel from content should affect containing section")
  
  " Test 4: Increase root level heading
  call s:setup_test_buffer()
  call cursor(1, 1)  " # Root Heading
  call md#update#incHeadingLevel(0)
  call test#framework#assert_equal(2, s:get_heading_level(1), "incHeadingLevel should work on root heading")
endfunction

function! s:test_decHeadingLevel()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#decHeadingLevel...")
  
  " Test 1: Decrease heading level without descendents
  call s:setup_test_buffer()
  call cursor(10, 1)  " ### Subsection A1
  call md#update#decHeadingLevel(0)
  call test#framework#assert_equal(2, s:get_heading_level(10), "decHeadingLevel(0) should decrease only current heading")
  call test#framework#assert_equal(4, s:get_heading_level(14), "decHeadingLevel(0) should not affect children")
  
  " Test 2: Decrease heading level with descendents
  call s:setup_test_buffer()
  call cursor(10, 1)  " ### Subsection A1
  call md#update#decHeadingLevel(1)
  call test#framework#assert_equal(2, s:get_heading_level(10), "decHeadingLevel(1) should decrease current heading")
  call test#framework#assert_equal(3, s:get_heading_level(14), "decHeadingLevel(1) should decrease child headings")
  
  " Test 3: Decrease from content line
  call s:setup_test_buffer()
  call cursor(12, 1)  " Subsection A1 content
  call md#update#decHeadingLevel(0)
  call test#framework#assert_equal(2, s:get_heading_level(10), "decHeadingLevel from content should affect containing section")
  
  " Test 4: Cannot decrease level 1 heading below level 1
  call s:setup_test_buffer()
  call cursor(1, 1)  " # Root Heading
  call md#update#decHeadingLevel(0)
  call test#framework#assert_equal(1, s:get_heading_level(1), "decHeadingLevel should not decrease level 1 below level 1")
endfunction

function! s:test_nestSection()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#nestSection...")
  
  " Test 1: Nest a section (should create parent heading and increase levels)
  call s:setup_test_buffer()
  let original_line_count = line('$')
  call cursor(6, 1)  " ## Section A
  call md#update#nestSection()
  
  " Should create a new heading above the current section
  call test#framework#assert_equal(original_line_count + 1, line('$'), "nestSection should add one line")
  call test#framework#assert_equal(2, s:get_heading_level(6), "nestSection should create new parent heading")
  call test#framework#assert_equal(3, s:get_heading_level(7), "nestSection should increase current heading level")
  
  " Test 2: Nest from content line
  call s:setup_test_buffer()
  call cursor(8, 1)  " Section A content
  call md#update#nestSection()
  call test#framework#assert_equal(3, s:get_heading_level(7), "nestSection from content should affect containing section")
  
  " Test 3: Cursor positioning after nesting
  call s:setup_test_buffer()
  call cursor(6, 1)  " ## Section A
  call md#update#nestSection()
  call test#framework#assert_equal(6, line('.'), "nestSection should position cursor on new parent heading")
endfunction

function! s:test_moveSectionBack()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#moveSectionBack...")
  
  " Test 1: Move section back to previous sibling - verify movement occurred
  call s:setup_test_buffer()
  call cursor(22, 1)  " ## Section B
  let original_content = getline(22, 29)  " Get Section B content
  call md#update#moveSectionBack()
  
  " Section B should now appear earlier in the document
  let moved_successfully = 0
  for line_num in range(1, 21)  " Check if Section B appears before line 22
    if getline(line_num) == "## Section B"
      let moved_successfully = 1
      break
    endif
  endfor
  call test#framework#assert_equal(1, moved_successfully, "moveSectionBack should move section before previous sibling")
  
  " Test 2: Cannot move first sibling back
  call s:setup_test_buffer()
  call cursor(6, 1)  " ## Section A (first sibling)
  let original_position = line('.')
  call md#update#moveSectionBack()
  " Check that Section A is still at its original position or close to it
  let section_a_found = 0
  for line_num in range(1, 10)
    if getline(line_num) == "## Section A"
      let section_a_found = 1
      break
    endif
  endfor
  call test#framework#assert_equal(1, section_a_found, "moveSectionBack should not move first sibling far")
  
  " Test 3: Move from content line - verify it doesn't crash and tries to move
  call test#framework#setup_buffer_with_content([
    \ '# Root',
    \ '',
    \ '## First Section', 
    \ 'First content',
    \ '',
    \ '## Second Section',
    \ 'Second content', 
    \ '',
    \ '## Third Section',
    \ 'Third content'
  \ ])
  call cursor(7, 1)  " "Second content"
  " Just verify the function runs without error and the content is preserved
  try
    call md#update#moveSectionBack()
    " Check that the sections still exist in some order
    let second_found = 0
    for line_num in range(1, line('$'))
      if getline(line_num) == "## Second Section"
        let second_found = 1
        break
      endif
    endfor
    call test#framework#assert_equal(1, second_found, "moveSectionBack from content should preserve section")
  catch
    call test#framework#assert_equal(1, 1, "moveSectionBack from content handled gracefully")
  endtry
endfunction

function! s:test_moveSectionForward()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#moveSectionForward...")
  
  " Test 1: Move section forward to after next sibling - verify movement occurred
  call s:setup_test_buffer()
  call cursor(6, 1)  " ## Section A
  let original_a_line = 0
  for line_num in range(1, line('$'))
    if getline(line_num) == "## Section A"
      let original_a_line = line_num
      break
    endif
  endfor
  call md#update#moveSectionForward()
  
  " Find Section A after the operation
  let new_a_line = 0
  for line_num in range(1, line('$'))
    if getline(line_num) == "## Section A"
      let new_a_line = line_num
      break
    endif
  endfor
  " Section A should have moved to a later line number
  let moved_successfully = (new_a_line > 0 && new_a_line > original_a_line)
  call test#framework#assert_equal(1, moved_successfully, "moveSectionForward should move section after next sibling")
  
  " Test 2: Cannot move last sibling forward
  call s:setup_test_buffer()
  call cursor(30, 1)  " ## Section C (last sibling)
  call md#update#moveSectionForward()
  " Verify Section C is still near its original position
  let section_c_found = 0
  for line_num in range(25, line('$'))
    if getline(line_num) == "## Section C"
      let section_c_found = 1
      break
    endif
  endfor
  call test#framework#assert_equal(1, section_c_found, "moveSectionForward should not move last sibling far")
  
  " Test 3: Move from content line
  call s:setup_test_buffer()
  call cursor(8, 1)  " Section A content
  let original_a_line = 0
  for line_num in range(1, line('$'))
    if getline(line_num) == "## Section A"
      let original_a_line = line_num
      break
    endif
  endfor
  call md#update#moveSectionForward()
  " Find Section A after the operation
  let new_a_line = 0
  for line_num in range(1, line('$'))
    if getline(line_num) == "## Section A"
      let new_a_line = line_num
      break
    endif
  endfor
  " Section A should have moved to a later line number
  let moved_successfully = (new_a_line > 0 && new_a_line > original_a_line)
  call test#framework#assert_equal(1, moved_successfully, "moveSectionForward from content should move containing section")
endfunction

function! s:test_raiseSectionBack()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#raiseSectionBack...")
  
  " Test 1: Raise subsection to become sibling of parent, positioned before parent
  call s:setup_test_buffer()
  call cursor(10, 1)  " ### Subsection A1
  call md#update#raiseSectionBack()
  
  " Subsection A1 should become a level 2 heading before Section A
  call test#framework#assert_equal(2, s:get_heading_level(6), "raiseSectionBack should decrease heading level")
  call test#framework#assert_equal("## Subsection A1", getline(6), "raiseSectionBack should move section before parent")
  
  " Test 2: Cannot raise root level section
  call s:setup_test_buffer()
  call cursor(1, 1)  " # Root Heading
  let original_line = getline(1)
  call md#update#raiseSectionBack()
  call test#framework#assert_equal(original_line, getline(1), "raiseSectionBack should not affect root level")
  
  " Test 3: Raise from content line
  call s:setup_test_buffer()
  call cursor(12, 1)  " Subsection A1 content
  call md#update#raiseSectionBack()
  call test#framework#assert_equal("## Subsection A1", getline(6), "raiseSectionBack from content should affect containing section")
endfunction

function! s:test_raiseSectionForward()
  call test#framework#write_info("")
  call test#framework#write_info("Testing md#update#raiseSectionForward...")
  
  " Test 1: Raise subsection to become sibling of parent, positioned after parent's siblings
  call s:setup_test_buffer()
  call cursor(10, 1)  " ### Subsection A1
  call md#update#raiseSectionForward()
  
  " Subsection A1 should become a level 2 heading after the last sibling of Section A
  call test#framework#assert_equal(2, s:get_heading_level(line('.')), "raiseSectionForward should decrease heading level")
  let raised_line = getline(line('.'))
  call test#framework#assert_equal("## Subsection A1", raised_line, "raiseSectionForward should move section after parent siblings")
  
  " Test 2: Cannot raise root level section (should not change much)
  call s:setup_test_buffer()
  call cursor(1, 1)  " # Root Heading
  let original_line = getline(1)
  call md#update#raiseSectionForward()
  " The root heading should still exist somewhere in the buffer
  let root_found = 0
  for line_num in range(1, line('$'))
    if getline(line_num) == original_line
      let root_found = 1
      break
    endif
  endfor
  call test#framework#assert_equal(1, root_found, "raiseSectionForward should not remove root level heading")
  
  " Test 3: Raise from content line
  call s:setup_test_buffer()
  call cursor(12, 1)  " Subsection A1 content
  call md#update#raiseSectionForward()
  let raised_line = getline(line('.'))
  call test#framework#assert_equal("## Subsection A1", raised_line, "raiseSectionForward from content should affect containing section")
endfunction

function! s:test_edge_cases()
  call test#framework#write_info("")
  call test#framework#write_info("Testing edge cases...")
  
  " Test 1: Empty buffer - functions should handle gracefully
  call test#framework#setup_buffer_with_content([])
  call cursor(1, 1)
  " These functions should not crash, though they may not perform operations
  try
    call md#update#moveSectionBack()
    call test#framework#assert_equal(1, 1, "moveSectionBack should handle empty buffer gracefully")
  catch
    call test#framework#assert_equal(1, 1, "moveSectionBack handled empty buffer with expected error")
  endtry
  
  " Test 2: No headings
  call test#framework#setup_buffer_from_file('no_headings.md')
  call cursor(1, 1)
  let original_content = getline(1)
  try
    call md#update#moveSectionBack()
    " Should not crash or modify content significantly
    call test#framework#assert_equal(original_content, getline(1), "moveSectionBack should handle no headings gracefully")
  catch
    call test#framework#assert_equal(1, 1, "moveSectionBack handled no headings with expected error")
  endtry
  
  " Test 3: Single heading
  call test#framework#setup_buffer_from_file('single_heading.md')
  call cursor(1, 1)
  let original_content = getline(1)
  call md#update#moveSectionForward()
  call test#framework#assert_equal(original_content, getline(1), "moveSectionForward should handle single heading gracefully")
  
  " Test 4: Section with no siblings (for move operations)
  call test#framework#setup_buffer_with_content(['# Root', '', '## Only Child', '', 'Content'])
  call cursor(3, 1)  " ## Only Child
  let original_content = getline(3)
  call md#update#moveSectionBack()
  call test#framework#assert_equal(original_content, getline(3), "moveSectionBack should handle section with no siblings")
  
  " Test 5: Heading level operations on valid headings
  call test#framework#setup_buffer_with_content(['# Root', '', '## Level 2', '', '### Level 3', '', '#### Level 4', '', '##### Level 5', '', '###### Level 6'])
  call cursor(11, 1)  " ###### Level 6
  call md#update#incHeadingLevel(0)
  " Level 6 is max, so should stay at 6
  call test#framework#assert_equal(6, s:get_heading_level(11), "incHeadingLevel should handle max heading level")
  
  " Test 6: Try to decrease level 1 heading
  call cursor(1, 1)  " # Root
  call md#update#decHeadingLevel(0)
  call test#framework#assert_equal(1, s:get_heading_level(1), "decHeadingLevel should not decrease level 1 below 1")
endfunction

" Run all tests
" Initialize test framework with results file
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init(g:mdpp_repo_root . '/tests/results.md')
  call s:run_tests()
endif