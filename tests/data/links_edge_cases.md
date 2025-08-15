# Edge Cases for Links

## Nested Brackets and Parentheses

Deep nesting: [Link with [[double]] nested brackets](https://example.com)
Parentheses: [URL with (nested (deep) parens)](https://example.com/path(with)nested(parens))

## Malformed Links

Missing closing bracket: [incomplete link
Missing closing paren: [text](https://incomplete.com
Unmatched brackets: [text]]](https://example.com)

## Empty and Minimal Cases

Empty text: [](https://example.com)
Empty URL: [text]()
Just brackets: []
Just parens: ()

## Special Characters

Unicode in text: [Link with émojis 🔗](https://example.com)
Special chars in URL: [Special](https://example.com/path?query=value&other=true#fragment)

## Reference Edge Cases

[undefined]: 
[missing-definition]: https://example.com

Reference to undefined: [Undefined Link][nonexistent]
Self-referencing: [self][self]

[self]: https://example.com/self