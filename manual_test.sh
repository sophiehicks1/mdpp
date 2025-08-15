#!/bin/bash

# Manual test script for list editing functionality
# This script creates a temporary Vim session to test the list editing features

REPO_ROOT="$(pwd)"
TEMP_DIR="/tmp/mdpp-manual-test-$$"
mkdir -p "$TEMP_DIR"

echo "Setting up manual test environment in $TEMP_DIR..."

# Clone dependencies
cd "$TEMP_DIR"
git clone --quiet https://github.com/kana/vim-textobj-user.git
git clone --quiet https://github.com/tpope/vim-repeat.git

# Create test vimrc
cat > "$TEMP_DIR/test-vimrc" << EOF
set nocompatible
filetype on
filetype plugin on

" Add dependencies and mdpp to runtimepath
execute 'set runtimepath+=' . '$TEMP_DIR/vim-textobj-user'
execute 'set runtimepath+=' . '$TEMP_DIR/vim-repeat'
execute 'set runtimepath+=' . '$REPO_ROOT'

" Force load plugins
runtime! plugin/**/*.vim

" Show key mappings for verification
set cmdheight=3
EOF

# Create test markdown file
cat > "$TEMP_DIR/manual-test.md" << 'EOF'
# Manual Test for List Editing

## Test Instructions:
1. Position cursor at end of list items below
2. Press <Enter> to create new list items
3. Press <Shift+Enter> to create continuation lines
4. Verify proper list type and indentation

## Unordered Lists
- First item
- Second item
  - Nested item

## Ordered Lists
1. First numbered item
2. Second numbered item
   1. Nested numbered item

## Checkbox Lists
- [ ] Unchecked todo
- [x] Checked item
  - [ ] Nested unchecked todo

## Non-list Context
This is a regular paragraph where <Enter> should work normally.
EOF

echo "Created test file: $TEMP_DIR/manual-test.md"
echo "Starting Vim with test configuration..."
echo ""
echo "Test the following scenarios:"
echo "1. Position cursor at end of list items and press <Enter>"
echo "2. Position cursor at end of list items and press <Shift+Enter>"  
echo "3. Verify new list items have correct type and indentation"
echo "4. Test in non-list areas to ensure normal behavior"
echo ""
echo "Press any key to continue..."
read -n 1

# Launch vim for manual testing
vim -u "$TEMP_DIR/test-vimrc" "$TEMP_DIR/manual-test.md"

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"
echo "Manual test complete."