# Indented Wrapped Links Test

This tests links that wrap across lines with indentation.

## List Items with Wrapped Links

- This is a root list item
  * This is a modestly long nested list item that ends with a [[relatively short
    link]]
  * Another nested item with an inline [file link text that
    wraps](./file.md)

## Deeper Nesting

- Level 1
  - Level 2
    - Level 3 with a [[deeply nested
      wrapped link]]
    - Another deep item with [inline link that
      spans lines](http://example.com)

## Blockquotes with Wrapped Links

> This is a quote with a [[wiki link
> that wraps]] across lines

> Another quote with an [inline link
> that wraps](./quoted-file.md)

## Mixed Indentation

  This is indented text with a [[wiki
  link]] that wraps

  More indented text with [inline
  link](./file.md)

## Reference Links with Indentation

- Item with [reference link
  text][ref1] that wraps
  - Nested with [another ref
    link][ref2]

[ref1]: ./referenced.md
[ref2]: http://example.com

## No indentation

This is some regular text, without indentation that ends with a link that [[spans
two lines]]

This is another chunk of regular text without indentation, but this one has [an
inline link](./inline-target.md)

Finally, we have one more chunk of non-indented text with a link. This is [a
reference link][ref3]

[ref3]: https://blah.com
