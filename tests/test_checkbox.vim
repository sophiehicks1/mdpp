" Test cases for checkbox check/uncheck functionality

" Test data file for checkbox tests
let s:test_file = 'checkbox_test.md'

function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file(s:test_file)
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#checkbox module...")
  call test#framework#write_info("======================================")
  call test#framework#write_info("")
  
  call test#framework#run_test_function("test_findCheckboxRange", function('s:test_findCheckboxRange'))
  call test#framework#run_test_function("test_checkCheckbox", function('s:test_checkCheckbox'))
  call test#framework#run_test_function("test_uncheckCheckbox", function('s:test_uncheckCheckbox'))
  call test#framework#run_test_function("test_edge_cases", function('s:test_edge_cases'))
  
  return test#framework#report_results("md#checkbox")
endfunction

" TODO make sure this actually makes sense
" Test md#checkbox#findCheckboxRange function
function! s:test_findCheckboxRange()
  call test#framework#write_info("Testing md#checkbox#findCheckboxRange...")
  call s:setup_test_buffer()
  
  " Test 1: Cursor on checkbox line should find range
  call cursor(5, 1)  " On "- [ ] Basic unchecked item"
  let range = md#checkbox#findCheckboxRange(line('.'))
  call test#framework#assert_not_empty(range, "Should find checkbox range when cursor on checkbox line")
  call test#framework#assert_equal(5, range.start_line, "Should find correct start line")
  call test#framework#assert_equal(5, range.end_line, "Single line checkbox should have same start/end")
  
  " Test 2: Cursor on continuation line should find range
  call cursor(13, 10)  " On continuation line of multi-line checkbox
  let range = md#checkbox#findCheckboxRange(line('.'))
  call test#framework#assert_not_empty(range, "Should find checkbox range when cursor on continuation line")
  call test#framework#assert_equal(12, range.start_line, "Should find correct start line for multi-line checkbox")
  call test#framework#assert_equal(14, range.end_line, "Should find correct end line for multi-line checkbox")
  
  " Test 3: Cursor on non-checkbox line should return empty
  call cursor(9, 1)  " On regular list item
  let range = md#checkbox#findCheckboxRange(line('.'))
  call test#framework#assert_empty(range, "Should return empty range when not in checkbox")
  
  " Test 4: Cursor on nested checkbox
  call cursor(21, 5)  " On nested checkbox line 21
  let range = md#checkbox#findCheckboxRange(line('.'))
  call test#framework#assert_not_empty(range, "Should find nested checkbox range")
  call test#framework#assert_equal(21, range.start_line, "Should find correct nested checkbox start")
endfunction

" TODO make sure this actually makes sense
" Test md#checkbox#checkCheckbox function
function! s:test_checkCheckbox()
  call test#framework#write_info("Testing md#checkbox#checkCheckbox...")
  call s:setup_test_buffer()
  
  " Test 1: Check unchecked single-line checkbox
  call cursor(5, 1)  " On "- [ ] Basic unchecked item"
  call md#checkbox#checkCheckbox(line('.'))
  let line = getline(5)
  call test#framework#assert_true(line =~ '^\s*-\s*\[x\]', "Should check unchecked checkbox")
  
  " Test 2: Check already checked checkbox (should remain checked)
  call cursor(6, 1)  " On already checked item
  let originalLine = getline(6)
  call md#checkbox#checkCheckbox(line('.'))
  let newLine = getline(6)
  call test#framework#assert_equal(substitute(originalLine, '\[[xX]\]', '[x]', ''), newLine, "Should normalize checked checkbox to [x]")
  
  " Test 3: Check multi-line checkbox from continuation line
  call cursor(13, 10)  " On continuation line
  call md#checkbox#checkCheckbox(line('.'))
  let line = getline(12)  " Check the checkbox line itself
  call test#framework#assert_true(line =~ '^\s*-\s*\[x\]', "Should check multi-line checkbox from continuation line")
  
  " Test 4: Attempt to check non-checkbox should do nothing
  call cursor(9, 1)  " On regular list item
  let originalLine = getline(9)
  call md#checkbox#checkCheckbox(line('.'))
  let newLine = getline(9)
  call test#framework#assert_equal(originalLine, newLine, "Should not modify non-checkbox lines")
  
  " Test 5: Check checkbox from different cursor position within item
  call s:setup_test_buffer()
  call cursor(5, 15)  " Middle of checkbox content
  call md#checkbox#checkCheckbox(line('.'))
  let line = getline(5)
  call test#framework#assert_true(line =~ '^\s*-\s*\[x\]', "Should check checkbox from any cursor position within item")
endfunction

" TODO make sure this actually makes sense
" Test md#checkbox#uncheckCheckbox function  
function! s:test_uncheckCheckbox()
  call test#framework#write_info("Testing md#checkbox#uncheckCheckbox...")
  call s:setup_test_buffer()
  
  " Test 1: Uncheck checked single-line checkbox
  call cursor(6, 1)  " On "- [x] Basic checked item"
  call md#checkbox#uncheckCheckbox(line('.'))
  let line = getline(6)
  call test#framework#assert_true(line =~ '^\s*-\s*\[ \]', "Should uncheck checked checkbox")
  
  " Test 2: Uncheck already unchecked checkbox (should remain unchecked)
  call cursor(5, 1)  " On unchecked item
  let originalLine = getline(5)
  call md#checkbox#uncheckCheckbox(line('.'))
  let newLine = getline(5)
  call test#framework#assert_equal(originalLine, newLine, "Should leave unchecked checkbox unchanged")
  
  " Test 3: Uncheck multi-line checkbox from continuation line
  call cursor(16, 8)  " On continuation line of checked multi-line item
  call md#checkbox#uncheckCheckbox(line('.'))
  let line = getline(15)  " Check the checkbox line itself
  call test#framework#assert_true(line =~ '^\s*-\s*\[ \]', "Should uncheck multi-line checkbox from continuation line")
  
  " Test 4: Attempt to uncheck non-checkbox should do nothing
  call cursor(9, 1)  " On regular list item
  let originalLine = getline(9)
  call md#checkbox#uncheckCheckbox(line('.'))
  let newLine = getline(9)
  call test#framework#assert_equal(originalLine, newLine, "Should not modify non-checkbox lines")
  
  " Test 5: Uncheck Capital X checkbox
  call s:setup_test_buffer()
  call cursor(7, 1)  " On "[X]" checkbox
  call md#checkbox#uncheckCheckbox(line('.'))
  let line = getline(7)
  call test#framework#assert_true(line =~ '^\s*-\s*\[ \]', "Should uncheck [X] checkbox")
endfunction

" TODO make sure this actually makes sense
" Test edge cases
function! s:test_edge_cases()
  call test#framework#write_info("Testing edge cases...")
  call s:setup_test_buffer()
  
  " Test 1: Nested checkbox handling
  call cursor(21, 1)  " On nested unchecked item
  call md#checkbox#checkCheckbox(line('.'))
  let line = getline(21)
  call test#framework#assert_true(line =~ '^\s*-\s*\[x\]', "Should handle nested checkboxes")
  
  " Test 2: Capital X checkbox normalization
  call cursor(7, 1)  " On "[X]" checkbox
  call md#checkbox#checkCheckbox(line('.'))
  let line = getline(7)
  call test#framework#assert_true(line =~ '^\s*-\s*\[x\]', "Should normalize [X] to [x]")
  
  " Test 3: Empty buffer
  call test#framework#setup_buffer_from_string("")
  call cursor(1, 1)
  let originalLine = getline(1)
  call md#checkbox#checkCheckbox(line('.'))
  let newLine = getline(1)
  call test#framework#assert_equal(originalLine, newLine, "Should handle empty buffer gracefully")
  
  " Test 4: Buffer with no checkboxes
  call test#framework#setup_buffer_from_string("# Heading\n\nSome text\n- Regular list item")
  call cursor(4, 1)
  let originalLine = getline(4)
  call md#checkbox#checkCheckbox(line('.'))
  let newLine = getline(4)
  call test#framework#assert_equal(originalLine, newLine, "Should not modify non-checkbox content")
endfunction

" Run all tests
" Initialize test framework with results file
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init(g:mdpp_repo_root . '/tests/results.md')
  call s:run_tests()
endif
