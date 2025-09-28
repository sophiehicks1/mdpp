" Integration tests for vim-open markdown link navigation
" Tests the complete mdpp + vim-open integration stack end-to-end

" Set up test environment
call test#framework#init('vimopen.txt')

" Global variables to capture test results
let g:test_collected_resources = []
let g:test_opener_called = 0

" Test opener that collects resources for validation
function! s:test_resource_collector(resource)
  call add(g:test_collected_resources, a:resource)
  let g:test_opener_called = 1
  " Don't actually open - just collect for testing
endfunction

function! s:test_resource_matcher(resource)
  " Match all resources for testing
  return 1
endfunction

" Setup test buffer with markdown content
function! s:setup_test_buffer()
  " Load the test markdown file
  call test#framework#setup_buffer_from_file('vimopen_test.md')
  " Ensure correct filetype
  setlocal filetype=markdown
  " Setup vim-open integration
  call md#vimopen#setup()
  
  " Reset test state
  let g:test_collected_resources = []
  let g:test_opener_called = 0
  
  " Add our test opener to vim-open
  call gopher#add_opener(function('s:test_resource_matcher'), function('s:test_resource_collector'))
endfunction

" Test file link extraction
function! s:test_file_link()
  call test#framework#write_info("Testing file link extraction...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 3: [Regular file link](./example.md)
  call cursor(3, 15)
  
  " Use gopher#go() directly to test vim-open integration
  let result = gopher#go()
  
  " Should have collected the resource and not fallen back
  call test#framework#assert_false(result == "gf", "Should not fall back to default gf")
  call test#framework#assert_equal(1, g:test_opener_called, "Should call opener")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect one resource")
  call test#framework#assert_equal('./example.md', g:test_collected_resources[0], "Should extract file path")
endfunction

" Test web URL extraction
function! s:test_web_url()
  call test#framework#write_info("Testing web URL extraction...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 5: [Website link](https://example.com)
  call cursor(5, 12)
  
  let result = gopher#go()
  
  call test#framework#assert_false(result == "gf", "Should not fall back to default gf")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect web URL")
  call test#framework#assert_equal('https://example.com', g:test_collected_resources[0], "Should extract URL")
endfunction

" Test custom identifier (Slack username)
function! s:test_slack_username()
  call test#framework#write_info("Testing Slack username extraction...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 9: [Slack username](@sophie.hicks)
  call cursor(9, 10)
  
  let result = gopher#go()
  
  call test#framework#assert_false(result == "gf", "Should not fall back to default gf")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect username")
  call test#framework#assert_equal('@sophie.hicks', g:test_collected_resources[0], "Should extract username")
endfunction

" Test Jira ticket ID
function! s:test_jira_ticket()
  call test#framework#write_info("Testing Jira ticket extraction...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 10: [Jira ticket](AB-1234)
  call cursor(10, 8)
  
  let result = gopher#go()
  
  call test#framework#assert_false(result == "gf", "Should not fall back to default gf")  
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect ticket ID")
  call test#framework#assert_equal('AB-1234', g:test_collected_resources[0], "Should extract ticket ID")
endfunction

" Test reference link resolution
function! s:test_reference_link()
  call test#framework#write_info("Testing reference link resolution...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 17: [Reference to file][file-ref]
  call cursor(17, 12)
  
  let result = gopher#go()
  
  call test#framework#assert_false(result == "gf", "Should not fall back to default gf")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect reference")
  call test#framework#assert_equal('./referenced-file.md', g:test_collected_resources[0], "Should resolve reference")
endfunction

" Test wiki link
function! s:test_wiki_link()
  call test#framework#write_info("Testing wiki link extraction...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 23: [[Internal Page]]
  call cursor(23, 8)
  
  let result = gopher#go()
  
  call test#framework#assert_false(result == "gf", "Should not fall back to default gf")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect wiki link")
  call test#framework#assert_equal('Internal Page', g:test_collected_resources[0], "Should extract wiki page")
endfunction

" Test non-link positions fallback correctly  
function! s:test_non_link_fallback()
  call test#framework#write_info("Testing non-link position fallback...")
  
  call s:setup_test_buffer()
  
  " Position cursor on plain text line 31
  call cursor(31, 10)
  
  let result = gopher#go()
  
  " Should fall back to default gf when no markdown link found
  call test#framework#assert_equal("gf", result, "Should fall back to default gf for non-links")
  call test#framework#assert_equal(0, len(g:test_collected_resources), "Should not collect from plain text")
endfunction

" Test gf mapping with feedkeys (end-to-end)
function! s:test_feedkeys_gf_mapping()
  call test#framework#write_info("Testing gf mapping with feedkeys...")
  
  call s:setup_test_buffer()
  
  " Position on a file link
  call cursor(3, 15)
  
  " Use feedkeys with 'x' flag to execute immediately without waiting for input
  " We'll catch any errors that would occur from actual file opening
  try
    call feedkeys("gf", 'x')
    " If we get here without error, vim-open handled it successfully
    call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect resource via feedkeys")
    call test#framework#assert_equal('./example.md', g:test_collected_resources[0], "Should extract correct path via feedkeys")
  catch /E447.*Can't find file/
    " This error means vim-open fell back to default gf, which is actually expected
    " if no opener claims the resource. The important thing is our finder worked.
    call test#framework#assert_equal(1, len(g:test_collected_resources), "Should still collect resource even if opener not found")
  endtry
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()

  call test#framework#write_info("Running end-to-end vim-open integration tests...")
  call test#framework#write_info("============================================")
  call test#framework#write_info("")

  call test#framework#run_test_function('test_file_link', function('s:test_file_link'))
  call test#framework#run_test_function('test_web_url', function('s:test_web_url'))
  call test#framework#run_test_function('test_slack_username', function('s:test_slack_username'))
  call test#framework#run_test_function('test_jira_ticket', function('s:test_jira_ticket'))
  call test#framework#run_test_function('test_reference_link', function('s:test_reference_link'))
  call test#framework#run_test_function('test_wiki_link', function('s:test_wiki_link'))
  call test#framework#run_test_function('test_non_link_fallback', function('s:test_non_link_fallback'))
  call test#framework#run_test_function('test_feedkeys_gf_mapping', function('s:test_feedkeys_gf_mapping'))

  call test#framework#report_results('md#vimopen')
endfunction

" Main execution
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('vimopen.txt')
  call s:run_all_tests()
endif