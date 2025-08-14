# mdpp Move Module Tests

This directory contains automated tests for the `md#move` module functions.

## Test Coverage

The test suite covers the following functions:

### Core Movement Functions
- `md#move#backToHeading` - Move to previous heading
- `md#move#forwardToHeading` - Move to next heading  
- `md#move#backToSibling` - Move to previous sibling heading
- `md#move#backToParent` - Move to parent heading
- `md#move#forwardToFirstChild` - Move to first child heading

### Test Categories

1. **Happy Path Tests**: Normal operation scenarios with expected movements
2. **Edge Cases**: Empty buffers, no headings, single heading, boundary conditions
3. **Visual Mode**: All movement functions tested in Visual mode
4. **Underline Headings**: Support for `===` and `---` style headings

## Running Tests

### Automated Test Runner
```bash
./tests/run_tests.sh
```

This script:
- Sets up a temporary test environment
- Clones required dependencies (vim-textobj-user, vim-repeat)
- Creates a minimal vimrc configuration
- Runs all tests and reports results

### Manual Testing
You can also run tests manually:

```bash
# Setup test environment
mkdir -p /tmp/mdpp-test && cd /tmp/mdpp-test
git clone https://github.com/kana/vim-textobj-user.git
git clone https://github.com/tpope/vim-repeat.git

# Create test vimrc
cat > test-vimrc << 'EOF'
set nocompatible
filetype on
filetype plugin on
execute 'set runtimepath+=' . '/tmp/mdpp-test/vim-textobj-user'
execute 'set runtimepath+=' . '/tmp/mdpp-test/vim-repeat'
execute 'set runtimepath+=' . '/path/to/mdpp'
runtime! plugin/**/*.vim
set nomore
set cmdheight=2
EOF

# Run tests
vim -u test-vimrc -c "source /path/to/mdpp/tests/test_move.vim" -c "qa!"
```

## Test Structure

### Test Files
- `test_move.vim` - Main test suite with all test functions
- `run_tests.sh` - Automated test runner script

### Test Framework
The tests use a simple assertion framework:
- `s:assert_equal(expected, actual, message)` - Compare expected vs actual values
- `s:setup_test_buffer()` - Create standardized test markdown content
- Test results are reported with pass/fail counts

### Sample Test Content
Tests use structured markdown content:
```markdown
# Root Heading
Root content

## Section A
Section A content

### Subsection A1
Subsection A1 content

#### Deep A1
Deep A1 content

### Subsection A2
Subsection A2 content

## Section B
Section B content

# Another Root
Another root content
```

## Test Results

All tests should pass. Example output:
```
Running tests for md#move module...
==================================

Testing md#move#backToHeading...
PASS: backToHeading from content should go to section heading
PASS: backToHeading from section should go to previous heading
...

Test Results:
=============
Passes: 41
Failures: 0
All tests passed!
```

## Known Issues

- Tests require vim-textobj-user and vim-repeat dependencies
- Tests must be run with proper plugin loading sequence
- Visual mode tests require careful buffer state management

## Adding New Tests

To add new tests:

1. Add test function following the naming pattern `s:test_*`
2. Call the function from `s:run_tests()`
3. Use `s:assert_equal()` for assertions
4. Use `s:setup_test_buffer()` for consistent test content
5. Clean up visual mode state properly if testing visual functions