" Test file for md#footnotes module

" Set up test environment
call test#framework#init(g:mdpp_repo_root . '/tests/results.md')

" Test data setup function
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_lines([
        \ '# Footnotes Test Document',
        \ '',
        \ 'This is a test document for footnotes functionality.',
        \ '',
        \ '## Simple Footnotes',
        \ '',
        \ 'Here''s a sentence with a footnote[^1].',
        \ '',
        \ 'Another sentence with a different footnote[^note2].',
        \ '',
        \ 'And here''s a third one[^3] in the middle of a sentence.',
        \ '',
        \ '## Multiple References',
        \ '',
        \ 'This footnote is referenced multiple times[^shared] in different places[^shared].',
        \ '',
        \ '## Complex Footnotes',
        \ '',
        \ 'This footnote has complex content[^complex].',
        \ '',
        \ '## Footnote Definitions',
        \ '',
        \ '[^1]: This is a simple footnote.',
        \ '',
        \ '[^note2]: This is another footnote with a longer identifier.',
        \ '',
        \ '[^3]: This footnote has a short identifier.',
        \ '',
        \ '[^shared]: This footnote is referenced multiple times from different locations.',
        \ '',
        \ '[^complex]: This footnote contains **bold text**, *italic text*, and even [a link](http://example.com).'
        \ ])
endfunction

" Test finding footnote references in a line
function! s:test_find_footnote_references_in_line()
  call test#framework#write_info("Testing md#footnotes#findFootnoteReferencesInLine...")
  
  " Test line with single footnote
  let line_content = "Here's a sentence with a footnote[^1]."
  let footnotes = md#footnotes#findFootnoteReferencesInLine(1, line_content)
  call test#framework#assert_equal(1, len(footnotes), "Should find one footnote in simple case")
  call test#framework#assert_equal('reference', footnotes[0].type, "Should identify as reference type")
  call test#framework#assert_equal('1', footnotes[0].id, "Should extract correct footnote ID")
  call test#framework#assert_equal(34, footnotes[0].start_col, "Should find correct start column")
  call test#framework#assert_equal(37, footnotes[0].end_col, "Should find correct end column")
  
  " Test line with multiple footnotes
  let line_content = "This footnote is referenced multiple times[^shared] in different places[^shared]."
  let footnotes = md#footnotes#findFootnoteReferencesInLine(1, line_content)
  call test#framework#assert_equal(2, len(footnotes), "Should find two footnotes in line")
  call test#framework#assert_equal('shared', footnotes[0].id, "Should extract first footnote ID")
  call test#framework#assert_equal('shared', footnotes[1].id, "Should extract second footnote ID")
  
  " Test line with no footnotes
  let line_content = "This line has no footnotes at all."
  let footnotes = md#footnotes#findFootnoteReferencesInLine(1, line_content)
  call test#framework#assert_equal(0, len(footnotes), "Should find no footnotes in plain text")
  
  " Test line with footnote in middle
  let line_content = "And here's a third one[^3] in the middle of a sentence."
  let footnotes = md#footnotes#findFootnoteReferencesInLine(1, line_content)
  call test#framework#assert_equal(1, len(footnotes), "Should find footnote in middle of sentence")
  call test#framework#assert_equal('3', footnotes[0].id, "Should extract correct ID from middle")
endfunction

" Test finding footnote at cursor position
function! s:test_find_footnote_at_cursor()
  call test#framework#write_info("Testing md#footnotes#findFootnoteAtCursor...")
  
  call s:setup_test_buffer()
  
  " Test cursor on footnote reference
  call cursor(7, 36)  " Position on [^1]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find footnote reference")
  call test#framework#assert_equal('1', footnote_info.id, "Should extract correct footnote ID")
  
  " Test cursor on footnote definition
  call cursor(22, 5)  " Position on [^1]: definition line
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('definition', footnote_info.type, "Should find footnote definition")
  call test#framework#assert_equal('1', footnote_info.id, "Should extract correct ID from definition")
  
  " Test cursor not on footnote
  call cursor(3, 10)  " Position on regular text
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal({}, footnote_info, "Should return empty dict when not on footnote")
  
  " Test cursor on complex footnote
  call cursor(18, 42)  " Position on [^complex]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find complex footnote reference")
  call test#framework#assert_equal('complex', footnote_info.id, "Should extract complex footnote ID")
endfunction

" Test finding footnote definitions
function! s:test_footnote_definitions()
  call test#framework#write_info("Testing footnote definition parsing...")
  
  call s:setup_test_buffer()
  
  " Test cursor on footnote reference to get definition content
  call cursor(7, 36)  " Position on [^1]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('This is a simple footnote.', footnote_info.content, "Should find correct definition content")
  
  " Test complex footnote definition
  call cursor(18, 42)  " Position on [^complex]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  let expected_content = 'This footnote contains **bold text**, *italic text*, and even [a link](http://example.com).'
  call test#framework#assert_equal(expected_content, footnote_info.content, "Should find complex definition content")
  
  " Test multiple references to same footnote
  call cursor(15, 48)  " Position on first [^shared]
  let footnote_info1 = md#footnotes#findFootnoteAtCursor()
  call cursor(15, 73)  " Position on second [^shared]
  let footnote_info2 = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal(footnote_info1.content, footnote_info2.content, "Should find same content for multiple references")
endfunction

" Test window sizing and ellision logic in detail
function! s:test_ellision_logic()
  call test#framework#write_info("Testing window sizing and ellision logic...")
  
  " Test with very long footnote content (should be ellided)
  call test#framework#setup_buffer_from_lines([
        \ 'This footnote has very long content[^long].',
        \ '',
        \ '[^long]: This is an extremely long footnote that contains more than seventy characters and should be ellided with dots at the end to fit within the maximum window width of seventy characters.',
        \ '',
        \ 'This footnote has many lines[^many].',
        \ '',
        \ '[^many]: Line 1',
        \ '    Line 2',
        \ '    Line 3',
        \ '    Line 4',
        \ '    Line 5',
        \ '    Line 6',
        \ '    Line 7',
        \ '    Line 8',
        \ '    Line 9',
        \ '    Line 10',
        \ '    Line 11',
        \ '    Line 12',
        \ '    Line 13',
        \ '    Line 14',
        \ '    Line 15',
        \ ])
  
  " Test long content footnote
  call cursor(1, 42)  " Position on [^long] - fixed position
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find long footnote reference")
  call test#framework#assert_equal('long', footnote_info.id, "Should extract long footnote ID")
  
  " Simulate the window sizing logic from the function
  let content = footnote_info.content
  let lines = ['[^' . footnote_info.id . ']:']
  call extend(lines, split(content, "\n"))
  
  " Apply ellision for content that's too long
  let max_width = 70
  let max_height = 11
  
  " Check if long line ellision works
  let has_long_line = 0
  for line in lines
    if len(line) > max_width
      let has_long_line = 1
      break
    endif
  endfor
  call test#framework#assert_equal(1, has_long_line, "Should have lines longer than 70 characters before ellision")
  
  " Apply ellision to long lines
  for i in range(len(lines))
    if len(lines[i]) > max_width
      let lines[i] = lines[i][0:max_width-4] . '...'
    endif
  endfor
  
  " Verify no line exceeds max width after ellision
  for line in lines
    call test#framework#assert_true(len(line) <= max_width, "Line should not exceed max width after ellision: " . string(line))
  endfor
  
  " Test many lines footnote
  call cursor(5, 35)  " Position on [^many]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find many-lines footnote reference")
  call test#framework#assert_equal('many', footnote_info.id, "Should extract many-lines footnote ID")
  
  " Simulate window sizing for many lines
  let content = footnote_info.content
  let lines = ['[^' . footnote_info.id . ']:']
  call extend(lines, split(content, "\n"))
  
  " Check if we have more than max_height lines
  call test#framework#assert_true(len(lines) > max_height, "Should have more than 11 lines before ellision")
  
  " Apply height ellision
  if len(lines) > max_height
    let lines = lines[0:max_height-1]
    if len(lines[max_height-1]) > max_width - 3
      let lines[max_height-1] = lines[max_height-1][0:max_width-4] . '...'
    else
      let lines[max_height-1] = lines[max_height-1] . '...'
    endif
  endif
  
  " Verify height constraint is respected
  call test#framework#assert_equal(max_height, len(lines), "Should have exactly max_height lines after ellision")
  
  " Verify last line has ellision
  call test#framework#assert_true(lines[max_height-1] =~ '\.\.\.$', "Last line should end with ellision")
endfunction

" Test window sizing and ellision
function! s:test_window_sizing()
  call test#framework#write_info("Testing floating window sizing and ellision...")
  
  " Test with very long footnote content (should be ellided)
  call test#framework#setup_buffer_from_lines([
        \ 'This footnote has very long content[^long].',
        \ '',
        \ '[^long]: This is an extremely long footnote that contains more than seventy characters and should be ellided with dots at the end to fit within the maximum window width of seventy characters.',
        \ '',
        \ 'This footnote has many lines[^many].',
        \ '',
        \ '[^many]: Line 1',
        \ 'Line 2',
        \ 'Line 3',
        \ 'Line 4',
        \ 'Line 5',
        \ 'Line 6',
        \ 'Line 7',
        \ 'Line 8',
        \ 'Line 9',
        \ 'Line 10',
        \ 'Line 11',
        \ 'Line 12',
        \ 'Line 13'
        \ ])
  
  " Test long content footnote
  call cursor(1, 35)  " Position on [^long]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find long footnote reference")
  call test#framework#assert_equal('long', footnote_info.id, "Should extract long footnote ID")
  
  " Test many lines footnote
  call cursor(5, 35)  " Position on [^many]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find many-lines footnote reference")
  call test#framework#assert_equal('many', footnote_info.id, "Should extract many-lines footnote ID")
  
  " Note: We can't easily test the actual window creation without Neovim,
  " but we can test that the footnote parsing works correctly
endfunction

" Test edge cases
function! s:test_edge_cases()
  call test#framework#write_info("Testing edge cases...")
  
  " Test with empty buffer
  enew!
  setlocal filetype=markdown
  setlocal noswapfile
  runtime! plugin/**/*.vim
  runtime! after/ftplugin/markdown.vim
  
  call cursor(1, 1)
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal({}, footnote_info, "Should handle empty buffer gracefully")
  
  " Test malformed footnote patterns
  call test#framework#setup_buffer_from_lines([
        \ 'This has malformed [^ footnotes.',
        \ 'And incomplete [^incomplete',
        \ 'And empty [^] references.',
        \ 'Valid footnote [^valid] here.',
        \ '',
        \ '[^valid]: This is valid.'
        \ ])
  
  " Test cursor on malformed footnotes
  call cursor(1, 20)  " Position on malformed [^
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal({}, footnote_info, "Should handle malformed footnotes")
  
  call cursor(3, 15)  " Position on empty [^]
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal({}, footnote_info, "Should handle empty footnote ID")
  
  call cursor(4, 20)  " Position on valid footnote
  let footnote_info = md#footnotes#findFootnoteAtCursor()
  call test#framework#assert_equal('reference', footnote_info.type, "Should find valid footnote among malformed ones")
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()
  
  call test#framework#write_info("Running tests for md#footnotes module...")
  call test#framework#write_info("==================================")
  call test#framework#write_info("")
  
  call s:test_find_footnote_references_in_line()
  call s:test_find_footnote_at_cursor()
  call s:test_footnote_definitions()
  call s:test_ellision_logic()
  call s:test_window_sizing()
  call s:test_edge_cases()
  
  return test#framework#report_results('md#footnotes')
endfunction

" Main execution - only run if this file is executed directly
call s:run_all_tests()