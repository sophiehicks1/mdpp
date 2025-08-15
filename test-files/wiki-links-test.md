# Wiki Link Text Objects Manual Test

This document can be used to manually test wiki link text objects:

Simple wiki link: [[Target]]
Wiki link with alias: [[Target|Alias]]
Wiki link with anchor: [[Page#Section|Display Text]]
Complex path: [[path/to/file.md#anchor|Nice Name]]

Mixed content: This has a [[wiki link]] and a [regular link](http://example.com).

Multiple links: [[First]], [[Second|Display]], and [[Third#section|Name]].

## Manual Testing Instructions

1. Open this file in Vim with the mdpp plugin loaded
2. Position cursor inside any wiki link
3. Test these text objects:
   - `vil` or `yil` - should select the display text (alias if present, target if not)
   - `val` or `yal` - should select around the display text  
   - `viu` or `yiu` - should select the target portion
   - `vau` or `yau` - should select around the target portion
   - `viL` or `yiL` - should select inside the entire link (excluding [[]])
   - `vaL` or `yaL` - should select the entire link (including [[]])

## Expected Results

For `[[Target|Alias]]`:
- `il` selects: `Alias`
- `al` selects: `Alias` 
- `iu` selects: `Target`
- `au` selects: `Target`
- `iL` selects: `Target|Alias`
- `aL` selects: `[[Target|Alias]]`

For `[[Target]]`:
- `il` selects: `Target`
- `al` selects: `Target`
- `iu` selects: `Target` 
- `au` selects: `Target`
- `iL` selects: `Target`
- `aL` selects: `[[Target]]`