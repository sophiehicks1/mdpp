#!/bin/bash

# Test runner for mdpp move module tests
# This script sets up a minimal Vim environment and runs the tests

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

# Create test vimrc
cat > "$TEMP_DIR/test-vimrc" << EOF
set nocompatible
filetype on
filetype plugin on

" Add dependencies and mdpp to runtimepath
execute 'set runtimepath+=' . '$TEMP_DIR/vim-textobj-user'
execute 'set runtimepath+=' . '$TEMP_DIR/vim-repeat'
execute 'set runtimepath+=' . '/home/runner/work/mdpp/mdpp'

" Force load plugins
runtime! plugin/**/*.vim

" Disable any output that might interfere with testing
set nomore
set cmdheight=2
EOF

echo "Running tests..."

# Run the tests
vim -u "$TEMP_DIR/test-vimrc" -c "source /home/runner/work/mdpp/mdpp/tests/test_move.vim" -c "qa!" 2>&1

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Test run complete."