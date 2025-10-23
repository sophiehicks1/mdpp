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

  " Add our test opener to vim-open (will be checked first due to order)
  call gopher#add_opener(function('s:test_resource_matcher'), function('s:test_resource_collector'))
endfunction

" Test that vim-open detection works correctly
function! s:test_vim_open_detection()
  call test#framework#write_info("Testing vim-open detection...")

  " The test environment should have vim-open loaded
  call test#framework#assert_true(exists('g:loaded_vim_open'), "Should detect vim-open via g:loaded_vim_open")
  call test#framework#assert_equal(1, g:loaded_vim_open, "vim-open should be loaded")

  " Test that setup function works when vim-open is available
  try
    call md#vimopen#setup()
    call test#framework#assert_true(1, "Setup should work when vim-open is available")
  catch
    call test#framework#assert_true(0, "Setup should not throw errors when vim-open is available: " . v:exception)
  endtry
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
  call test#framework#assert_equal(1, g:test_opener_called, "Should call opener")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect one resource")
  call test#framework#assert_equal('./example.md', g:test_collected_resources[0], "Should extract file path")
endfunction

" Test web target extraction
function! s:test_web_url()
  call test#framework#write_info("Testing web URL extraction...")

  call s:setup_test_buffer()

  " Position cursor on line 5: [Website link](https://example.com)
  call cursor(5, 12)

  let result = gopher#go()

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

  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect username")
  call test#framework#assert_equal('@sophie.hicks', g:test_collected_resources[0], "Should extract username")
endfunction

function! s:test_wiki_link_defaults()
  call test#framework#write_info("Testing wiki link syntax with defaults...")

  call s:setup_test_buffer()

  " Position cursor on the first wiki style link
  call cursor(23, 3)
  call gopher#go()
  call cursor(24, 3)
  call gopher#go()

  call test#framework#assert_equal(1, g:test_opener_called, "Should call opener")
  call test#framework#assert_equal(2, len(g:test_collected_resources), "Should collect one resource")
  call test#framework#assert_equal('./Internal Page.md', g:test_collected_resources[0], "Should use default resolver")
  call test#framework#assert_equal('./docs/another-page.md', g:test_collected_resources[1], "Should use default resolver")
endfunction

function! s:custom_resolver(string)
  return '~/Documents/Stuff/' . a:string . '.md'
endfunction

function! s:test_custom_wiki_link_resolver()
  call test#framework#write_info("Testing wiki link syntax with custom resolver...")

  let g:Mdpp_wiki_resolver = function('s:custom_resolver')

  call s:setup_test_buffer()

  " Position cursor on the first wiki style link
  call cursor(23, 3)
  call gopher#go()
  call cursor(24, 3)
  call gopher#go()

  unlet g:Mdpp_wiki_resolver

  call test#framework#assert_equal(1, g:test_opener_called, "Should call opener")
  call test#framework#assert_equal(2, len(g:test_collected_resources), "Should collect one resource")
  call test#framework#assert_equal('~/Documents/Stuff/Internal Page.md', g:test_collected_resources[0], 
        \ "Should use custom resolver")
  call test#framework#assert_equal('~/Documents/Stuff/docs/another-page.md', g:test_collected_resources[1],
        \ "Should use custom resolver")
endfunction

" Test Jira ticket ID
function! s:test_jira_ticket()
  call test#framework#write_info("Testing Jira ticket extraction...")

  call s:setup_test_buffer()

  " Position cursor on line 10: [Jira ticket](AB-1234)
  call cursor(10, 8)

  let result = gopher#go()

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

  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect reference")
  call test#framework#assert_equal('./referenced-file.md', g:test_collected_resources[0], "Should resolve reference")
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

" Test for Bug #48: multi-line link support breaks with indentation
" This test follows the exact reproduction steps from the bug report
function! s:test_bug_48_indented_wrapped_link()
  call test#framework#write_info("Testing Bug #48: indented wrapped link...")

  " Create a buffer with the exact content from the bug report
  new
  call setline(1, '- This is a root list item')
  call setline(2, '  * This is a modestly long nested list item that ends with a [[relatively short')
  call setline(3, '    link]]')
  
  " Save to a temporary file so vim-open can resolve relative paths
  let temp_file = tempname() . '.md'
  execute 'write ' . temp_file
  setlocal filetype=markdown
  
  " Set up vim-open integration
  call md#vimopen#setup()
  
  " Reset test state
  let g:test_collected_resources = []
  let g:test_opener_called = 0
  
  " Place cursor as specified in bug report: "at the end of the nested list item, 
  " inside the [[relatively short link]] text"
  " This means cursor should be inside the link, let's test line 3, column 8 (inside "link")
  call cursor(3, 8)
  
  " Invoke vim-open using gopher#go() as specified
  let result = gopher#go()
  
  " Check that the correct resource was collected
  call test#framework#assert_equal(1, g:test_opener_called, "Should call opener for wrapped link")
  call test#framework#assert_equal(1, len(g:test_collected_resources), "Should collect one resource")
  
  " The critical assertion: the link text should be "relatively short link" (single space)
  " not "relatively short    link" (with extra indentation spaces)
  let expected_resource = './relatively short link.md'
  call test#framework#assert_equal(expected_resource, g:test_collected_resources[0], 
        \ "Should extract link without indentation spaces (Bug #48)")
  
  " Clean up
  bdelete!
  call delete(temp_file)
  
  " Also test with cursor on line 2 (first line of the link)
  new
  call setline(1, '- This is a root list item')
  call setline(2, '  * This is a modestly long nested list item that ends with a [[relatively short')
  call setline(3, '    link]]')
  execute 'write ' . temp_file
  setlocal filetype=markdown
  
  let g:test_collected_resources = []
  let g:test_opener_called = 0
  
  call cursor(2, 85)  " Inside "short" on line 2
  let result = gopher#go()
  
  call test#framework#assert_equal(1, g:test_opener_called, "Should call opener from line 2")
  call test#framework#assert_equal(expected_resource, g:test_collected_resources[0],
        \ "Should extract link correctly from line 2 (Bug #48)")
  
  bdelete!
  call delete(temp_file)
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()

  call test#framework#write_info("Running end-to-end vim-open integration tests...")
  call test#framework#write_info("============================================")
  call test#framework#write_info("")

  call test#framework#run_test_function('test_vim_open_detection', function('s:test_vim_open_detection'))
  call test#framework#run_test_function('test_file_link', function('s:test_file_link'))
  call test#framework#run_test_function('test_web_url', function('s:test_web_url'))
  call test#framework#run_test_function('test_slack_username', function('s:test_slack_username'))
  call test#framework#run_test_function('test_jira_ticket', function('s:test_jira_ticket'))
  call test#framework#run_test_function('test_reference_link', function('s:test_reference_link'))
  call test#framework#run_test_function('test_feedkeys_gf_mapping', function('s:test_feedkeys_gf_mapping'))
  call test#framework#run_test_function('test_wiki_link_defaults', function('s:test_wiki_link_defaults'))
  call test#framework#run_test_function('test_custom_wiki_link_resolver',
        \ function('s:test_custom_wiki_link_resolver'))
  call test#framework#run_test_function('test_bug_48_indented_wrapped_link',
        \ function('s:test_bug_48_indented_wrapped_link'))

  call test#framework#report_results('md#vimopen')
endfunction

" Main execution
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('vimopen.txt')
  call s:run_all_tests()
endif
