#!/bin/bash

# Test runner for mdpp module tests
# This script sets up a minimal Vim environment and runs the tests
# Usage: Run from repository root directory

# Check if running from repository root
if [ ! -f "plugin/mdpp.vim" ]; then
    echo "Error: Please run this script from the repository root directory"
    exit 1
fi

# Get absolute path to repository root
REPO_ROOT="$(pwd)"

# Create temporary directory for test dependencies
TEMP_DIR="/tmp/mdpp-test-$$"
mkdir -p "$TEMP_DIR"

echo "Setting up test environment in $TEMP_DIR..."

# Clone required dependencies
echo "Cloning vim-textobj-user..."
cd "$TEMP_DIR"
git clone --quiet https://github.com/kana/vim-textobj-user.git

echo "Cloning vim-repeat..."
git clone --quiet https://github.com/tpope/vim-repeat.git

echo "Cloning vim-open..."
git clone --quiet https://github.com/sophiehicks1/vim-open.git

# Create test vimrc
cat > "$TEMP_DIR/test-vimrc" << EOF
set nocompatible
filetype on
filetype plugin on

" Add dependencies and mdpp to runtimepath
execute 'set runtimepath+=' . '$TEMP_DIR/vim-textobj-user'
execute 'set runtimepath+=' . '$TEMP_DIR/vim-repeat'
execute 'set runtimepath+=' . '$TEMP_DIR/vim-open'
execute 'set runtimepath+=' . '$REPO_ROOT'

" Force load plugins
runtime! plugin/**/*.vim

" Set repository root for test framework
let g:mdpp_repo_root = '$REPO_ROOT'

" Disable any output that might interfere with testing
set nomore
set cmdheight=2
set shortmess+=F
set t_Co=0
set t_ti=
set t_te=
EOF

echo "Running tests..."

# Auto-discover and run all test files
for test_file in "$REPO_ROOT"/tests/test_*.vim; do
  if [ -f "$test_file" ]; then
    echo "Running $(basename "$test_file")..."
    # Run vim silently and let it write to the results file
    vim -u "$TEMP_DIR/test-vimrc" -c "source $test_file" -c "qa!" >/dev/null 2>&1
  fi
done

# print empty line
echo ''

# Display results
for result_file in "$REPO_ROOT"/tests/results/*.txt; do
  if [ -f "$result_file" ]; then
    cat "$result_file" | grep -v '^PASS:' | grep -v '^=*$' | grep -v '^Testing'
    echo ""
  fi
done

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Test run complete."
