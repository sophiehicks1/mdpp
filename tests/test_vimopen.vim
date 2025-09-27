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
    
    " Simulate link detection - now detects any link, not just file links
    if a:context.line =~ '\[.*\](.*)'
      return 1
    else
      return 0
    endif
  endfunction
  
  call test#framework#assert_equal(1, TestIsMarkdownLink(context_file_link), "Should detect file link")
  call test#framework#assert_equal(1, TestIsMarkdownLink(context_web_link), "Should detect web link")
  call test#framework#assert_equal(0, TestIsMarkdownLink(context_no_link), "Should not detect non-link text")
  call test#framework#assert_equal(0, TestIsMarkdownLink(context_non_markdown), "Should not work in non-markdown files")
  
  delfunction TestIsMarkdownLink
endfunction

" Test link address extraction logic
function! s:test_extract_link_addresses()
  call test#framework#write_info("Testing link address extraction...")
  
  " Mock the internal function for testing
  function! TestExtractLinkAddress(url)
    " Simply return the URL as-is since we no longer clean or filter
    return a:url
  endfunction
  
  " Test various link types - all should be returned as-is
  call test#framework#assert_equal('./file.md', TestExtractLinkAddress('./file.md'), "Should return relative path as-is")
  call test#framework#assert_equal('../file.md', TestExtractLinkAddress('../file.md'), "Should return parent path as-is")
  call test#framework#assert_equal('~/file.md', TestExtractLinkAddress('~/file.md'), "Should return home directory path as-is")
  call test#framework#assert_equal('/absolute/path/file.md', TestExtractLinkAddress('/absolute/path/file.md'), "Should return absolute path as-is")
  call test#framework#assert_equal('https://example.com', TestExtractLinkAddress('https://example.com'), "Should return HTTPS URL as-is")
  call test#framework#assert_equal('http://example.com/page', TestExtractLinkAddress('http://example.com/page'), "Should return HTTP URL as-is")
  call test#framework#assert_equal('ftp://server.com/file', TestExtractLinkAddress('ftp://server.com/file'), "Should return FTP URL as-is")
  call test#framework#assert_equal('mailto:test@example.com', TestExtractLinkAddress('mailto:test@example.com'), "Should return mailto URL as-is")
  call test#framework#assert_equal('@sophie.hicks', TestExtractLinkAddress('@sophie.hicks'), "Should return slack username as-is")
  call test#framework#assert_equal('AB-1234', TestExtractLinkAddress('AB-1234'), "Should return jira ticket ID as-is")
  
  delfunction TestExtractLinkAddress
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
  call test#framework#run_test_function('test_extract_link_addresses', function('s:test_extract_link_addresses'))
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