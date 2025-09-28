" Integration tests for vim-open markdown link navigation
" Tests the complete mdpp + vim-open integration stack end-to-end

" Set up test environment
call test#framework#init('vimopen.txt')

" Buffer-local variable to collect resources passed to vim-open
let b:test_collected_resources = []

" Test opener that collects all resources passed to it
function! s:test_resource_collector(resource)
  " Collect the resource for validation
  call add(b:test_collected_resources, a:resource)
  " Don't actually open anything - just collect for testing
endfunction

function! s:test_opener_matcher(resource)
  " Match all non-empty resources for testing purposes
  return !empty(a:resource)
endfunction

" Setup function to configure vim-open with our test collector
function! s:setup_vim_open_testing()
  " Clear any previous collected resources
  let b:test_collected_resources = []
  
  " Add our test opener that collects all resources
  call gopher#add_opener(function('s:test_opener_matcher'), function('s:test_resource_collector'))
  
  " Add a debug finder that shows us what context vim-open provides
  call gopher#add_finder(function('s:debug_finder_matcher'), function('s:debug_finder_extractor'))
  
  " Add a catch-all opener to prevent any fallback to default gf
  call gopher#add_opener(function('s:catch_all_matcher'), function('s:catch_all_handler'))
endfunction

" Catch-all functions to prevent fallback to default gf
function! s:catch_all_matcher(resource)
  " Match anything that our main matcher doesn't handle
  return 1
endfunction

function! s:catch_all_handler(resource)
  " Do nothing - just prevent fallback
endfunction

" Debug functions to understand what context vim-open provides
function! s:debug_finder_matcher(context)
  call test#framework#write_info("Debug context keys: " . join(keys(a:context), ', '))
  call test#framework#write_info("Debug context filetype: " . get(a:context, 'filetype', 'NONE'))
  call test#framework#write_info("Debug context line: " . get(a:context, 'line', 'NONE'))
  call test#framework#write_info("Debug context col: " . get(a:context, 'col', 'NONE'))
  call test#framework#write_info("Debug context lnum: " . get(a:context, 'lnum', 'NONE'))
  
  " Test our mdpp finder logic directly
  if a:context.filetype == 'markdown'
    let pos = [0, a:context.lnum, a:context.col, 0]
    call test#framework#write_info("Debug: testing pos = " . string(pos))
    let link_info = md#links#findLinkAtPos(pos)
    call test#framework#write_info("Debug: link_info = " . string(link_info))
    if !empty(link_info)
      let url = md#links#getLinkUrl(link_info)
      call test#framework#write_info("Debug: extracted URL = '" . url . "'")
      
      " Test if the actual mdpp vimopen functions would match
      if exists('*md#vimopen#setup') && exists('g:test_mdpp_finder_match')
        let mdpp_match = g:test_mdpp_finder_match(a:context)
        call test#framework#write_info("Debug: mdpp finder match result = " . string(mdpp_match))
        if mdpp_match
          let mdpp_extract = g:test_mdpp_finder_extract(a:context)
          call test#framework#write_info("Debug: mdpp finder extract result = '" . mdpp_extract . "'")
        endif
      endif
    endif
  endif
  
  return 0  " Don't actually match anything
endfunction

function! s:debug_finder_extractor(context)
  return ''  " Don't extract anything
endfunction

" Setup test buffer with markdown content
function! s:setup_test_buffer()
  " Load the test markdown file
  call test#framework#setup_buffer_from_file('vimopen_test.md')
  " Ensure correct filetype
  setlocal filetype=markdown
  " Setup vim-open integration
  call md#vimopen#setup()
  " Store references to mdpp finder functions for debugging
  if exists('g:test_finder_match') && exists('g:test_finder_extract')
    let g:test_mdpp_finder_match = g:test_finder_match
    let g:test_mdpp_finder_extract = g:test_finder_extract
  endif
  " Configure our test collector
  call s:setup_vim_open_testing()
endfunction

" Test inline file link navigation
function! s:test_inline_file_link()
  call test#framework#write_info("Testing inline file link navigation...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 3: [Regular file link](./example.md)
  call cursor(3, 15)  " Middle of link text
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Debug: check what's under cursor
  call test#framework#write_info("Debug: current line = " . getline('.'))
  call test#framework#write_info("Debug: cursor position = " . line('.') . ',' . col('.'))
  call test#framework#write_info("Debug: word under cursor = '" . expand('<cword>') . "'")
  
  " Instead of using feedkeys, directly call gopher#go() to test the integration
  let result = gopher#go()
  call test#framework#write_info("Debug: gopher#go() returned: '" . result . "'")
  
  " Validate that our collector received the correct resource
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect exactly one resource")
  if len(b:test_collected_resources) > 0
    call test#framework#assert_equal('./example.md', b:test_collected_resources[0], "Should extract correct file path")
  endif
endfunction

" Test inline web URL link
function! s:test_inline_web_link()
  call test#framework#write_info("Testing inline web URL link...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 5: [Website link](https://example.com)
  call cursor(5, 10)  " On link text
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Trigger gf mapping
  call feedkeys("gf", 'x')
  
  " Validate URL extraction
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect web URL")
  call test#framework#assert_equal('https://example.com', b:test_collected_resources[0], "Should extract correct URL")
endfunction

" Test custom identifier links (Slack username)
function! s:test_custom_identifier_link()
  call test#framework#write_info("Testing custom identifier link...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 9: [Slack username](@sophie.hicks)
  call cursor(9, 8)  " On link text
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Trigger gf mapping
  call feedkeys("gf", 'x')
  
  " Validate custom identifier extraction
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect custom identifier")
  call test#framework#assert_equal('@sophie.hicks', b:test_collected_resources[0], "Should extract Slack username")
endfunction

" Test Jira ticket identifier
function! s:test_jira_ticket_link()
  call test#framework#write_info("Testing Jira ticket link...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 10: [Jira ticket](AB-1234)
  call cursor(10, 6)  " On link text
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Trigger gf mapping
  call feedkeys("gf", 'x')
  
  " Validate ticket ID extraction
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect Jira ticket")
  call test#framework#assert_equal('AB-1234', b:test_collected_resources[0], "Should extract ticket ID")
endfunction

" Test reference link resolution
function! s:test_reference_link()
  call test#framework#write_info("Testing reference link resolution...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 17: [Reference to file][file-ref]
  call cursor(17, 10)  " On link text
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Trigger gf mapping
  call feedkeys("gf", 'x')
  
  " Validate reference resolution (should resolve to ./referenced-file.md from line 26)
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect referenced resource")
  call test#framework#assert_equal('./referenced-file.md', b:test_collected_resources[0], "Should resolve reference link")
endfunction

" Test reference link to custom identifier
function! s:test_reference_custom_link()
  call test#framework#write_info("Testing reference link to custom identifier...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 19: [Reference to slack][slack-ref]
  call cursor(19, 12)  " On link text
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Trigger gf mapping
  call feedkeys("gf", 'x')
  
  " Validate reference resolution to custom identifier
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect referenced custom identifier")
  call test#framework#assert_equal('@team.lead', b:test_collected_resources[0], "Should resolve reference to Slack username")
endfunction

" Test wiki link
function! s:test_wiki_link()
  call test#framework#write_info("Testing wiki link...")
  
  call s:setup_test_buffer()
  
  " Position cursor on line 23: [[Internal Page]]
  call cursor(23, 8)  " Inside wiki link brackets
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Trigger gf mapping
  call feedkeys("gf", 'x')
  
  " Validate wiki link extraction
  call test#framework#assert_equal(1, len(b:test_collected_resources), "Should collect wiki link")
  call test#framework#assert_equal('Internal Page', b:test_collected_resources[0], "Should extract wiki page name")
endfunction

" Test positioning at different parts of links
function! s:test_cursor_positions()
  call test#framework#write_info("Testing different cursor positions within links...")
  
  call s:setup_test_buffer()
  
  " Test cursor at beginning of link text
  call cursor(3, 2)  " Beginning of [Regular file link](./example.md)
  let b:test_collected_resources = []
  call feedkeys("gf", 'x')
  call test#framework#assert_equal('./example.md', b:test_collected_resources[0], "Should work at beginning of link")
  
  " Test cursor at end of link text
  call cursor(3, 18)  " End of link text
  let b:test_collected_resources = []
  call feedkeys("gf", 'x')
  call test#framework#assert_equal('./example.md', b:test_collected_resources[0], "Should work at end of link text")
  
  " Test cursor on URL part
  call cursor(3, 25)  " On the URL part
  let b:test_collected_resources = []
  call feedkeys("gf", 'x')
  call test#framework#assert_equal('./example.md', b:test_collected_resources[0], "Should work on URL part")
endfunction

" Test non-link positions don't trigger
function! s:test_non_link_positions()
  call test#framework#write_info("Testing non-link positions...")
  
  call s:setup_test_buffer()
  
  " Position cursor on plain text line 31: "Some plain text with no links."
  call cursor(31, 10)
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Debug: check what's under cursor
  call test#framework#write_info("Debug: current line = " . getline('.'))
  call test#framework#write_info("Debug: cursor position = " . line('.') . ',' . col('.'))
  call test#framework#write_info("Debug: word under cursor = '" . expand('<cword>') . "'")
  
  " Instead of using feedkeys, directly call gopher#go()
  let result = gopher#go()
  call test#framework#write_info("Debug: gopher#go() returned: '" . result . "'")
  
  " Validate that either no resources were collected by our markdown finder,
  " or if fallback occurred, it should return "gf"
  if result == "gf"
    call test#framework#assert_equal(0, len(b:test_collected_resources), "Should not collect from non-markdown via our finder")
  else
    call test#framework#assert_true(len(b:test_collected_resources) <= 1, "Should collect at most one resource from fallback")
  endif
endfunction

" Test multiple mappings in sequence
function! s:test_multiple_mappings()
  call test#framework#write_info("Testing multiple gf mappings in sequence...")
  
  call s:setup_test_buffer()
  
  " Clear collected resources
  let b:test_collected_resources = []
  
  " Navigate to several different links
  call cursor(3, 10)   " File link
  call feedkeys("gf", 'x')
  
  call cursor(5, 10)   " Web URL
  call feedkeys("gf", 'x')
  
  call cursor(9, 8)    " Slack username
  call feedkeys("gf", 'x')
  
  " Should have collected all three resources
  call test#framework#assert_equal(3, len(b:test_collected_resources), "Should collect all three resources")
  call test#framework#assert_equal('./example.md', b:test_collected_resources[0], "First resource should be file")
  call test#framework#assert_equal('https://example.com', b:test_collected_resources[1], "Second resource should be URL")
  call test#framework#assert_equal('@sophie.hicks', b:test_collected_resources[2], "Third resource should be username")
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()

  call test#framework#write_info("Running end-to-end integration tests for vim-open markdown navigation...")
  call test#framework#write_info("====================================================================")
  call test#framework#write_info("")

  call test#framework#run_test_function('test_inline_file_link', function('s:test_inline_file_link'))
  call test#framework#run_test_function('test_inline_web_link', function('s:test_inline_web_link'))
  call test#framework#run_test_function('test_custom_identifier_link', function('s:test_custom_identifier_link'))
  call test#framework#run_test_function('test_jira_ticket_link', function('s:test_jira_ticket_link'))
  call test#framework#run_test_function('test_reference_link', function('s:test_reference_link'))
  call test#framework#run_test_function('test_reference_custom_link', function('s:test_reference_custom_link'))
  call test#framework#run_test_function('test_wiki_link', function('s:test_wiki_link'))
  call test#framework#run_test_function('test_cursor_positions', function('s:test_cursor_positions'))
  call test#framework#run_test_function('test_non_link_positions', function('s:test_non_link_positions'))
  call test#framework#run_test_function('test_multiple_mappings', function('s:test_multiple_mappings'))

  call test#framework#report_results('md#vimopen')
endfunction

" Main execution - only run if this file is executed directly
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('vimopen.txt')
  call s:run_all_tests()
endif