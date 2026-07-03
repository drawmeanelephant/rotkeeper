---
title: "JavaScript Assets"
description: "Minimalist client-side scripts, if required by the author."
status: "complete"
---

### Architectural Intent
The `home/assets/js/` directory allows users to supply custom client-side behavior, though Rotkeeper fundamentally avoids relying on JS for structural layout.

### Directory / File Schema Expectations
Standard `.js` files. Must strictly avoid overriding framework hydration paradigms to comply with Rotkeeper's zero-hydration constraint.
