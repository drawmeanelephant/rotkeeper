---
title: "Template Golden Fixture"
description: "Deterministic CommonMark probe page for template golden regression checks"
template: theme-spooky-dark.html
---

# Template Golden Fixture

This page exercises the template-rendering surface with CommonMark-safe
structures only: no task lists, no footnotes, no raw HTML. Template edits that
change the wrapped DOM will diverge from the checked-in goldens.

## Inline Surface

Regular paragraph with **bold**, *italic*, ***both***, `inline code`, a
[link](my-first-page.md), and an external <https://example.com/autolink>.

## GFM Table

| Left | Center | Right |
| :--- | :----: | ----: |
| a \| b | *mid* | 3 |

## Code Fence

```zig
pub fn main() void {
    std.debug.print("rotkeeper\n", .{});
}
```

## Blocks

> First quoted line.
>
> > Nested quote survives.

- alpha
- beta
  - gamma

1. first
2. second

---

Closing paragraph after a thematic break.
