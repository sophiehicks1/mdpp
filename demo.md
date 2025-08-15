# List Editing Demo

This file demonstrates the new list editing functionality.

## Unordered Lists
- First item
- Second item  
  - Nested item
  - Another nested item

## Ordered Lists  
1. First numbered item
2. Second numbered item
   1. Nested numbered item
   2. Another nested numbered item

## Checkbox Lists
- [ ] Unchecked todo item
- [x] Completed item
- [X] Another completed item
  - [ ] Nested unchecked todo
  - [x] Nested completed item

## Mixed List Types
- Unordered item
  1. Nested ordered item
  2. Another nested ordered item
     - [ ] Deeply nested checkbox
     - [x] Another deeply nested checkbox

## Usage Instructions

When your cursor is at the end of any list item:

1. **Press `<Enter>`** to create a new list item of the same type
   - Unordered list → new `- ` item
   - Ordered list → next number (e.g., `3. `)  
   - Checkbox list → new `- [ ] ` item

2. **Press `<Shift+Enter>`** to create a continuation line
   - Indents to align with the content of the current list item
   - Perfect for multi-paragraph list items

3. **In non-list contexts**, both keys work normally (user's existing mappings)

## Test It Out

Try positioning your cursor at the end of any list item above and:
- Press `<Enter>` to see a new list item created
- Press `<Shift+Enter>` to see a continuation line created
- Try it in this paragraph to see normal behavior