" Integration tests for wikilink autocomplete functionality
" Tests the complete mdpp autocomplete integration

" Set up test environment
call test#framework#init('autocomplete.txt')

" Global variables to capture test results
let g:test_completions = []

" Test completion function that captures results
function! s:test_completion_function(text)
  call add(g:test_completions, 'called with: ' . a:text)
  return ['test-page1', 'test-page2', 'subdir/page3']
endfunction

" Setup test buffer with markdown content
function! s:setup_test_buffer()
  " Load a simple markdown file
  call test#framework#setup_buffer_with_content([
        \ '# Test Document',
        \ '',
        \ 'Some text here.',
        \ '',
        \ 'Testing autocomplete: [[',
        \ '',
        \ 'More text follows.'
        \ ])
  
  " Ensure correct filetype
  setlocal filetype=markdown
  
  " Reset test state
  let g:test_completions = []
endfunction

" Test that autocomplete is enabled when vim-open is available
function! s:test_autocomplete_enabled_with_vim_open()
  call test#framework#write_info("Testing autocomplete enabled with vim-open...")
  
  let g:loaded_vim_open = 1
  unlet! g:mdpp_wikilink_autocomplete
  
  call test#framework#assert_equal(1, md#autocomplete#isEnabled(), "Should be enabled when vim-open is available")
  
  unlet g:loaded_vim_open
endfunction

" Test that autocomplete is disabled when vim-open is not available
function! s:test_autocomplete_disabled_without_vim_open()
  call test#framework#write_info("Testing autocomplete disabled without vim-open...")
  
  unlet! g:loaded_vim_open
  unlet! g:mdpp_wikilink_autocomplete
  
  call test#framework#assert_equal(0, md#autocomplete#isEnabled(), "Should be disabled when vim-open is not available")
endfunction

" Test explicit configuration override
function! s:test_autocomplete_explicit_config()
  call test#framework#write_info("Testing explicit configuration override...")
  
  let g:loaded_vim_open = 1
  let g:mdpp_wikilink_autocomplete = 0
  
  call test#framework#assert_equal(0, md#autocomplete#isEnabled(), "Should respect explicit disable")
  
  let g:mdpp_wikilink_autocomplete = 1
  call test#framework#assert_equal(1, md#autocomplete#isEnabled(), "Should respect explicit enable")
  
  unlet g:loaded_vim_open
  unlet g:mdpp_wikilink_autocomplete
endfunction

" Test default completion function
function! s:test_default_completion()
  call test#framework#write_info("Testing default completion function...")
  
  " Create test files in a temporary directory
  let test_dir = '/tmp/completion-test'
  call system('mkdir -p ' . test_dir)
  call system('touch ' . test_dir . '/page1.md')
  call system('touch ' . test_dir . '/page2.md') 
  call system('mkdir -p ' . test_dir . '/docs')
  call system('touch ' . test_dir . '/docs/readme.md')
  
  " Change to test directory
  let old_cwd = getcwd()
  execute 'cd ' . test_dir
  
  try
    " Test completion with empty text
    let completions = md#autocomplete#complete(0, '')
    call test#framework#assert_true(len(completions) >= 2, "Should find markdown files")
    call test#framework#assert_true(index(completions, 'page1') >= 0, "Should include page1")
    call test#framework#assert_true(index(completions, 'page2') >= 0, "Should include page2")
    
    " Test completion with prefix
    let completions = md#autocomplete#complete(0, 'page')
    call test#framework#assert_true(len(completions) >= 2, "Should find matching files")
    call test#framework#assert_true(index(completions, 'page1') >= 0, "Should match page1")
    call test#framework#assert_true(index(completions, 'page2') >= 0, "Should match page2")
    
  finally
    " Restore directory and cleanup
    execute 'cd ' . old_cwd
    call system('rm -rf ' . test_dir)
  endtry
endfunction

" Test custom completion function
function! s:test_custom_completion_function()
  call test#framework#write_info("Testing custom completion function...")
  
  let g:Mdpp_wikilink_completion_fn = function('s:test_completion_function')
  
  call s:setup_test_buffer()
  
  " Test completion
  let completions = md#autocomplete#complete(0, 'test')
  
  call test#framework#assert_equal(1, len(g:test_completions), "Should call custom function")
  call test#framework#assert_equal('called with: test', g:test_completions[0], "Should pass correct text")
  call test#framework#assert_equal(['test-page1', 'test-page2', 'subdir/page3'], completions, "Should return custom completions")
  
  unlet g:Mdpp_wikilink_completion_fn
endfunction

" Test findstart functionality
function! s:test_completion_findstart()
  call test#framework#write_info("Testing completion findstart...")
  
  call s:setup_test_buffer()
  
  " Position cursor after [[  
  call cursor(5, 25)  " One position after the [[
  
  " Test findstart
  let start_pos = md#autocomplete#complete(1, '')
  call test#framework#assert_equal(25, start_pos, "Should find correct start position after [[")
  
  " Test with content after [[
  call setline(5, 'Testing autocomplete: [[page')
  call cursor(5, 29)  " After "page"
  
  let start_pos = md#autocomplete#complete(1, '')
  call test#framework#assert_equal(25, start_pos, "Should find start position after [[ with content")
endfunction

" Test findstart edge cases
function! s:test_completion_findstart_edge_cases()
  call test#framework#write_info("Testing completion findstart edge cases...")
  
  call test#framework#setup_buffer_with_content([
        \ 'No wikilink here',
        \ 'Single bracket [only',
        \ 'Regular link [text](url)',
        \ 'Incomplete [[ but then ] another bracket'
        \ ])
  
  " Test with no [[ found
  call cursor(1, 5)
  let result = md#autocomplete#complete(1, '')
  call test#framework#assert_equal(-1, result, "Should return -1 when no [[ found")
  
  " Test with single bracket
  call cursor(2, 15)
  let result = md#autocomplete#complete(1, '')
  call test#framework#assert_equal(-1, result, "Should return -1 for single bracket")
  
  " Test with regular link
  call cursor(3, 12)
  let result = md#autocomplete#complete(1, '')
  call test#framework#assert_equal(-1, result, "Should return -1 inside regular link")
endfunction

" Test trigger completion function
function! s:test_trigger_completion()
  call test#framework#write_info("Testing trigger completion function...")
  
  " Test when disabled
  unlet! g:loaded_vim_open
  unlet! g:mdpp_wikilink_autocomplete
  
  let result = md#autocomplete#triggerCompletion()
  call test#framework#assert_equal('[[', result, "Should just return [[ when disabled")
  
  " Test when enabled
  let g:loaded_vim_open = 1
  
  let result = md#autocomplete#triggerCompletion()
  " Check that it contains the control characters (they may display differently)
  call test#framework#assert_true(result =~ '^\[\[', "Should start with [[")
  call test#framework#assert_true(len(result) > 2, "Should contain completion trigger when enabled")
  
  unlet g:loaded_vim_open
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running wikilink autocomplete tests...")
  call test#framework#write_info("===========================================")
  call test#framework#write_info("")
  
  call test#framework#run_test_function('test_autocomplete_enabled_with_vim_open', function('s:test_autocomplete_enabled_with_vim_open'))
  call test#framework#run_test_function('test_autocomplete_disabled_without_vim_open', function('s:test_autocomplete_disabled_without_vim_open'))
  call test#framework#run_test_function('test_autocomplete_explicit_config', function('s:test_autocomplete_explicit_config'))
  call test#framework#run_test_function('test_default_completion', function('s:test_default_completion'))
  call test#framework#run_test_function('test_custom_completion_function', function('s:test_custom_completion_function'))
  call test#framework#run_test_function('test_completion_findstart', function('s:test_completion_findstart'))
  call test#framework#run_test_function('test_completion_findstart_edge_cases', function('s:test_completion_findstart_edge_cases'))
  call test#framework#run_test_function('test_trigger_completion', function('s:test_trigger_completion'))
  
  call test#framework#report_results('md#autocomplete')
endfunction

" Main execution
if !exists('g:mdpp_repo_root')
  echoerr "Test error: g:mdpp_repo_root not set. Please run tests via run_tests.sh"
else
  call test#framework#init('autocomplete.txt')
  call s:run_all_tests()
endif