---
title: "Assets Base Directory"
description: "Root directory for frontend static assets"
status: "OK"
---

### Architectural Intent
This directory holds raw CSS, JS, and image assets deliberately excluded from automatic documentation generation by DIP, to prevent noise. The core intent is to store static styling and minor scripts without any compilation pipeline.

### Directory / File Schema Expectations
Subdirectories strictly categorize assets by type (css, js, images). No frameworks or preprocessing dependencies are allowed here.
