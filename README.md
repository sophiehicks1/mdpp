# mdpp

A vim plugin that adds text objects, navigation and structural manipulation to markdown editing.

## Features

### Markdown Text Objects

Navigate and manipulate markdown structures with precision:

- **`is`/`as`** - Inside/around section (current heading and its content)
- **`it`/`at`** - Inside/around tree (current heading tree from root)  
- **`ih`/`ah`** - Inside/around heading (heading text only)
- **`ic`/`ac`** - Inside/around checkbox (checkbox list item)
- **`il`/`al`** - Inside/around link text (text between `[...]`)
- **`iu`/`au`** - Inside/around link URL (URL for inline links or reference definition)
- **`iL`/`aL`** - Inside/around entire link (complete link syntax)

Examples:
```
- `das` - Delete entire section
- `yis` - Yank section content  
- `cih` - Change heading text
- `vic` - Select checkbox content
- `dac` - Delete entire checkbox item
- `vil` - Select link text
- `ciu` - Change link URL
- `yaL` - Yank entire link
```

#### Link Text Objects

Supports both inline and reference style links:
- **Inline links**: `[text](url)` 
- **Reference links**: `[text][ref]` with `[ref]: url` definitions

**Note**: Multi-line links are not currently supported. This will be tracked in a separate issue for future implementation.

#### Checkbox Text Objects

Work with markdown checkbox list items:
- **`ic`** - Select the text content of a checkbox item (excluding the `- [ ] ` prefix)
- **`ac`** - Select the entire checkbox item (including the `- [ ] ` prefix)

Supports:
- Both checked (`- [x]`) and unchecked (`- [ ]`) checkboxes
- Multi-line checkbox items with proper indentation
- Works regardless of cursor position within the checkbox item

Examples:
```
- [ ] This is a todo item
      that spans multiple lines
- [x] Completed task
```
- `vic` on either line selects just the text content
- `vac` selects the entire checkbox including prefix and continuation lines

### Smart Navigation

Move through your document structure efficiently:

- **`]]`/`[[`** - Next/previous heading (any level)
- **`]s`/`[s`** - Next/previous sibling heading (same level)
- **`)`/`(`** - First child/parent heading

### Document Structure Manipulation

Reorganize your markdown hierarchy effortlessly:

#### Heading Level Control
- **`]H`/`[H`** - Increase/decrease heading level (current only)
- **`]h`/`[h`** - Increase/decrease heading level (cascades to children)

#### Section Movement  
- **`]m`/`[m`** - Move section forward/backward among siblings
- **`]M`/`[M`** - Raise section up one level forward/backward
- **`gR`** - Nest current section (create parent heading)

### Footnote Support (Neovim only)

- **`<leader>f`** - Show footnote content in floating window when cursor is on footnote reference or definition

The footnote feature works with standard Markdown footnote syntax:
- Footnote references: `[^footnote-id]`
- Footnote definitions: `[^footnote-id]: footnote content`

### Enhanced Link Navigation (vim-open integration)

When [vim-open](https://github.com/sophiehicks1/vim-open) is installed, **`gf`** can be used to open markdown links:

- **`gf`** - Open links in current window (works on any part of markdown links)
- **`gF`** - Open links in new tab

Supported link types:
- Inline links: `[text](./file.md)`, `[text](https://example.com)`, `[text](@username)`
- Reference links: `[text][ref]` with `[ref]: ./file.md` definitions  
- Wiki links: `[[Internal Page]]`, `[[docs/another-page]]`

Features:
- Passes all link addresses to vim-open for processing (files, URLs, custom identifiers)
- Works with vim-open's configurable "opener" system for handling different resource types
- Supports file paths, web URLs, and custom identifiers like Slack usernames or Jira ticket IDs
- Only activates in markdown files

Examples of supported links:
- `[File](./readme.md)` - Opens file in vim
- `[Website](https://example.com)` - Opens in browser  
- `[Slack user](@sophie.hicks)` - Can be configured to open Slack DM
- `[Ticket](AB-1234)` - Can be configured to open Jira ticket

<!-- ### Additional Features -->

<!-- - **`<C-f>`** (Insert mode) - Insert footnote with interactive prompt -->
<!-- - **`<C-l>`** (Insert mode) - Insert reference link with interactive prompt -->

## Installation

### Using vim-plug:
```vim
Plug 'sophiehicks1/mdpp'

### Using Vundle:
```vim
Plugin 'sophiehicks1/mdpp.vim'
```

## Usage Examples

### Document Navigation
```markdown
# Project Overview          <- ]s from anywhere jumps here
## Features                 <- ]] moves to next sibling  
### Authentication          <- ) moves to first child
### Database                <- [[ moves to previous sibling
## Installation             <- ( moves back to parent
# Conclusion                <- ]s continues to next heading
```

### Structural Editing
Given this structure:
```markdown
# Main Topic
## Subtopic A
### Detail 1
### Detail 2  
## Subtopic B
```

- Position cursor on "## Subtopic A" and press `]m` → moves entire section after "Subtopic B"
- Press `[h` on "## Subtopic A" → becomes "# Subtopic A" (and children become ##, ###)
- Press `gR` on "### Detail 1" → creates new parent heading above it

## Dependencies

- tpope/vim-repeat
- kana/vim-textob-user

## Optional Dependencies

- [sophiehicks1/vim-open](https://github.com/sophiehicks1/vim-open) - Enhanced `gf` functionality for opening markdown links

## Configuration

```vim
" no text object mappings
let g:mdpp_text_objects = 0

" no default mappings
let g:mdpp_default_mappings = 0
```

You can set your own mappings up by copying the `<Plug>` mappings found in `after/ftplugin/markdown.vim`

---

**mdpp.vim** - Making markdown editing as powerful as your ideas.
