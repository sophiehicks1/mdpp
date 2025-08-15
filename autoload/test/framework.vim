" Generic test framework for mdpp modules
" Provides common assertion functions and test infrastructure

" Test result counters
let s:test_passes = 0
let s:test_failures = 0

" Assertion function
function! test#framework#assert_equal(expected, actual, message)
  if a:expected != a:actual
    echo "FAIL: " . a:message
    echo "Expected: " . string(a:expected)
    echo "Actual: " . string(a:actual)
    let s:test_failures = s:test_failures + 1
  else
    echo "PASS: " . a:message
    let s:test_passes = s:test_passes + 1
  endif
endfunction

" Internal helper function to setup buffer with shared logic
function! s:setup_buffer(content_fn)
  " Create a new buffer
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  
  " Populate content using the provided function
  call a:content_fn()
  
  " Load the plugin
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
endfunction

" Setup a test buffer with content from a markdown file
function! test#framework#setup_buffer_from_file(filename)
  call s:setup_buffer({ -> s:load_content_from_file(a:filename) })
endfunction

" Setup a test buffer with inline content (for cases where a file doesn't make sense)
function! test#framework#setup_buffer_with_content(content_lines)
  call s:setup_buffer({ -> s:load_content_from_lines(a:content_lines) })
endfunction

" Helper function to load content from file
function! s:load_content_from_file(filename)
  " Read content from test data file - resolve relative to repository root
  if !exists('g:mdpp_repo_root')
    echoerr "Test framework error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
    return
  endif
  let test_data_path = g:mdpp_repo_root . '/tests/data/' . a:filename
  if !filereadable(test_data_path)
    echoerr "Test data file not found: " . test_data_path
    return
  endif
  
  " Load content from file
  execute 'silent read ' . fnameescape(test_data_path)
  " Remove the empty first line created by 'read'
  if line('$') > 1 && getline(1) == ''
    1delete
  endif
endfunction

" Helper function to load content from lines
function! s:load_content_from_lines(content_lines)
  " Set the content
  call setline(1, a:content_lines)
endfunction

" Report test results
function! test#framework#report_results(module_name)
  echo ""
  echo "Test Results for " . a:module_name . ":"
  echo "============="
  echo "Passes: " . s:test_passes
  echo "Failures: " . s:test_failures
  
  if s:test_failures == 0
    echo "All tests passed!"
    return 0
  else
    echo "Some tests failed!"
    return 1
  endif
endfunction

" Reset test counters
function! test#framework#reset()
  let s:test_passes = 0
  let s:test_failures = 0
endfunction

" Get current test counts (for reporting progress)
function! test#framework#get_counts()
  return {'passes': s:test_passes, 'failures': s:test_failures}
endfunction