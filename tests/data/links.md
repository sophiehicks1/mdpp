# Links Test Data

## Basic Inline Links

Simple inline link: [example](http://example.com)
Link with title: [example with title](http://example.com "Example Title")
Link with complex text: [**bold text** and *italic*](http://example.com)
Multiple links: [first](http://first.com) and [second](http://second.com)

## Basic Reference Links

Simple reference: [example reference][ref1]
Implicit reference: [example][]
Complex text reference: [**bold** and *italic* text][ref2]

## Reference Definitions

[ref1]: http://example.com
[ref2]: http://example.com/complex "Title"
[example]: http://implicit-example.com

## Edge Cases

Link at start of line:
[start](http://start.com) of line

Link at end of line [end](http://end.com)

Empty text: [](http://empty-text.com)
Nested brackets: [text with [brackets]](http://nested.com)
Link with parentheses in URL: [test](http://example.com/path(with)parens)

## Malformed Links

Just brackets: [not a link]
Just reference: [not a reference][missing]
Unmatched brackets: [unmatched
Unmatched parentheses: [test](unmatched

## No Links

This is just plain text.
Some text with brackets [but no links] and (parentheses).