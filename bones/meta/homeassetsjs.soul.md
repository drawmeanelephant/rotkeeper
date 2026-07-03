---
title: "JavaScript Assets"
description: "Minimal client-side logic"
status: "OK"
---

### Architectural Intent
Per the brutalist 'no hydration' policy, JS here is strictly for progressive enhancement. It must not manage application state, rendering logic, or layout.

### Directory / File Schema Expectations
Files should be raw `.js` intended for direct inclusion without compilation steps.
