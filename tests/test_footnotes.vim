" Test file for md#footnotes module

" Set up test environment
call test#framework#init('footnotes.txt')

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

" Test footnote text object range functions
function! s:test_footnote_text_object_ranges()
  call test#framework#write_info("Testing footnote text object range functions...")

  call s:setup_test_buffer()

  " Test footnote text range for reference
  call cursor(7, 36)  " Position on [^1]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  let text_range = md#footnotes#getFootnoteTextRange(footnote_info)
  call test#framework#assert_not_empty(text_range, "Should get footnote text range")
  if !empty(text_range)
    call test#framework#assert_equal(4, len(text_range), "Text range should have 4 elements")
    call test#framework#assert_equal(7, text_range[0], "Text range line should be correct")
    call test#framework#assert_equal(36, text_range[1], "Text range start column should be correct")
    call test#framework#assert_equal(7, text_range[2], "Text range end line should be correct")
    call test#framework#assert_equal(36, text_range[3], "Text range end column should be correct")
  endif

  " Test footnote definition range for reference
  let def_range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
  call test#framework#assert_not_empty(def_range, "Should get footnote definition range")
  if !empty(def_range)
    call test#framework#assert_equal(4, len(def_range), "Definition range should have 4 elements")
    call test#framework#assert_equal(23, def_range[0], "Definition range line should be correct")
  endif

  " Test footnote full range for reference
  let full_range = md#footnotes#getFootnoteFullRange(footnote_info)
  call test#framework#assert_not_empty(full_range, "Should get footnote full range")
  if !empty(full_range)
    call test#framework#assert_equal(4, len(full_range), "Full range should have 4 elements")
    call test#framework#assert_equal(7, full_range[0], "Full range line should be correct")
    call test#framework#assert_equal(34, full_range[1], "Full range start column should be correct")
    call test#framework#assert_equal(37, full_range[3], "Full range end column should be correct")
  endif

  " Test footnote definition range for definition
  call cursor(23, 5)  " Position on [^1]: definition line
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  let def_range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
  call test#framework#assert_not_empty(def_range, "Should get definition range from definition position")
  if !empty(def_range)
    call test#framework#assert_equal(23, def_range[0], "Definition range line should be correct")
  endif
endfunction

" Test footnote text objects
function! s:test_footnote_text_objects()
  call test#framework#write_info("Testing footnote text object functions...")

  call s:setup_test_buffer()

  " Test inside footnote text on reference
  call cursor(7, 36)  " Position on [^1]
  let result = md#objects#insideFootnoteText()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for inside footnote text")
  if type(result) == type([])
    call test#framework#assert_equal('v', result[0], "Should be character-wise selection")
  endif

  " Test around footnote text on reference
  let result = md#objects#aroundFootnoteText()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for around footnote text")
  if type(result) == type([])
    call test#framework#assert_equal('v', result[0], "Should be character-wise selection")
  endif

  " Test inside footnote definition
  let result = md#objects#insideFootnoteDefinition()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for inside footnote definition")
  if type(result) == type([])
    call test#framework#assert_equal('v', result[0], "Should be character-wise selection")
  endif

  " Test around footnote definition
  let result = md#objects#aroundFootnoteDefinition()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for around footnote definition")
  if type(result) == type([])
    call test#framework#assert_equal('V', result[0], "Should be line-wise selection")
  endif

  " Test inside footnote
  let result = md#objects#insideFootnote()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for inside footnote")
  if type(result) == type([])
    call test#framework#assert_equal('v', result[0], "Should be character-wise selection")
  endif

  " Test around footnote
  let result = md#objects#aroundFootnote()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for around footnote")
  if type(result) == type([])
    call test#framework#assert_equal('v', result[0], "Should be character-wise selection")
  endif

  " Test on footnote definition line
  call cursor(23, 5)  " Position on [^1]: definition line
  let result = md#objects#insideFootnoteDefinition()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for definition line")

  let result = md#objects#aroundFootnoteDefinition()
  call test#framework#assert_false(type(result) == type(0) && result == 0, "Should return valid range for around definition")
  if type(result) == type([])
    call test#framework#assert_equal('V', result[0], "Should be line-wise selection for definition")
  endif

  " Test that text objects return 0 when not on footnote
  call cursor(3, 10)  " Position on regular text
  let result = md#objects#insideFootnoteText()
  call test#framework#assert_true(type(result) == type(0) && result == 0, "Should return 0 when not on footnote")
  let result = md#objects#aroundFootnoteText()
  call test#framework#assert_true(type(result) == type(0) && result == 0, "Should return 0 when not on footnote")
  let result = md#objects#insideFootnoteDefinition()
  call test#framework#assert_true(type(result) == type(0) && result == 0, "Should return 0 when not on footnote")
  let result = md#objects#aroundFootnoteDefinition()
  call test#framework#assert_true(type(result) == type(0) && result == 0, "Should return 0 when not on footnote")
  let result = md#objects#insideFootnote()
  call test#framework#assert_true(type(result) == type(0) && result == 0, "Should return 0 when not on footnote")
  let result = md#objects#aroundFootnote()
  call test#framework#assert_true(type(result) == type(0) && result == 0, "Should return 0 when not on footnote")
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

  " Prepare content for display
  " The content should be joined as a single paragraph (no newlines between continuation lines)
  let raw_lines = split(footnote_info.content, "\n")
  let window_lines = md#ux#prepareContentForFloatingWindow(max_window, footnote_info.id, footnote_info.content)
  call test#framework#assert_equal(1, len(raw_lines), "Continuation lines should be joined into single paragraph")

  " Verify last line doesn't have ellision
  call test#framework#assert_true(!(window_lines[-1] =~ '\.\.\.$'), "Last line shouldn't end with ellision")

  " Test many paras footnote
  call cursor(21, 45)  " Position on [^paras]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal('reference', footnote_info.type, "Should find paras footnote reference")
  call test#framework#assert_equal('paras', footnote_info.id, "Should extract paras footnote ID")

  " Prepare content for ellision
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
  call cursor(21, 45)  " Position on [^paras]
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal('reference', footnote_info.type, "Should find paras footnote reference")
  call test#framework#assert_equal('paras', footnote_info.id, "Should extract paras footnote ID")
  call test#framework#assert_equal(25, len(split(footnote_info.content, "\n")), "Should have exactly 25 lines before ellision")

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
  call test#framework#setup_empty_buffer()

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

" Test footnote detection from continuation lines  
function! s:test_continuation_line_detection()
  call test#framework#write_info("Testing footnote detection from continuation lines...")

  " Create test buffer with multi-line footnotes
  call test#framework#setup_buffer_from_lines(['# Test', '', 'Reference[^multi].', '', '[^multi]: First line', '    Second line', '    Third line', '', '[^simple]: Single line'])

  " Test cursor on continuation line
  call cursor(6, 8)  " Position on "Second line" 
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote from continuation line")
  if !empty(footnote_info)
    call test#framework#assert_equal('definition', footnote_info.type, "Should identify as definition type")
    call test#framework#assert_equal('multi', footnote_info.id, "Should extract correct footnote ID")
    call test#framework#assert_equal(5, footnote_info.line_num, "Should point to definition line")
  endif

  " Test cursor on third continuation line
  call cursor(7, 8)  " Position on "Third line"
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote from third continuation line")
  if !empty(footnote_info)
    call test#framework#assert_equal('multi', footnote_info.id, "Should extract correct footnote ID from third line")
  endif

  " Test cursor not on continuation line
  call cursor(8, 1)  " Position on empty line between footnotes
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_equal({}, footnote_info, "Should not find footnote on empty line between definitions")
endfunction

" Test footnote detection from definition content (not just marker)
function! s:test_definition_content_detection()
  call test#framework#write_info("Testing footnote detection from definition content...")

  call s:setup_test_buffer()

  " Test cursor on content part of definition line 
  call cursor(23, 10)  " Position on "This is a simple footnote." content
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote from definition content")
  if !empty(footnote_info)
    call test#framework#assert_equal('definition', footnote_info.type, "Should identify as definition type")
    call test#framework#assert_equal('1', footnote_info.id, "Should extract correct footnote ID from content")
  endif

  " Test cursor on content part of longer definition
  call cursor(31, 40)  " Position in middle of complex footnote content
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find footnote from complex definition content")
  if !empty(footnote_info)
    call test#framework#assert_equal('definition', footnote_info.type, "Should identify as definition type")
    call test#framework#assert_equal('complex', footnote_info.id, "Should extract complex footnote ID from content")
  endif
endfunction

" Test that newlines are handled correctly in ranges
function! s:test_newline_handling()
  call test#framework#write_info("Testing newline handling in footnote ranges...")

  " start with content that specifically tests the newline issue
  call test#framework#setup_buffer_from_lines(['# Test', '', 'Reference[^1] and [^2].', '', '[^1]: blah blah blah', '', '[^2]: foo bar baz'])  " Start with empty buffer

  " Test definition range for first footnote
  call cursor(5, 5)  " Position on [^1]: definition line
  let footnote_info = md#footnotes#findFootnoteAtPos(getpos('.'))
  call test#framework#assert_not_empty(footnote_info, "Should find first footnote")
  
  if !empty(footnote_info)
    let def_range = md#footnotes#getFootnoteDefinitionRange(footnote_info)
    call test#framework#assert_not_empty(def_range, "Should get definition range")
    if !empty(def_range)
      " The range should end on line 5 (content line), not line 6 (blank line)
      call test#framework#assert_equal(5, def_range[2], "Range should end on content line, not include trailing blank line")
      
      " Content should be exactly from after ": " to end of content
      " Line is "[^1]: blah blah blah" 
      " [^1]: = 5 chars, + space = 6 chars, so content starts at position 7
      let content_start_expected = 7  " After "[^1]: "
      call test#framework#assert_equal(content_start_expected, def_range[1], "Range should start after marker")
      
      " End column should be at end of "blah blah blah" 
      " Length of line "[^1]: blah blah blah" = 20, so end col should be 20
      let expected_end_col = 20
      call test#framework#assert_equal(expected_end_col, def_range[3], "Range should end after content")
    endif
  endif
endfunction

" Test finding next available footnote ID
function! s:test_find_next_available_id()
  call test#framework#write_info("Testing md#footnotes#findNextAvailableId...")

  call test#framework#setup_empty_buffer()
  
  let next_id = md#footnotes#findNextAvailableId()
  call test#framework#assert_equal('1', next_id, "Should return '1' for empty buffer")

  " Test with existing footnotes
  call setline(1, ['# Test', 'Text with footnote[^1].', 'Another footnote[^3].', '', '[^1]: First footnote', '[^3]: Third footnote'])
  
  let next_id = md#footnotes#findNextAvailableId()
  call test#framework#assert_equal('2', next_id, "Should return '2' when 1 and 3 exist")

  " Test with consecutive footnotes
  call setline(1, ['# Test', 'Text[^1] and [^2] and [^3].', '', '[^1]: First', '[^2]: Second', '[^3]: Third'])
  
  let next_id = md#footnotes#findNextAvailableId()
  call test#framework#assert_equal('4', next_id, "Should return '4' when 1,2,3 exist")

  " Test with mixed ID types (numbers and letters)
  call setline(1, ['# Test', 'Text[^1] and [^note] and [^2].', '', '[^1]: First', '[^note]: Named', '[^2]: Second'])
  
  let next_id = md#footnotes#findNextAvailableId()
  call test#framework#assert_equal('3', next_id, "Should return '3' even with mixed ID types")
endfunction

" Test adding footnote reference
function! s:test_add_footnote_reference()
  call test#framework#write_info("Testing md#footnotes#addFootnoteReference...")

  call test#framework#setup_empty_buffer()

  " Test adding in middle of line
  call setline(1, 'Lorem ipsum dolor sit amet')
  call md#footnotes#addFootnoteReference(1, 10, '2') " At column 10 (between 'u' and 'm' in 'ipsum')
  let result = getline(1)
  call test#framework#assert_equal('Lorem ipsu[^2]m dolor sit amet', result, "Should add reference at column 10")

  " Test adding at end of line
  call setline(1, 'Lorem ipsum dolor sit amet')
  call md#footnotes#addFootnoteReference(1, 26, '3') " At column 26 (after last character)
  let result = getline(1)
  call test#framework#assert_equal('Lorem ipsum dolor sit amet[^3]', result, "Should add reference at end")
endfunction

" Test adding footnote reference in middle of line (bug fix test)
function! s:test_add_footnote_reference_middle_of_line()
  call test#framework#write_info("Testing md#footnotes#addFootnoteReference in middle of line...")

  call test#framework#setup_empty_buffer()

  " Test case from bug report: cursor after "text" before "."
  call setline(1, 'This is some text. My cursor is in the middle.')
  " Cursor at column 18 (after 'text', before '.')
  call md#footnotes#addFootnoteReference(1, 18, '1')
  let result = getline(1)
  call test#framework#assert_equal('This is some text.[^1] My cursor is in the middle.', result, "Should insert footnote at cursor position, not skip a character")

  " Test case: cursor at column 11 (between space and 's' in 'second')
  call setline(1, 'First word second word third word')
  call md#footnotes#addFootnoteReference(1, 11, '2')
  let result = getline(1)
  call test#framework#assert_equal('First word [^2]second word third word', result, "Should insert at column 11")

  " Test case: cursor at column 6 (between space and 'm' in 'middle')
  call setline(1, 'Start middle end')
  call md#footnotes#addFootnoteReference(1, 6, '3')
  let result = getline(1)
  call test#framework#assert_equal('Start [^3]middle end', result, "Should insert at column 6")
endfunction

" FIXME make sure these tests are fixed
" Test adding footnote definition
function! s:test_add_footnote_definition()
  call test#framework#write_info("Testing md#footnotes#addFootnoteDefinition...")

  call test#framework#setup_empty_buffer()

  " Test adding to empty buffer
  let def_line = md#footnotes#addFootnoteDefinition('1')
  call test#framework#assert_equal(2, def_line, "Should append reference definition at line 2 for empty buffer")
  let result = getline(2)
  call test#framework#assert_equal('[^1]: ', result, "Should add definition correctly")

  " Test adding to non-empty buffer
  call test#framework#setup_buffer_from_lines(['# Test', 'Some content'])
  let def_line = md#footnotes#addFootnoteDefinition('2')
  call test#framework#assert_equal(4, def_line, "Should append footnote definition at line 4 after content and blank line")
  let blank_line = getline(3)
  let def_line_content = getline(4)
  call test#framework#assert_equal('', blank_line, "Should add blank line before definition")
  call test#framework#assert_equal('[^2]: ', def_line_content, "Should add definition after blank line")

  " Test adding when last line is already empty
  call test#framework#setup_buffer_from_lines(['# Test', 'Content', ''])
  let def_line = md#footnotes#addFootnoteDefinition('3')
  call test#framework#assert_equal(4, def_line, "Should add definition after existing blank line")
  let result = getline(4)
  call test#framework#assert_equal('[^3]: ', result, "Should add definition correctly after blank line")
endfunction

" Run all tests
function! s:run_all_tests()
  call test#framework#reset()

  call test#framework#write_info("Running tests for md#footnotes module...")
  call test#framework#write_info("==================================")
  call test#framework#write_info("")

  call test#framework#run_test_function('test_find_footnote_references_in_line', function('s:test_find_footnote_references_in_line'))
  call test#framework#run_test_function('test_find_footnote_at_position', function('s:test_find_footnote_at_position'))
  call test#framework#run_test_function('test_footnote_text_object_ranges', function('s:test_footnote_text_object_ranges'))
  call test#framework#run_test_function('test_footnote_text_objects', function('s:test_footnote_text_objects'))
  call test#framework#run_test_function('test_footnote_definitions', function('s:test_footnote_definitions'))
  call test#framework#run_test_function('test_wrapped_footnote_content', function('s:test_wrapped_footnote_content'))
  call test#framework#run_test_function('test_text_wrapping_logic', function('s:test_text_wrapping_logic'))
  call test#framework#run_test_function('test_window_sizing', function('s:test_window_sizing'))
  call test#framework#run_test_function('test_edge_cases', function('s:test_edge_cases'))
  call test#framework#run_test_function('test_continuation_line_detection', function('s:test_continuation_line_detection'))
  call test#framework#run_test_function('test_definition_content_detection', function('s:test_definition_content_detection'))
  call test#framework#run_test_function('test_newline_handling', function('s:test_newline_handling'))
  call test#framework#run_test_function('test_find_next_available_id', function('s:test_find_next_available_id'))
  call test#framework#run_test_function('test_add_footnote_reference', function('s:test_add_footnote_reference'))
  call test#framework#run_test_function('test_add_footnote_reference_middle_of_line', function('s:test_add_footnote_reference_middle_of_line'))
  call test#framework#run_test_function('test_add_footnote_definition', function('s:test_add_footnote_definition'))

  return test#framework#report_results('md#footnotes')
endfunction

" Main execution - only run if this file is executed directly
call s:run_all_tests()
