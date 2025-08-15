# mdpp Test Suite

This directory contains automated tests for the mdpp plugin modules. Currently provides comprehensive test coverage for both the `md#move` and `md#links` modules, with the framework designed to support testing all mdpp modules.

## Test Infrastructure

### Automated Test Suite
- **Test Runner**: `run_tests.sh` - Self-contained script that sets up dependencies and runs tests
- **Test Framework**: `autoload/test/framework.vim` - Reusable test infrastructure for all mdpp modules
- **Test Data**: `data/` directory containing markdown files for test scenarios
- **Current Coverage**: 133 test cases covering movement functions and link manipulation

### Running Tests
```bash
# Run all move module tests
./run_tests.sh

# The script automatically:
# - Creates isolated test environment
# - Clones required dependencies (vim-textobj-user, vim-repeat)
# - Sets up minimal Vim configuration
# - Runs tests and reports results
# - Cleans up test environment
```

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
4. **Document Variations**: Tests with underline-style headings and unusual content structures

## Test Data Files

Test scenarios use markdown files in the `data/` directory for better readability:

### Movement Test Data
- `comprehensive.md` - Main test document with hierarchical heading structure
- `no_headings.md` - Document with only content, no headings
- `single_heading.md` - Document with single heading
- `underline_headings.md` - Document using underline-style heading syntax
- `content_before_heading.md` - Document with content before first heading

### Link Test Data
- `links.md` - Comprehensive link test document with various link types:
  - Simple inline links: `[example](http://example.com)`
  - Complex inline links: `[**bold** and *italic*](http://example.com)`
  - Multiple links per line
  - Reference links: `[example reference][ref1]`
  - Implicit reference links: `[example][]`
  - Reference definitions: `[ref1]: http://example.com`
  - Edge cases and malformed links

## Framework Architecture

### Reusable Test Framework (`autoload/test/framework.vim`)
- `test#framework#assert_equal()` - Standard assertion function
- `test#framework#setup_buffer_from_file()` - Load test data from markdown files
- `test#framework#setup_buffer_with_content()` - Create buffer with inline content
- `test#framework#report_results()` - Standard test result reporting
- `test#framework#reset()` - Reset test counters for new test runs

### Benefits
- **Maintainable**: Test data stored as readable markdown files
- **Reusable**: Framework can be used for testing other modules
- **Isolated**: Each test run uses clean environment
- **Comprehensive**: Covers normal usage, edge cases, and error conditions

## Adding New Tests

1. **For new test data**: Add markdown files to `tests/data/`
2. **For new test functions**: Use the framework functions for consistency
3. **For new modules**: Follow the pattern established in `test_move.vim`

Example test function:
```vim
function! s:test_new_function()
  echo "Testing new function..."
  
  call test#framework#setup_buffer_from_file('test_data.md')
  
  " Test steps here
  call cursor(5, 1)
  call some#module#function()
  call test#framework#assert_equal(expected, actual, "descriptive message")
endfunction
```

## Expected Test Output

```
Running tests for md#move module...
==================================

Testing md#move#backToHeading...
PASS: backToHeading from content should go to section heading
PASS: backToHeading from section should go to previous heading
...

Test Results for md#move:
=============
Passes: 41
Failures: 0
All tests passed!
```
4. **Document Variations**: Tests with underline-style headings and unusual content structures

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

## Framework Usage

### Creating New Test Modules

To create tests for other mdpp modules:

1. Create a new test file: `tests/test_<module>.vim`
2. Use the framework functions:
   ```vim
   " Load the test framework
   source autoload/test/framework.vim
   
   " Test function
   function! s:test_your_function()
     call test#framework#setup_buffer_from_file('your_test_data.md')
     " Your test code here
     call test#framework#assert_equal(expected, actual, "Test description")
   endfunction
   
   " Main runner function
   function! TestYourModule()
     call test#framework#reset()
     call s:test_your_function()
     return test#framework#report_results("your#module")
   endfunction
   
   " Auto-run the tests
   call TestYourModule()
   ```

### Test Data Files

Store test content as markdown files in `tests/data/` for better readability and maintenance. Use descriptive filenames that indicate the test scenario.

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
Running tests for md#links module...
====================================

Testing md#links#findInlineLinksInLine...
PASS: Should find one inline link
PASS: Link type should be inline
PASS: Link text should match
...

Passes: 67
Failures: 0
All tests passed!

Running tests for md#move module...
==================================

Testing md#move#backToHeading...
PASS: backToHeading from content should go to section heading
PASS: backToHeading from section should go to previous heading
...

Passes: 66
Failures: 0
All tests passed!

Total test results: 133 tests passed
```

## Known Issues

- Tests require vim-textobj-user and vim-repeat dependencies
- Tests must be run with proper plugin loading sequence
- Visual mode tests require careful buffer state management

## Contributor Guidelines

### Test Requirements

When adding new functionality to mdpp:

1. **Write comprehensive tests** for all functions that directly expose functionality to users
2. **Consider underline headings** (`===` and `---` syntax) in addition to standard markdown headings - this is easily forgotten but important for compatibility
3. **Test edge cases** including empty buffers, no headings, single headings, and boundary conditions
4. **Use the test framework** in `autoload/test/framework.vim` for consistency
5. **Store test data** as readable markdown files in `tests/data/`

### Adding Tests to Existing Modules

To add tests to the move module:

### Adding Tests to Existing Modules

To add tests to the move module:

1. Add test function to `tests/test_move.vim` following the naming pattern `s:test_*`
2. Call the function from `s:run_tests()`  
3. Use `test#framework#assert_equal()` for assertions
4. Use `test#framework#setup_buffer_from_file()` for consistent test content
5. Clean up visual mode state properly if testing visual functionsg Modules

To add tests to the move module:

### Adding Tests to Existing Modules

To add tests to the move module:

1. Add test function to `tests/test_move.vim` following the naming pattern `s:test_*`
2. Call the function from `s:run_tests()`  
3. Use `test#framework#assert_equal()` for assertions
4. Use `test#framework#setup_buffer_from_file()` for consistent test content
5. Clean up visual mode state properly if testing visual functions