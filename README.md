# mdpp

A comprehensive vim plugin that transforms markdown editing with powerful text objects, intelligent navigation, structural manipulation, and optional REPL integration.

## Features

### Markdown Text Objects

Navigate and manipulate markdown structures with precision:

- **`is`/`as`** - Inside/around section (current heading and its content)
- **`it`/`at`** - Inside/around tree (current heading tree from root)  
- **`ih`/`ah`** - Inside/around heading (heading text only)

Examples:
```
- `das` - Delete entire section
- `yis` - Yank section content  
- `cih` - Change heading text
```

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

### Additional Features

- **`<C-f>`** (Insert mode) - Insert footnote with interactive prompt
- **`<C-l>`** (Insert mode) - Insert reference link with interactive prompt

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

## Contributing

This plugin follows standard vim plugin conventions. The codebase is modularly organized:

- `ftplugin/markdown.vim` - Main mappings and initialization
- `autoload/md/core.vim` - Core functionality and text objects  
- `autoload/md/move.vim` - Navigation commands
- `autoload/md/line.vim` - Line-level parsing utilities

---

**mdpp.vim** - Making markdown editing as powerful as your ideas.

[test]: https://test.com

[^asdf]: This is better
