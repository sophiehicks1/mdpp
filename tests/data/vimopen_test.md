# Test file for vim-open integration

[Regular file link](./example.md)
[Another file](../docs/readme.txt)
[Website link](https://example.com)
[HTTP link](http://example.com/page.html)
[Home directory file](~/config.yaml)
[Absolute path](/etc/hosts)
[File with spaces](./my%20file.md)
[File with fragment](./file.md#section)
[File with query](./file.md?param=value)
[Complex file path](./docs/sub%20dir/file%20name.md#heading?search=test)

Reference style links:
[Reference to file][file-ref]
[Reference to website][web-ref]

Wiki style links:
[[Internal Page]]
[[docs/another-page]]

[file-ref]: ./referenced-file.md
[web-ref]: https://example.com/referenced-page

Some plain text with no links.

- [ ] A checkbox item with [embedded link](./todo.md)
- [x] Completed item with [web link](https://example.com)