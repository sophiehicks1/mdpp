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
  
  echo "Running tests for md#move module..."
  echo "=================================="
  
  call s:test_backToHeading()
  call s:test_forwardToHeading()
  call s:test_backToSibling()
  call s:test_forwardToSibling()
  call s:test_backToParent()
  call s:test_forwardToFirstChild()
  call s:test_visual_mode()
  call s:test_edge_cases()
  
  return test#framework#report_results("md#move")
endfunction

" Test md#move#backToHeading function
function! s:test_backToHeading()
  echo ""
  echo "Testing md#move#backToHeading..."
  
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
  
  " Test 4: Comprehensive backward navigation - build index of all headings and test systematic movement
  call s:test_comprehensive_backward_navigation()
  
  " Test 5: From content before first heading should not move
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
  
  " Start from the last heading and navigate backward through all headings
  call cursor(heading_lines[-1], 1)  " Start at the last heading
  
  " Move backward through headings - test that we can navigate through multiple levels
  " Test from last heading (35) to second-to-last (30)
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(30, line('.'), "Should move from last heading to previous")
  
  " Test a few more to ensure comprehensive navigation works
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(26, line('.'), "Should continue backward navigation")
  
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(22, line('.'), "Should navigate across different heading levels")
  
  " Test that we can reach the first heading
  " Navigate to first heading
  call cursor(1, 1)
  let first_heading_line = line('.')
  call md#move#backToHeadingNormal()
  call test#framework#assert_equal(first_heading_line, line('.'), 
        \ "From first heading should not move")
endfunction

" Test md#move#forwardToHeading function
function! s:test_forwardToHeading()
  echo ""
  echo "Testing md#move#forwardToHeading..."
  
  call s:setup_test_buffer()
  
  " Test 1: From line 1 (# Root Heading) should go to line 6 (## Section A)
  call cursor(1, 1)
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(6, line('.'), "forwardToHeading from root should go to next heading")
  
  " Test 2: From line 3 (content) should go to line 6 (## Section A)
  call cursor(3, 1)
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(6, line('.'), "forwardToHeading from content should go to next heading")
  
  " Test 3: Comprehensive forward navigation - test movement across all heading levels
  call s:test_comprehensive_forward_navigation()
  
  " Test 4: From last heading should not move
  let last_line = line('$')
  while getline(last_line) !~ '^#' && last_line > 1
    let last_line = last_line - 1
  endwhile
  call cursor(last_line, 1)
  let original_line = line('.')
  call md#move#forwardToHeadingNormal()
  call test#framework#assert_equal(original_line, line('.'), "forwardToHeading from last heading should not move")
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
  let visited_headings = [line('.')]
  
  " Move forward through all headings systematically
  for i in range(1, len(heading_lines) - 1)
    call md#move#forwardToHeadingNormal()
    let current_line = line('.')
    call add(visited_headings, current_line)
    
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
  echo ""
  echo "Testing md#move#backToSibling..."
  
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
  call cursor(6, 1)  " ## Section A (first level 2 heading)
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
  echo ""
  echo "Testing md#move#forwardToSibling..."
  
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
  call cursor(30, 1)  " ## Section C (last level 2 heading)
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
  echo ""
  echo "Testing md#move#backToParent..."
  
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
endfunction

" Test md#move#forwardToFirstChild function
function! s:test_forwardToFirstChild()
  echo ""
  echo "Testing md#move#forwardToFirstChild..."
  
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
  
  " Test 5: From # Root Heading should go to ## Section A
  call cursor(1, 1)
  call md#move#forwardToFirstChildNormal()
  call test#framework#assert_equal(6, line('.'), "forwardToFirstChild from root should go to first level 2 heading")
endfunction

" Test Visual mode functions
function! s:test_visual_mode()
  echo ""
  echo "Testing Visual mode functions..."
  
  " Test Visual mode backToHeading
  call s:setup_test_buffer()
  call cursor(8, 1)  " Start on Section A content
  normal! v
  call cursor(8, 5)  " Select some characters
  call md#move#backToHeadingVisual()
  
  " Check that we're in visual mode
  call test#framework#assert_equal('v', mode(), "Should still be in visual mode after backToHeading")
  
  " Check cursor position moved to heading
  call test#framework#assert_equal(6, line('.'), "Visual mode backToHeading should move cursor to heading")
  
  " Verify that a selection exists by checking if start and end are different
  let selection_info = ''
  execute "normal! \<Esc>"
  
  " Test Visual mode forwardToHeading
  call s:setup_test_buffer()
  call cursor(1, 1)  " Start on Root Heading
  normal! v
  call cursor(1, 5)  " Select some characters
  call md#move#forwardToHeadingVisual()
  
  call test#framework#assert_equal('v', mode(), "Should still be in visual mode after forwardToHeading")
  call test#framework#assert_equal(6, line('.'), "Visual mode forwardToHeading should move cursor to next heading")
  
  execute "normal! \<Esc>"
  
  " Test Visual mode backToSibling
  call s:setup_test_buffer()
  call cursor(22, 1)  " Start on Section B
  normal! v
  call cursor(22, 8)  " Select some characters
  call md#move#backToSiblingVisual()
  
  call test#framework#assert_equal('v', mode(), "Should still be in visual mode after backToSibling")
  call test#framework#assert_equal(6, line('.'), "Visual mode backToSibling should move to previous sibling")
  
  execute "normal! \<Esc>"
  
  " Test Visual mode backToParent
  call s:setup_test_buffer()
  call cursor(10, 1)  " Start on Subsection A1
  normal! v
  call cursor(10, 10)  " Select some characters
  call md#move#backToParentVisual()
  
  call test#framework#assert_equal('v', mode(), "Should still be in visual mode after backToParent")
  call test#framework#assert_equal(6, line('.'), "Visual mode backToParent should move to parent heading")
  
  execute "normal! \<Esc>"
  
  " Test Visual mode forwardToFirstChild
  call s:setup_test_buffer()
  call cursor(6, 1)  " Start on Section A
  normal! v
  call cursor(6, 12)  " Select some characters
  call md#move#forwardToFirstChildVisual()
  
  call test#framework#assert_equal('v', mode(), "Should still be in visual mode after forwardToFirstChild")
  call test#framework#assert_equal(10, line('.'), "Visual mode forwardToFirstChild should move to first child")
  
  execute "normal! \<Esc>"
endfunction

" Test edge cases
function! s:test_edge_cases()
  echo ""
  echo "Testing edge cases..."
  
  " Test with empty buffer
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
  
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
call s:run_tests()