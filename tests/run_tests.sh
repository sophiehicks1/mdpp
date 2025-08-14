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

" Disable any output that might interfere with testing
set nomore
set cmdheight=2
EOF

echo "Running tests..."

# Auto-discover and run all test files
for test_file in "$REPO_ROOT"/tests/test_*.vim; do
    if [ -f "$test_file" ]; then
        echo "Running $(basename "$test_file")..."
        vim -u "$TEMP_DIR/test-vimrc" -c "source $test_file" -c "qa!" 2>&1
    fi
done

# Cleanup
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

echo "Test run complete."