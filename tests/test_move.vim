" Test suite for md#move module functions
" Tests the following functions:
" - md#move#backToHeading
" - md#move#forwardToHeading
" - md#move#backToSibling
" - md#move#backToParent
" - md#move#forwardToFirstChild

" Test framework functions
function! s:assert_equal(expected, actual, message)
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

function! s:setup_test_buffer()
  " Create a new buffer with test markdown content
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  
  " Insert comprehensive test content
  let test_content = [
        \ '# Root Heading',
        \ '',
        \ 'Root content line 1',
        \ 'Root content line 2',
        \ '',
        \ '## Section A',
        \ '',
        \ 'Section A content',
        \ '',
        \ '### Subsection A1',
        \ '',
        \ 'Subsection A1 content',
        \ '',
        \ '#### Deep A1',
        \ '',
        \ 'Deep A1 content',
        \ '',
        \ '### Subsection A2',
        \ '',
        \ 'Subsection A2 content',
        \ '',
        \ '## Section B',
        \ '',
        \ 'Section B content',
        \ '',
        \ '### Subsection B1',
        \ '',
        \ 'Subsection B1 content',
        \ '',
        \ '## Section C',
        \ '',
        \ 'Section C content',
        \ 'More content',
        \ '',
        \ '# Another Root',
        \ '',
        \ 'Another root content'
        \ ]
  
  call setline(1, test_content)
  
  " Load the plugin
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
  
  " Refresh document to build DOM
  call md#dom#refreshDocument()
endfunction

function! s:run_tests()
  let s:test_passes = 0
  let s:test_failures = 0
  
  echo "Running tests for md#move module..."
  echo "=================================="
  
  call s:test_backToHeading()
  call s:test_forwardToHeading()
  call s:test_backToSibling()
  call s:test_backToParent()
  call s:test_forwardToFirstChild()
  call s:test_visual_mode()
  call s:test_edge_cases()
  
  echo ""
  echo "Test Results:"
  echo "============="
  echo "Passes: " . s:test_passes
  echo "Failures: " . s:test_failures
  
  if s:test_failures == 0
    echo "All tests passed!"
  else
    echo "Some tests failed!"
  endif
endfunction

" Test md#move#backToHeading function
function! s:test_backToHeading()
  echo ""
  echo "Testing md#move#backToHeading..."
  
  call s:setup_test_buffer()
  
  " Test 1: From line 8 (Section A content) should go to line 6 (## Section A)
  call cursor(8, 1)
  call md#move#backToHeadingNormal()
  call s:assert_equal(6, line('.'), "backToHeading from content should go to section heading")
  
  " Test 2: From line 6 (## Section A) should go to line 1 (# Root Heading)
  call cursor(6, 1)
  call md#move#backToHeadingNormal()
  call s:assert_equal(1, line('.'), "backToHeading from section should go to previous heading")
  
  " Test 3: From line 1 (first heading) should stay at line 1 (no previous heading)
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "backToHeading from first heading should not move")
  
  " Test 4: From content before first heading should not move
  call s:setup_test_buffer()
  call setline(1, ['Content before any heading', '# First Heading', 'Content'])
  call md#dom#refreshDocument()
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "backToHeading from before first heading should not move")
endfunction

" Test md#move#forwardToHeading function
function! s:test_forwardToHeading()
  echo ""
  echo "Testing md#move#forwardToHeading..."
  
  call s:setup_test_buffer()
  
  " Test 1: From line 1 (# Root Heading) should go to line 6 (## Section A)
  call cursor(1, 1)
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(6, line('.'), "forwardToHeading from root should go to next heading")
  
  " Test 2: From line 3 (content) should go to line 6 (## Section A)
  call cursor(3, 1)
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(6, line('.'), "forwardToHeading from content should go to next heading")
  
  " Test 3: From last heading should not move
  let last_line = line('$')
  while getline(last_line) !~ '^#' && last_line > 1
    let last_line = last_line - 1
  endwhile
  call cursor(last_line, 1)
  let original_line = line('.')
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "forwardToHeading from last heading should not move")
endfunction

" Test md#move#backToSibling function
function! s:test_backToSibling()
  echo ""
  echo "Testing md#move#backToSibling..."
  
  call s:setup_test_buffer()
  
  " Test 1: From ## Section B (line 22) should go to ## Section A (line 6)
  call cursor(22, 1)
  call md#move#backToSiblingNormal()
  call s:assert_equal(6, line('.'), "backToSibling should move to previous sibling")
  
  " Test 2: From ### Subsection A2 (line 18) should go to ### Subsection A1 (line 10)
  call cursor(18, 1)
  call md#move#backToSiblingNormal()
  call s:assert_equal(10, line('.'), "backToSibling should move to previous subsection sibling")
  
  " Test 3: From first sibling should not move
  call cursor(6, 1)  " ## Section A (first level 2 heading)
  let original_line = line('.')
  call md#move#backToSiblingNormal()
  call s:assert_equal(original_line, line('.'), "backToSibling from first sibling should not move")
  
  " Test 4: From content should work based on containing section
  call cursor(24, 1)  " Section B content  
  call md#move#backToSiblingNormal()
  call s:assert_equal(22, line('.'), "backToSibling from content should go to current section heading")
  
  " Test 5: From section with no siblings should not move
  call cursor(14, 1)  " #### Deep A1 (only level 4 heading)
  let original_line = line('.')
  call md#move#backToSiblingNormal()
  call s:assert_equal(original_line, line('.'), "backToSibling with no siblings should not move")
endfunction

" Test md#move#backToParent function
function! s:test_backToParent()
  echo ""
  echo "Testing md#move#backToParent..."
  
  call s:setup_test_buffer()
  
  " Test 1: From ### Subsection A1 (line 10) should go to ## Section A (line 6)
  call cursor(10, 1)
  call md#move#backToParentNormal()
  call s:assert_equal(6, line('.'), "backToParent should move to parent heading")
  
  " Test 2: From #### Deep A1 (line 14) should go to ### Subsection A1 (line 10)
  call cursor(14, 1)
  call md#move#backToParentNormal()
  call s:assert_equal(10, line('.'), "backToParent should move to immediate parent")
  
  " Test 3: From content should go to section heading
  call cursor(12, 1)  " Subsection A1 content
  call md#move#backToParentNormal()
  call s:assert_equal(10, line('.'), "backToParent from content should go to section heading")
  
  " Test 4: From root heading should not move (no parent)
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToParentNormal()
  call s:assert_equal(original_line, line('.'), "backToParent from root heading should not move")
  
  " Test 5: From content under root heading should go to root heading
  call cursor(3, 1)  " Root content line 1
  call md#move#backToParentNormal()
  call s:assert_equal(1, line('.'), "backToParent from root content should go to root heading")
endfunction

" Test md#move#forwardToFirstChild function
function! s:test_forwardToFirstChild()
  echo ""
  echo "Testing md#move#forwardToFirstChild..."
  
  call s:setup_test_buffer()
  
  " Test 1: From ## Section A (line 6) should go to ### Subsection A1 (line 10)
  call cursor(6, 1)
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(10, line('.'), "forwardToFirstChild should move to first child heading")
  
  " Test 2: From ### Subsection A1 (line 10) should go to #### Deep A1 (line 14)
  call cursor(10, 1)
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(14, line('.'), "forwardToFirstChild should move to deeper child")
  
  " Test 3: From heading with no children should not move
  call cursor(14, 1)  " #### Deep A1 (no children)
  let original_line = line('.')
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(original_line, line('.'), "forwardToFirstChild with no children should not move")
  
  " Test 4: From content should work based on containing section
  call cursor(8, 1)  " Section A content
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(10, line('.'), "forwardToFirstChild from content should use containing section")
  
  " Test 5: From # Root Heading should go to ## Section A
  call cursor(1, 1)
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(6, line('.'), "forwardToFirstChild from root should go to first level 2 heading")
endfunction

" Test Visual mode functions
function! s:test_visual_mode()
  echo ""
  echo "Testing Visual mode functions..."
  
  " Test Visual mode backToHeading
  call s:setup_test_buffer()
  call cursor(8, 1)
  normal! v
  call md#move#backToHeadingVisual()
  call s:assert_equal(6, line('.'), "Visual mode backToHeading should work")
  if mode() ==# 'v'
    execute "normal! \<Esc>"
  endif
  
  " Test Visual mode forwardToHeading
  call s:setup_test_buffer()
  call cursor(1, 1)
  normal! v
  call md#move#forwardToHeadingVisual()
  call s:assert_equal(6, line('.'), "Visual mode forwardToHeading should work")
  if mode() ==# 'v'
    execute "normal! \<Esc>"
  endif
  
  " Test Visual mode backToSibling
  call s:setup_test_buffer()
  call cursor(22, 1)
  normal! v
  call md#move#backToSiblingVisual()
  call s:assert_equal(6, line('.'), "Visual mode backToSibling should work")
  if mode() ==# 'v'
    execute "normal! \<Esc>"
  endif
  
  " Test Visual mode backToParent
  call s:setup_test_buffer()
  call cursor(10, 1)
  normal! v
  call md#move#backToParentVisual()
  call s:assert_equal(6, line('.'), "Visual mode backToParent should work")
  if mode() ==# 'v'
    execute "normal! \<Esc>"
  endif
  
  " Test Visual mode forwardToFirstChild
  call s:setup_test_buffer()
  call cursor(6, 1)
  normal! v
  call md#move#forwardToFirstChildVisual()
  call s:assert_equal(10, line('.'), "Visual mode forwardToFirstChild should work")
  if mode() ==# 'v'
    execute "normal! \<Esc>"
  endif
endfunction

" Test edge cases
function! s:test_edge_cases()
  echo ""
  echo "Testing edge cases..."
  
  " Test with empty buffer
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
  call md#dom#refreshDocument()
  
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "Empty buffer: backToHeading should not move")
  
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "Empty buffer: forwardToHeading should not move")
  
  " Test with only content, no headings
  call setline(1, ['Just content', 'More content', 'Even more'])
  call md#dom#refreshDocument()
  
  call cursor(2, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "No headings: backToHeading should not move")
  
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "No headings: forwardToHeading should not move")
  
  call md#move#backToSiblingNormal()
  call s:assert_equal(original_line, line('.'), "No headings: backToSibling should not move")
  
  call md#move#backToParentNormal()
  call s:assert_equal(original_line, line('.'), "No headings: backToParent should not move")
  
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(original_line, line('.'), "No headings: forwardToFirstChild should not move")
  
  " Test with single heading
  call setline(1, ['# Single Heading', 'Content line'])
  call md#dom#refreshDocument()
  
  call cursor(1, 1)
  let original_line = line('.')
  call md#move#backToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "Single heading: backToHeading should not move")
  
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(original_line, line('.'), "Single heading: forwardToHeading should not move")
  
  call md#move#backToSiblingNormal()
  call s:assert_equal(original_line, line('.'), "Single heading: backToSibling should not move")
  
  call md#move#backToParentNormal()
  call s:assert_equal(original_line, line('.'), "Single heading: backToParent should not move")
  
  call md#move#forwardToFirstChildNormal()
  call s:assert_equal(original_line, line('.'), "Single heading: forwardToFirstChild should not move")
  
  " Test underline-style headings
  call setline(1, [
        \ 'Main Heading',
        \ '============',
        \ '',
        \ 'Content here',
        \ '',
        \ 'Sub Heading',
        \ '-----------',
        \ '',
        \ 'More content'
        \ ])
  call md#dom#refreshDocument()
  
  call cursor(4, 1)
  call md#move#backToHeadingNormal()
  call s:assert_equal(1, line('.'), "Underline headings: backToHeading should work")
  
  call cursor(1, 1)
  call md#move#forwardToHeadingNormal()
  call s:assert_equal(6, line('.'), "Underline headings: forwardToHeading should work")
endfunction

" Run all tests
call s:run_tests()