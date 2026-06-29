---
title: "Doc Layout Template"
description: "Layout expectations for sidebar layouts and structural indices."
status: "complete"
---

### Architectural Intent
The primary Pandoc HTML template for rendering static documentation pages. It handles layout rendering, side navigation, headers, footers, and scripts integration.

### Directory / File Schema Expectations
It is deeply dependent on the CSS structures declared in `rotkeeper.css`. If layout classes are renamed in the stylesheet, the documentation grid layout will crumble. Modify this layout only when updating global documentation typography or page headers.
