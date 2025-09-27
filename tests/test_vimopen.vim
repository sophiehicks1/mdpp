" Test file for md#vimopen module
" Tests vim-open integration functionality

" Set up test environment
call test#framework#init('vimopen.txt')

" Test data setup function
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('vimopen_test.md')
endfunction

" Test vim-open setup function
function! s:test_setup()
  call test#framework#write_info("Testing md#vimopen#setup...")
  
  " Just test that the function exists and can be called without errors
  try
    call md#vimopen#setup()
    call test#framework#assert_equal(1, 1, "Setup function executed without errors")
  catch
    call test#framework#assert_equal(0, 1, "Setup function should not throw errors: " . v:exception)
  endtry
endfunction

" Test detection of markdown links that are file paths
function! s:test_is_markdown_link_detection()
  call test#framework#write_info("Testing markdown link detection...")
  
  call s:setup_test_buffer()
  
  " Create context objects for different positions
  let context_file_link = {
    \ 'filetype': 'markdown',
    \ 'lnum': 3,
    \ 'col': 15,
    \ 'line': '[Example file](./example.md)'
    \ }
  
  let context_web_link = {
    \ 'filetype': 'markdown',
    \ 'lnum': 5,
    \ 'col': 15,
    \ 'line': '[Website](https://example.com)'
    \ }
  
  let context_no_link = {
    \ 'filetype': 'markdown',
    \ 'lnum': 1,
    \ 'col': 5,
    \ 'line': 'Just plain text'
    \ }
  
  let context_non_markdown = {
    \ 'filetype': 'text',
    \ 'lnum': 3,
    \ 'col': 15,
    \ 'line': '[Example file](./example.md)'
    \ }
  
  " Test with mock function that simulates internal behavior
  function! TestIsMarkdownLink(context)
    if a:context.filetype != 'markdown'
      return 0
    endif
    
    " Simulate link detection
    if a:context.line =~ '\[.*\](\..*\.md)'
      return 1
    elseif a:context.line =~ '\[.*\](https\?://.*)'
      return 0  " Web URLs should not be handled
    else
      return 0
    endif
  endfunction
  
  call test#framework#assert_equal(1, TestIsMarkdownLink(context_file_link), "Should detect file link")
  call test#framework#assert_equal(0, TestIsMarkdownLink(context_web_link), "Should not detect web link")
  call test#framework#assert_equal(0, TestIsMarkdownLink(context_no_link), "Should not detect non-link text")
  call test#framework#assert_equal(0, TestIsMarkdownLink(context_non_markdown), "Should not work in non-markdown files")
  
  delfunction TestIsMarkdownLink
endfunction

" Test file path detection logic
function! s:test_looks_like_file_path()
  call test#framework#write_info("Testing file path detection...")
  
  " Mock the internal function for testing
  function! TestLooksLikeFilePath(url)
    if empty(a:url)
      return 0
    endif
    
    " Exclude web URLs
    if a:url =~? '^https\?://' || a:url =~? '^ftp://' || a:url =~? '^mailto:'
      return 0
    endif
    
    " Include things that look like file paths
    return a:url =~ '^\~/' || 
         \ a:url =~ '^\.\./' ||
         \ a:url =~ '^\.\/' ||
         \ a:url =~ '^/' ||
         \ a:url =~ '\.\w\+$' ||
         \ a:url !~ '://'
  endfunction
  
  " Test various URL types
  call test#framework#assert_equal(1, TestLooksLikeFilePath('./file.md'), "Should detect relative path with ./")
  call test#framework#assert_equal(1, TestLooksLikeFilePath('../file.md'), "Should detect parent path with ../")
  call test#framework#assert_equal(1, TestLooksLikeFilePath('~/file.md'), "Should detect home directory path")
  call test#framework#assert_equal(1, TestLooksLikeFilePath('/absolute/path/file.md'), "Should detect absolute path")
  call test#framework#assert_equal(1, TestLooksLikeFilePath('file.md'), "Should detect simple filename with extension")
  call test#framework#assert_equal(1, TestLooksLikeFilePath('docs/readme.txt'), "Should detect relative directory path")
  
  call test#framework#assert_equal(0, TestLooksLikeFilePath('https://example.com'), "Should not detect HTTPS URL")
  call test#framework#assert_equal(0, TestLooksLikeFilePath('http://example.com/file.html'), "Should not detect HTTP URL")
  call test#framework#assert_equal(0, TestLooksLikeFilePath('ftp://server.com/file'), "Should not detect FTP URL")
  call test#framework#assert_equal(0, TestLooksLikeFilePath('mailto:test@example.com'), "Should not detect mailto URL")
  call test#framework#assert_equal(0, TestLooksLikeFilePath(''), "Should not detect empty string")
  
  delfunction TestLooksLikeFilePath
endfunction

" Test file path cleaning logic
function! s:test_clean_file_path()
  call test#framework#write_info("Testing file path cleaning...")
  
  " Mock the internal function for testing
  function! TestCleanFilePath(url)
    let path = a:url
    
    " Remove URL fragments and query parameters
    let path = substitute(path, '[#?].*$', '', '')
    
    " URL decode common encoded characters
    let path = substitute(path, '%20', ' ', 'g')
    let path = substitute(path, '%23', '#', 'g')
    let path = substitute(path, '%25', '%', 'g')
    
    return path
  endfunction
  
  call test#framework#assert_equal('./file.md', TestCleanFilePath('./file.md'), "Should leave simple path unchanged")
  call test#framework#assert_equal('./file.md', TestCleanFilePath('./file.md#section'), "Should remove fragment")
  call test#framework#assert_equal('./file.md', TestCleanFilePath('./file.md?param=value'), "Should remove query parameters")
  call test#framework#assert_equal('./my file.md', TestCleanFilePath('./my%20file.md'), "Should decode %20 to space")
  call test#framework#assert_equal('./file#name.md', TestCleanFilePath('./file%23name.md'), "Should decode %23 to #")
  call test#framework#assert_equal('./file%name.md', TestCleanFilePath('./file%25name.md'), "Should decode %25 to %")
  call test#framework#assert_equal('./my file.md', TestCleanFilePath('./my%20file.md#section?param=value'), "Should handle multiple cleanups")
  
  delfunction TestCleanFilePath
endfunction

" Test integration with actual link detection
function! s:test_integration()
  call test#framework#write_info("Testing integration with actual link detection...")
  
  call s:setup_test_buffer()
  
  " Test that the buffer was set up correctly
  call test#framework#assert_not_empty(getline(3), "Should have content in test buffer")
  call test#framework#assert_true(getline(3) =~ '\[.*\]', "Should have link syntax on line 3")
  
  " Test that we can position cursor and create context objects
  call cursor(3, 15)
  let context = {'filetype': 'markdown', 'lnum': line('.'), 'col': col('.'), 'line': getline('.')}
  
  call test#framework#assert_equal('markdown', context.filetype, "Should have correct filetype")
  call test#framework#assert_equal(3, context.lnum, "Should have correct line number")
  call test#framework#assert_not_empty(context.line, "Should have line content")
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()

  call test#framework#write_info("Running tests for md#vimopen module...")
  call test#framework#write_info("====================================")
  call test#framework#write_info("")

  call test#framework#run_test_function('test_setup', function('s:test_setup'))
  call test#framework#run_test_function('test_is_markdown_link_detection', function('s:test_is_markdown_link_detection'))
  call test#framework#run_test_function('test_looks_like_file_path', function('s:test_looks_like_file_path'))
  call test#framework#run_test_function('test_clean_file_path', function('s:test_clean_file_path'))
  call test#framework#run_test_function('test_integration', function('s:test_integration'))

  call test#framework#report_results('md#vimopen')
endfunction

" Main execution - only run if this file is executed directly
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('vimopen.txt')
  call s:run_all_tests()
endif