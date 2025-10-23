# Link Test Document

This document contains various types of markdown links for testing.

## Inline Links

Simple inline link: [Google](https://google.com)
Inline link with title: [Google with title](https://google.com "Google Search")
Link with spaces in URL: [Spaced URL](https://example.com/path with spaces)

Multiple links on same line: [First](https://first.com) and [Second](https://second.com)

## Reference Links

Simple reference link: [Google][google]
Implicit reference link: [GitHub][]
Reference with different text: [Search Engine][google]

Multiple reference links: [GitHub][] and [Google][google] on same line.

## Reference Definitions

[google]: https://google.com
[GitHub]: https://github.com
[nested]: https://example.com/nested

## Complex Cases

Nested brackets in text: [Link with [nested] brackets](https://example.com)
Nested parentheses in URL: [Complex URL](https://example.com/(nested))
Empty link text: [](https://example.com)
Empty reference: [Empty][]

## Edge Cases

Almost a link but not: [text](not-a-url
Malformed reference: [text][missing-ref]
Link at line start: [Start Link](https://start.com)
Link at line end: Text ending with [End Link](https://end.com)

[Empty]: 

Text with multiple [inline](https://inline.com) and [reference][google] links mixed together.
