# Multi-line Link Test Document

This document contains links that span multiple lines.

## Wiki Links

Simple wiki link on one line: [[simple wiki]]

Wiki link that wraps: This line has a link at the end [[modest link
with 5 words]] that continues on next line.

Wiki link at start of line [[another link that
spans lines]] followed by text.

## Inline Links

Simple inline link: [simple](http://example.com)

Inline link with wrapped text: [this is a link that
spans multiple lines](http://example.com)

Inline link with wrapped URL: [short text](http://example.com/very/long/url
/that/continues/on/next/line)

Inline link both wrapped: [this link has both text
and URL wrapped](http://example.com/long/url
/continued/here)

Inline at line end [link text
wraps](http://example.com)

## Reference Links

Simple reference: [simple][ref1]

Reference with wrapped text: [this reference text
spans multiple lines][ref2]

Reference at line end [wrapped reference
text][ref3]

## Reference Definitions

[ref1]: http://example.com/simple
[ref2]: http://example.com/multiline
[ref3]: http://example.com/endline

## Mixed Content

Here is text with an inline [wrapped inline link
text](http://inline.com) and a reference [wrapped reference
link][ref1] on the same lines.

## Edge Cases

Multiple wrapped links: [first wrapped
link](http://first.com) and [second wrapped
link](http://second.com)

Link that starts and ends on different lines [[wiki
link]] with [inline
link](http://example.com) together.

Just barely fits on one line: [this text is long enough to wrap
](http://example.com)

Empty wrapped text: [
](http://example.com)
