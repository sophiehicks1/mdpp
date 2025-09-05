# Footnote Wrapping Test

This is a test to verify that footnote content wrapped by vim's textwidth setting displays correctly[^1].

Another test with a simple footnote[^2].

[^1]: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco
    laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
    cillum dolore eu fugiat nulla pariatur.

[^2]: This is a simple footnote that fits on one line.

## Expected Behavior

When you position your cursor on [^1] and display the footnote, it should show as one continuous paragraph instead of three separate lines.

When you position your cursor on [^2], it should display normally as a single line.