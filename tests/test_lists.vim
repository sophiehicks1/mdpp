"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Test file for md#lists module
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Initialize test framework
call test#framework#init(g:mdpp_repo_root . '/tests/results.md')

" Test data setup function
function! s:setup_list_test_buffer()
  call test#framework#setup_buffer_with_content([
    \ '# List Test',
    \ '',
    \ '## Unordered Lists',
    \ '',
    \ '- First item',
    \ '- Second item',
    \ '  - Nested item',
    \ '',
    \ '## Ordered Lists',
    \ '',
    \ '1. First numbered',
    \ '2. Second numbered',
    \ '   1. Nested numbered',
    \ '',
    \ '## Checkbox Lists',
    \ '',
    \ '- [ ] Unchecked todo',
    \ '- [x] Checked item',
    \ '  - [ ] Nested unchecked',
    \ '',
    \ 'Regular paragraph',
    \ ])
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#lists module...")
  call test#framework#write_info("=====================================")
  
  call s:test_list_context_detection()
  call s:test_new_list_item_generation()
  call s:test_list_continuation_generation()
  call s:test_different_list_markers()
  call s:test_edge_cases()
  
  return test#framework#report_results("md#lists")
endfunction

" Test list context detection
function! s:test_list_context_detection()
  call test#framework#write_info("")
  call test#framework#write_info("Testing list context detection...")
  
  call s:setup_list_test_buffer()
  
  " Test unordered list item
  call cursor(5, 1)  " On "- First item"
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Should detect unordered list context")
  
  " Test ordered list item  
  call cursor(11, 1)  " On "1. First numbered"
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Should detect ordered list context")
  
  " Test checkbox list item
  call cursor(17, 1)  " On "- [ ] Unchecked todo"
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Should detect checkbox list context")
  
  " Test non-list context
  call cursor(21, 1)  " On "Regular paragraph"
  call test#framework#assert_equal(0, md#lists#isInListContext(), "Should not detect list context in regular paragraph")
  
  " Test nested list item
  call cursor(7, 1)  " On "  - Nested item"
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Should detect nested list context")
endfunction

" Test new list item generation
function! s:test_new_list_item_generation()
  call test#framework#write_info("")
  call test#framework#write_info("Testing new list item generation...")
  
  call s:setup_list_test_buffer()
  
  " Test unordered list new item
  call cursor(5, 15)  " End of "- First item"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('- ', newItem, "Should generate unordered list item")
  
  " Test ordered list new item
  call cursor(11, 18)  " End of "1. First numbered"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('2. ', newItem, "Should generate next ordered list item")
  
  " Test checkbox list new item
  call cursor(17, 20)  " End of "- [ ] Unchecked todo"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('- [ ] ', newItem, "Should generate checkbox list item")
  
  " Test nested list item generation
  call cursor(7, 17)  " End of "  - Nested item"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('  - ', newItem, "Should generate nested list item with proper indent")
  
  " Test non-list context
  call cursor(21, 10)  " In "Regular paragraph"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('', newItem, "Should return empty string for non-list context")
endfunction

" Test list continuation generation
function! s:test_list_continuation_generation()
  call test#framework#write_info("")
  call test#framework#write_info("Testing list continuation generation...")
  
  call s:setup_list_test_buffer()
  
  " Test unordered list continuation
  call cursor(5, 15)  " End of "- First item"
  let continuation = md#lists#generateListContinuation()
  call test#framework#assert_equal('  ', continuation, "Should generate unordered list continuation indent")
  
  " Test ordered list continuation
  call cursor(11, 18)  " End of "1. First numbered"
  let continuation = md#lists#generateListContinuation()
  call test#framework#assert_equal('   ', continuation, "Should generate ordered list continuation indent")
  
  " Test checkbox list continuation
  call cursor(17, 20)  " End of "- [ ] Unchecked todo"
  let continuation = md#lists#generateListContinuation()
  call test#framework#assert_equal('      ', continuation, "Should generate checkbox list continuation indent")
  
  " Test nested list continuation
  call cursor(7, 17)  " End of "  - Nested item"
  let continuation = md#lists#generateListContinuation()
  call test#framework#assert_equal('    ', continuation, "Should generate nested list continuation with proper indent")
endfunction

" Test with different list markers
function! s:test_different_list_markers()
  call test#framework#write_info("")
  call test#framework#write_info("Testing different list markers...")
  
  call test#framework#setup_buffer_with_content([
    \ '* Asterisk item',
    \ '- Dash item',
    \ '10. Double digit item',
    \ '- [X] Capital X checkbox',
    \ ])
  
  " Test asterisk marker
  call cursor(1, 15)  " End of "* Asterisk item"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('* ', newItem, "Should generate asterisk list item")
  
  " Test dash marker
  call cursor(2, 12)  " End of "- Dash item"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('- ', newItem, "Should generate dash list item")
  
  " Test double digit ordered
  call cursor(3, 20)  " End of "10. Double digit item"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('11. ', newItem, "Should generate next double digit ordered item")
  
  " Test capital X checkbox
  call cursor(4, 20)  " End of "- [X] Capital X checkbox"
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('- [ ] ', newItem, "Should generate unchecked checkbox from capital X")
endfunction

" Test edge cases
function! s:test_edge_cases()
  call test#framework#write_info("")
  call test#framework#write_info("Testing edge cases...")
  
  " Test empty buffer
  call test#framework#setup_buffer_with_content([''])
  
  call cursor(1, 1)
  call test#framework#assert_equal(0, md#lists#isInListContext(), "Empty buffer should not be in list context")
  
  " Test single line with list item
  call test#framework#setup_buffer_with_content(['- Single item'])
  call cursor(1, 13)
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Single list item should be detected")
  let newItem = md#lists#generateNewListItem()
  call test#framework#assert_equal('- ', newItem, "Should generate new item from single list item")
  
  " Test continuation line detection
  call test#framework#setup_buffer_with_content([
    \ '- List item',
    \ '  continuation line',
    \ '  another continuation',
    \ '',
    \ 'Regular paragraph'
    \ ])
  
  call cursor(2, 10)  " On continuation line
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Continuation line should be in list context")
  
  call cursor(3, 10)  " On another continuation line
  call test#framework#assert_equal(1, md#lists#isInListContext(), "Second continuation line should be in list context")
  
  call cursor(5, 5)  " On regular paragraph
  call test#framework#assert_equal(0, md#lists#isInListContext(), "Regular paragraph should not be in list context")
endfunction

" Run all tests
call s:run_tests()
quit