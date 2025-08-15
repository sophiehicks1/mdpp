# Final Test for Footnote Functionality

This document demonstrates the footnote functionality implemented in the mdpp plugin.

## Basic Footnotes

Here's a sentence with a simple footnote[^1].

Here's another sentence with a different footnote[^note2].

Multiple references to the same footnote[^shared] can be used[^shared].

## Complex Footnotes

This footnote has complex content[^complex].

## Testing Instructions

1. Position cursor on any footnote reference (e.g., `[^1]`)
2. Press `<leader>f` (usually `\f`)
3. In Neovim: A floating window should appear with footnote content
4. In Vim: A warning message should appear

## Footnote Definitions

[^1]: This is a simple footnote with basic text.

[^note2]: This footnote has a longer identifier and demonstrates that footnote IDs can contain letters and numbers.

[^shared]: This footnote is referenced multiple times from different locations in the document.

[^complex]: This footnote contains **bold text**, *italic text*, and even [a link](http://example.com) to demonstrate that footnote content can include markdown formatting.