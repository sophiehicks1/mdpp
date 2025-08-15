#!/bin/bash

# Simple validation test script for list editing functionality
REPO_ROOT="$(pwd)"
TEMP_DIR="/tmp/mdpp-validation-$$"
mkdir -p "$TEMP_DIR"

echo "Setting up validation test..."

# Clone dependencies  
cd "$TEMP_DIR"
git clone --quiet https://github.com/kana/vim-textobj-user.git
git clone --quiet https://github.com/tpope/vim-repeat.git

# Create test vimrc
cat > "$TEMP_DIR/test-vimrc" << EOF
set nocompatible
filetype on
filetype plugin on
execute 'set runtimepath+=' . '$TEMP_DIR/vim-textobj-user'
execute 'set runtimepath+=' . '$TEMP_DIR/vim-repeat'
execute 'set runtimepath+=' . '$REPO_ROOT'
runtime! plugin/**/*.vim
EOF

# Create test markdown file
cat > "$TEMP_DIR/validation-test.md" << 'EOF'
# Validation Test

## Unordered List
- Item 1

## Ordered List  
1. Item 1

## Checkbox List
- [ ] Todo item
EOF

echo "Testing list editing functionality..."

# Test 1: Validate unordered list functionality
cat > "$TEMP_DIR/test1.vim" << 'EOF'
edit validation-test.md
call cursor(5, 9)  " End of "- Item 1"
let result = md#lists#handleEnter()
if result ==# "\<CR>- "
  echo "PASS: Unordered list <Enter> generates correct new item"
else
  echo "FAIL: Expected '\<CR>- ', got '" . result . "'"
endif
quit!
EOF

# Test 2: Validate ordered list functionality  
cat > "$TEMP_DIR/test2.vim" << 'EOF'
edit validation-test.md
call cursor(8, 10)  " End of "1. Item 1"
let result = md#lists#handleEnter()
if result ==# "\<CR>2. "
  echo "PASS: Ordered list <Enter> generates correct new item"
else
  echo "FAIL: Expected '\<CR>2. ', got '" . result . "'"
endif
quit!
EOF

# Test 3: Validate checkbox list functionality
cat > "$TEMP_DIR/test3.vim" << 'EOF'
edit validation-test.md  
call cursor(11, 17)  " End of "- [ ] Todo item"
let result = md#lists#handleEnter()
if result ==# "\<CR>- [ ] "
  echo "PASS: Checkbox list <Enter> generates correct new item"
else
  echo "FAIL: Expected '\<CR>- [ ] ', got '" . result . "'"
endif
quit!
EOF

# Test 4: Validate non-list context
cat > "$TEMP_DIR/test4.vim" << 'EOF'
edit validation-test.md
call cursor(1, 16)  " End of "# Validation Test"
let result = md#lists#handleEnter()
if result ==# "\<CR>"
  echo "PASS: Non-list context returns normal <Enter>"
else
  echo "FAIL: Expected '\<CR>', got '" . result . "'"
endif
quit!
EOF

# Test 5: Validate continuation functionality
cat > "$TEMP_DIR/test5.vim" << 'EOF'
edit validation-test.md
call cursor(5, 9)  " End of "- Item 1"
let result = md#lists#handleShiftEnter()
if result ==# "\<CR>  "
  echo "PASS: Unordered list <S-Enter> generates correct continuation"
else
  echo "FAIL: Expected '\<CR>  ', got '" . result . "'"
endif
quit!
EOF

# Run all tests
echo "Running validation tests..."
cd "$TEMP_DIR"
vim -u test-vimrc -c "source test1.vim" 2>/dev/null
vim -u test-vimrc -c "source test2.vim" 2>/dev/null  
vim -u test-vimrc -c "source test3.vim" 2>/dev/null
vim -u test-vimrc -c "source test4.vim" 2>/dev/null
vim -u test-vimrc -c "source test5.vim" 2>/dev/null

echo "Validation complete."

# Cleanup
cd "$REPO_ROOT"
rm -rf "$TEMP_DIR"
echo "Cleaned up temporary files."