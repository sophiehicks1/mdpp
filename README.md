# mdpp.vim - Markdown Power Plugin

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

- **`]s`/`[s`** - Next/previous heading (any level)
- **`]]`/`[[`** - Next/previous sibling heading (same level)
- **`)`/`(`** - First child/parent heading
- **`]h`/`[h`** - Move between headings with visual feedback

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

## Installation

### Using vim-plug:
```vim
Plug 'sophiehicks1/mdpp'

### Using Vundle:
```vim
Plugin 'your-username/mdpp.vim'
Plugin 'sophiehicks1/repl.vim'  " Optional
```

## Configuration

### Basic Setup
```vim
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

- **Core functionality**: Vim 7.4+ (no external dependencies)

## Tips & Tricks

1. **Combine text objects with operators**: `d]s` deletes from cursor to next section
2. **Use counts with movements**: `3]]` jumps 3 sibling headings forward  
3. **Visual mode works**: Select text then use navigation commands

## Contributing

This plugin follows standard vim plugin conventions. The codebase is modularly organized:

- `ftplugin/markdown.vim` - Main mappings and initialization
- `autoload/md/core.vim` - Core functionality and text objects  
- `autoload/md/move.vim` - Navigation commands
- `autoload/md/line.vim` - Line-level parsing utilities
- `autoload/md/repl.vim` - REPL integration
- `autoload/md/str.vim` - String manipulation helpers

## License

[Your chosen license here]

---

**mdpp.vim** - Making markdown editing as powerful as your ideas.
