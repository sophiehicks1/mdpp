# mdpp - Markdown Text Objects and Navigation Plugin

mdpp is a Vim plugin that provides sophisticated text objects, navigation, and structural manipulation capabilities for markdown files. It adds text objects for sections, headings, and trees, along with powerful navigation and document restructuring commands.

Always reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.

## Working Effectively

### Dependencies and Installation
- Clone required dependencies:
  - `git clone https://github.com/tpope/vim-repeat.git` -- takes 1-2 seconds. Set timeout to 10+ seconds.
  - `git clone https://github.com/kana/vim-textobj-user.git` -- takes 1-2 seconds. Set timeout to 10+ seconds.
- No build process required - this is pure VimScript
- Plugin must be added to Vim's runtimepath along with dependencies
- The plugin automatically loads when editing markdown files

### Testing and Validation
- The plugin provides three main features that must be validated:
  1. **Text Objects**: `is`/`as` (sections), `it`/`at` (trees), `ih`/`ah` (headings)
  2. **Navigation**: `[[`/`]]` (headings), `[s`/`]s` (siblings), `(`/`)` (parent/child)
  3. **Structure Manipulation**: `[h`/`]h` (heading levels), `gR` (nest), `[m`/`]m` (move sections)

- **Automated Testing**: The plugin includes comprehensive automated tests in the `tests/` directory:
  - Run tests with `./tests/run_tests.sh` for self-contained test execution
  - Refer to `tests/README.md` for detailed testing documentation
  - Write thorough automated tests for all functions that directly expose functionality to users
  - Use the test framework in `autoload/test/framework.vim` for consistent test structure
  - Store test data as markdown files in `tests/data/` for readability

### Manual Validation Requirements
ALWAYS validate the plugin functionality with the following test scenario after any changes:

1. Create a test markdown file with hierarchical headings
2. Load the file in Vim with proper plugin configuration
3. Test at least one example from each feature category:
   - Navigate using `]]` to move between headings
   - Use `is` text object to select section content
   - Use `]h` to increase a heading level
   - Use `gR` to nest a section under a new parent heading

### Required Vim Configuration
To use the plugin, your vimrc must include:
```vim
set nocompatible
filetype on
filetype plugin on

" Add dependencies and mdpp to runtimepath
set runtimepath+=/path/to/vim-textobj-user
set runtimepath+=/path/to/vim-repeat
set runtimepath+=/path/to/mdpp

" Force load plugins
runtime! plugin/**/*.vim
```

### Testing Commands
Test the plugin is working with these Vim commands:
```vim
:set filetype=markdown
:runtime after/ftplugin/markdown.vim
:verbose map gR
:verbose map ]s
:verbose map is
```

All mappings should show they are loaded from the mdpp plugin files.

## Validation

- ALWAYS run automated tests first: `./tests/run_tests.sh` to verify current functionality
- Tests are comprehensive and self-contained - prefer running automated tests over manual validation when possible
- Automated tests cover move module navigation functions with 41 test cases across different scenarios
- ALWAYS manually validate any code changes by testing the plugin functionality in Vim after automated tests pass
- Use the test-files directory which contains sample markdown files (foo.md, long-test.md)
- Test scenarios MUST include:
  - Text object operations: Try `vas` to select around a section, `dis` to delete inside a section
  - Navigation: Move between headings with `]]` and `[[`, navigate siblings with `]s` and `[s`
  - Structure changes: Use `]h` to promote headings, `gR` to create parent sections
- When adding new functionality, write comprehensive automated tests before implementing changes
- NEVER assume the plugin works without running both automated tests and manual validation

## Common Tasks

### Repository Structure
```
/home/runner/work/mdpp/mdpp/
├── README.md                      # Documentation and usage examples
├── plugin/mdpp.vim               # Main plugin entry point with text object definitions
├── autoload/md/                  # Core functionality modules
│   ├── objects.vim              # Text object implementations
│   ├── move.vim                 # Navigation functions
│   ├── dom.vim                  # Document structure parsing
│   ├── line.vim                 # Line manipulation utilities
│   ├── node.vim                 # Document node handling
│   └── update.vim               # Structure modification functions
├── after/ftplugin/markdown.vim   # Markdown-specific key mappings
└── test-files/                   # Sample markdown files for testing
    ├── foo.md                   # Basic test document with sections
    └── long-test.md             # Extended test document
```

### Key Features and Mappings

#### Text Objects
- `is`/`as` - Inside/around section (current heading and its content)
- `it`/`at` - Inside/around tree (current heading tree from root)
- `ih`/`ah` - Inside/around heading (heading text only)

#### Navigation
- `]]`/`[[` - Next/previous heading (any level)
- `]s`/`[s` - Next/previous sibling heading (same level)
- `)`/`(` - First child/parent heading

#### Structure Manipulation
- `]H`/`[H` - Increase/decrease heading level (current only)
- `]h`/`[h` - Increase/decrease heading level (cascades to children)
- `]m`/`[m` - Move section forward/backward among siblings
- `]M`/`[M` - Raise section up one level forward/backward
- `gR` - Nest current section (create parent heading)

### Configuration Options
- `let g:mdpp_text_objects = 0` - Disable text object mappings
- `let g:mdpp_default_mappings = 0` - Disable all default key mappings

### Sample Commands for Common Operations

#### Quick Plugin Test
```bash
# Create minimal test setup
mkdir -p /tmp/mdpp-test && cd /tmp/mdpp-test
git clone https://github.com/tpope/vim-repeat.git
git clone https://github.com/kana/vim-textobj-user.git

# Create test vimrc
cat > test-vimrc << 'EOF'
set nocompatible
filetype on
filetype plugin on
execute 'set runtimepath+=' . '/tmp/mdpp-test/vim-textobj-user'
execute 'set runtimepath+=' . '/tmp/mdpp-test/vim-repeat'
execute 'set runtimepath+=' . '/home/runner/work/mdpp/mdpp'
runtime! plugin/**/*.vim
EOF

# Test with sample markdown file
vim -u test-vimrc /home/runner/work/mdpp/mdpp/test-files/foo.md
```

#### Testing Text Objects
```vim
" In Vim with a markdown file loaded:
:set filetype=markdown
:runtime after/ftplugin/markdown.vim

" Test section text object
vas    " Select around section
dis    " Delete inside section

" Test heading text object
vih    " Select inside heading text
cah    " Change around heading
```

#### Testing Navigation
```vim
" Move between headings
]]     " Next heading
[[     " Previous heading
]s     " Next sibling heading
[s     " Previous sibling heading
)      " First child heading
(      " Parent heading
```

#### Testing Structure Manipulation
```vim
" Modify heading levels
]h     " Increase heading level
[h     " Decrease heading level

" Move sections
]m     " Move section forward
[m     " Move section backward
gR     " Create parent heading for current section
```

## Troubleshooting

### Plugin Not Loading
- Verify dependencies are properly installed and in runtimepath
- Ensure `filetype plugin on` is set in vimrc
- Use `:runtime after/ftplugin/markdown.vim` to manually load mappings
- Check `:verbose map gR` shows mappings from mdpp plugin

### Mappings Not Working
- Confirm file type is set to markdown: `:set filetype=markdown`
- Check if default mappings are disabled: `:echo g:mdpp_default_mappings`
- Verify text objects are enabled: `:echo g:mdpp_text_objects`

### No Build or Compilation
- This plugin requires no compilation or build process
- All functionality is implemented in VimScript
- Simply ensure proper installation and configuration

## Style and structure guidelines

### Module structure

- Each module should either implement user exposed plugin functionality **or** perform semantic markdown
  operations/calculations. No module should do both.
- Semantic modules shouldn't care about the operation they are being used for, so that they can later be
  reused in other contexts.
- Plugin functionality modules shouldn't know anything about markdown semantic structure.
- No keybinding, mapping or text object should ever call directly into a semantic module.

For example, if you want to create a binding that adds the character X at the end of the current line, this
would involve edits to two separate files:

- implement `md#text#addXToLine(line_num)` in a semantic module
- implement `md#edit#addX()` in a plugin functionality module, that just passes the current line number into
  `md#text#addXToLine`

In other words:

- user facing operations should always be bound to thin wrappers which are implemented in modules that only
  implement plugin functionality.
- semantic operations should always happen in modules that are ignorant of the purpose or context of the
  operation they are being called from.
- semantic modules shouldn't operate on "cursor position" or "the current line", and their functions should
  never be directly exposed via user mappings.
- User mapping should be bound to a thin wrapper in a plugin functionality module (like md#move or md#update),
  and the cursor positions or current line should be calculated in the thin wrapper and passed into the
  relevant semantic modules (such as md#checkbox or md#links) as runtime arguments.

### Code style
- Keep functions small, simple and readable.
- Each function should do only one thing, it should only operate at one level of abstraction and it should be
  trivially easy to understand what each function is trying to do, why and how. You can achieve this by
  extracting logic into subfunctions with helpful descriptive names, that make the code more readable.
- If the code is hard to understand, first you should try to make the code simpler. If you can't make it
  simpler and it's still hard to understand, try to make the naming more descriptive. Only use comments to
  explain things that can't be made obvious through well written, intentional code.
- Prioritize making it easy to understand and reusable over making it short.
- Use human-friendly names.
- Do not leave trailing whitespace on any lines.
