" Test file for md#footnotes module

" Set up test environment
call test#framework#init(g:mdpp_repo_root . '/tests/results.md')

" Test data setup function
function! s:setup_test_buffer()
  call test#framework#setup_buffer_from_file('footnotes_test.md')
endfunction

" Test finding footnote references in a line
function! s:test_find_footnote_references_in_line()
  call test#framework#write_info("Testing md#footnotes#findFootnoteReferencesInLine...")

  call s:setup_test_buffer()

  " Test line with single footnote
  let footnotes = md#footnotes#findFootnoteReferencesInLine(7)
  call test#framework#assert_equal(1, len(footnotes), "Should find one footnote in simple case")
  if len(footnotes) == 1
    call test#framework#assert_equal('reference', footnotes[0].type, "Should identify as reference type")
    call test#framework#assert_equal('1', footnotes[0].id, "Should extract correct footnote ID")
    call test#framework#assert_equal(34, footnotes[0].start_col, "Should find correct start column")
    call test#framework#assert_equal(37, footnotes[0].end_col, "Should find correct end column")
  endif

  " Test line with multiple footnotes
  let footnotes = md#footnotes#findFootnoteReferencesInLine(15)
  call test#framework#assert_equal(2, len(footnotes), "Should find two footnotes in line")
  if len(footnotes) == 2
    call test#framework#assert_equal('shared', footnotes[0].id, "Should extract first footnote ID")
    call test#framework#assert_equal('shared', footnotes[1].id, "Should extract second footnote ID")
  endif

  " Test line with no footnotes
  let footnotes = md#footnotes#findFootnoteReferencesInLine(3)
  call test#framework#assert_equal(0, len(footnotes), "Should find no footnotes in plain text")

  " Test line with footnote in middle
  let footnotes = md#footnotes#findFootnoteReferencesInLine(11)
  call test#framework#assert_equal(1, len(footnotes), "Should find footnote in middle of sentence")
  if len(footnotes) == 1
    call test#framework#assert_equal('3', footnotes[0].id, "Should extract correct ID from middle")
  endif
endfunction

" Test finding footnote at given position
function! s:test_find_footnote_at_position()
  call test#framework#write_info("Testing md#footnotes#findFootnoteAtPos...")

  call s:setup_test_buffer()

  " Test cursor on footnote reference
  call cursor(7, 36)  " Position on [^1]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote at cursor position")
  if !empty(footnote_info)
    call test#framework#assert_equal('reference', footnote_info.type, "Should find footnote reference")
    call test#framework#assert_equal('1', footnote_info.id, "Should extract correct footnote ID")
  endif

  " Test cursor on footnote definition
  call cursor(23, 5)  " Position on [^1]: definition line
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote definition at cursor position")
  if ! empty(footnote_info)
    call test#framework#assert_equal('definition', footnote_info.type, "Should find footnote definition")
    call test#framework#assert_equal('1', footnote_info.id, "Should extract correct ID from definition")
  endif

  " Test cursor not on footnote
  call cursor(3, 10)  " Position on regular text
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal({}, footnote_info, "Should return empty dict when not on footnote")

  " Test cursor on complex footnote
  call cursor(19, 42)  " Position on [^complex]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find complex footnote at cursor position")
  if !empty(footnote_info)
    call test#framework#assert_equal('reference', footnote_info.type, "Should find complex footnote reference")
    call test#framework#assert_equal('complex', footnote_info.id, "Should extract complex footnote ID")
  endif
endfunction

" Test finding footnote definitions
function! s:test_footnote_definitions()
  call test#framework#write_info("Testing footnote definition parsing...")

  call s:setup_test_buffer()

  " Test cursor on footnote reference to get definition content
  call cursor(7, 36)  " Position on [^1]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote at cursor position")
  if !empty(footnote_info)
    call test#framework#assert_equal('This is a simple footnote.', footnote_info.content, "Should find correct definition content")
  endif

  " Test complex footnote definition
  call cursor(19, 42)  " Position on [^complex]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find complex footnote at cursor position")
  let expected_content = 'This footnote contains **bold text**, *italic text*, and even [a link](http://example.com).'
  if !empty(footnote_info)
    call test#framework#assert_equal(expected_content, footnote_info.content, "Should find complex definition content")
  endif

  " Test multiple references to same footnote
  call cursor(15, 48)  " Position on first [^shared]
  let footnote_info1 = md#footnotes#findFootnoteAtPos(getpos('.'))
  call cursor(15, 73)  " Position on second [^shared]
  let footnote_info2 = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal(footnote_info1.content, footnote_info2.content, "Should find same content for multiple references")
endfunction

" Test window sizing and text wrapping logic in detail
function! s:test_text_wrapping_logic()
  call test#framework#write_info("Testing window sizing and text wrapping logic...")

  " Test with very long footnote content (should be wrapped, not ellided per line)
  call test#framework#setup_buffer_from_file('long_footnotes_test.md')

  " Test long content footnote
  call cursor(1, 42)  " Position on [^long] - fixed position
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal('reference', footnote_info.type, "Should find long footnote reference")
  call test#framework#assert_equal('long', footnote_info.id, "Should extract long footnote ID")

  " test window sizing
  let max_window = {'width': 70, 'height': 11}
  let lines = md#ux#prepareContentForFloatingWindow(max_window, footnote_info.id, footnote_info.content)
  " there should be exactly 4 lines: header + 3 wrapped lines
  call test#framework#assert_equal(4, len(lines), "Should have exactly 4 lines after wrapping long footnote content")

  " Verify that long content is wrapped, not truncated with ... on each line
  for line in lines[1:]  " Skip the header line
    " All lines should fit within max width
    call test#framework#assert_true(len(line) <= max_window.width, "Line should fit within max width after wrapping: " . string(line))
    " No line should be truncated for this example
    call test#framework#assert_true(! (line =~ '\.\.\.$'), "Lines should be wrapped, not truncated: " . string(line))
  endfor

  " Test many lines footnote
  call cursor(5, 35)  " Position on [^many]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal('reference', footnote_info.type, "Should find many-lines footnote reference")
  call test#framework#assert_equal('many', footnote_info.id, "Should extract many-lines footnote ID")

  " Prepare content with ellision
  let raw_lines = split(footnote_info.content, "\n")
  let window_lines = md#ux#prepareContentForFloatingWindow(max_window, footnote_info.id, footnote_info.content)

  " Check if we have more than max_window.height lines before processing and height constraint is respected after
  call test#framework#assert_true(len(raw_lines) > max_window.height, "Should have more than 11 lines before ellision")
  call test#framework#assert_equal(max_window.height, len(window_lines), "Should have exactly max_window.height lines after ellision")

  " Verify last line has ellision
  call test#framework#assert_true(window_lines[-1] =~ '\.\.\.$', "Last line should end with ellision")
endfunction

" Test window sizing and ellision
function! s:test_window_sizing()
  call test#framework#write_info("Testing floating window sizing and ellision...")

  " Test with very long footnote content (should be ellided)
  call test#framework#setup_buffer_from_file('long_footnotes_test.md')

  " Test long content footnote
  call cursor(1, 36)  " Position on [^long]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal('reference', footnote_info.type, "Should find long footnote reference")
  call test#framework#assert_equal('long', footnote_info.id, "Should extract long footnote ID")

  " Test many lines footnote
  call cursor(5, 35)  " Position on [^many]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal('reference', footnote_info.type, "Should find many-lines footnote reference")
  call test#framework#assert_equal('many', footnote_info.id, "Should extract many-lines footnote ID")
  call test#framework#assert_equal(13, len(split(footnote_info.content, "\n")), "Should have exactly 13 lines before ellision")

  " Note: We can't easily test the actual window creation without Neovim,
  " but we can test that the footnote parsing works correctly
endfunction

" Test wrapped footnote content parsing
function! s:test_wrapped_footnote_content()
  call test#framework#write_info("Testing wrapped footnote content parsing...")

  call test#framework#setup_buffer_from_file('wrapped_footnote_test.md')

  " Test cursor on wrapped footnote reference
  call cursor(3, 20)  " Position on [^wrapped]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find wrapped footnote at cursor position")
  if !empty(footnote_info)
    call test#framework#assert_equal('reference', footnote_info.type, "Should find wrapped footnote reference")
    call test#framework#assert_equal('wrapped', footnote_info.id, "Should extract wrapped footnote ID")
    
    " The content should be joined as a single paragraph (spaces, not newlines between continuation lines)
    let expected_content = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus a sem odio. Nunc ultricies quis neque ac lacinia. Phasellus id lacus quam. Praesent dignissim tortor neque, vitae tristique leo luctus id. Donec commodo'
    call test#framework#assert_equal(expected_content, footnote_info.content, "Should join wrapped lines with spaces, not newlines")
  endif
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
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal({}, footnote_info, "Should handle empty buffer gracefully")

  " Test malformed footnote patterns
  call test#framework#setup_buffer_from_file('bad_footnotes.md')

  " Test cursor on malformed footnotes
  call cursor(1, 20)  " Position on malformed [^
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal({}, footnote_info, "Should handle malformed footnotes")

  call cursor(2, 20)  " Position on malformed [^incomplete
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal({}, footnote_info, "Should handle malformed footnotes")

  call cursor(3, 12)  " Position on empty [^]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal({}, footnote_info, "Should handle empty footnote ID")

  call cursor(4, 20)  " Position on valid footnote
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find valid footnote among malformed ones")
  call test#framework#assert_equal('reference', footnote_info.type, "Should find valid footnote among malformed ones")
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()

  call test#framework#write_info("Running tests for md#footnotes module...")
  call test#framework#write_info("==================================")
  call test#framework#write_info("")

  call test#framework#run_test_function('test_find_footnote_references_in_line', function('s:test_find_footnote_references_in_line'))
  call test#framework#run_test_function('test_find_footnote_at_position', function('s:test_find_footnote_at_position'))
  call test#framework#run_test_function('test_footnote_definitions', function('s:test_footnote_definitions'))
  call test#framework#run_test_function('test_wrapped_footnote_content', function('s:test_wrapped_footnote_content'))
  call test#framework#run_test_function('test_text_wrapping_logic', function('s:test_text_wrapping_logic'))
  call test#framework#run_test_function('test_window_sizing', function('s:test_window_sizing'))
  call test#framework#run_test_function('test_edge_cases', function('s:test_edge_cases'))

  return test#framework#report_results('md#footnotes')
endfunction

" Main execution - only run if this file is executed directly
call s:run_all_tests()
