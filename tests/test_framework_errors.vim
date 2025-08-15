" Test suite to demonstrate the issue with non-existent assert functions
" This test should fail when a non-existent function is called, but currently passes silently

function! s:test_with_invalid_assert()
  call test#framework#write_info("Testing with invalid assert function...")
  
  " This function doesn't exist - should cause an error but currently doesn't
  call test#framework#assert_non_existent(1, 1, "This should fail but doesn't")
  
  " This should pass
  call test#framework#assert_equal(1, 1, "This should pass")
endfunction

function! s:test_with_typo_in_assert()
  call test#framework#write_info("Testing with typo in assert function...")
  
  " This is a typo - should cause an error but currently doesn't  
  call test#framework#assert_equall(2, 2, "This has a typo and should fail but doesn't")
  
  " This should pass
  call test#framework#assert_equal(2, 2, "This should pass")
endfunction

function! s:run_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Testing framework error detection...")
  call test#framework#write_info("====================================")
  
  call s:test_with_invalid_assert()
  call s:test_with_typo_in_assert()
  
  return test#framework#report_results("framework_errors")
endfunction

" Run the test
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init(g:mdpp_repo_root . '/tests/results.md')
  call s:run_tests()
endif