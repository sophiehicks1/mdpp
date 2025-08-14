# Markdown Links Test File

## Inline Links

Simple inline link: [example](http://example.com)
Link with title: [example with title](http://example.com "Example Title")
Link with complex text: [**bold text** and *italic*](http://example.com)

## Multi-line Inline Links

Multi-line text: [this is a link that
spans multiple lines](http://example.com)

Multi-line URL: [example](http://example.com/very/long/url/that/might/span
/multiple/lines)

## Reference Links

Simple reference: [example reference][ref1]
Implicit reference: [example][]
Complex text reference: [**bold** and *italic* text][ref2]

Multi-line reference text: [this reference text
spans multiple lines][ref3]

## Reference Definitions

[ref1]: http://example.com
[ref2]: http://example.com/complex "Title"
[ref3]: http://example.com/multiline
[example]: http://implicit-example.com

## Mixed Content

Here's a paragraph with [inline link](http://inline.com) and 
[reference link][ref1] in the same content.

## Edge Cases

Link at start of line:
[start](http://start.com) of line

Link at end of line [end](http://end.com)

Multiple links: [first](http://first.com) and [second](http://second.com)

Nested brackets: [text with [brackets]](http://nested.com)

Empty text: [](http://empty-text.com)