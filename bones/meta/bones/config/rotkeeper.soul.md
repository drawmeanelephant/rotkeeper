---
title: "Rotkeeper Config"
description: "Definitive rules for templates and site settings."
status: "complete"
---

### Architectural Intent
The central configuration file for Rotkeeper's build process. It defines site variables, metadata defaults, theme styling switches, and paths used during static site generation.

### Directory / File Schema Expectations
Errors or typos in the YAML syntax (such as indentation or missing quotes) will cause `yq` parsing to collapse, breaking script configurations and halts execution. Validate this file against standard YAML rules after editing. Ensure directory keys match the paths configured in the environment variables.

## Necromancer's Notes
<!-- DIP-SOUL-EXTRACTED: 2026-07-13T23:16:45Z -->


### Architectural Intent
The central configuration file for Rotkeeper's build process. It defines site variables, metadata defaults, theme styling switches, and paths used during static site generation.

### Directory / File Schema Expectations
Errors or typos in the YAML syntax (such as indentation or missing quotes) will cause `yq` parsing to collapse, breaking script configurations and halts execution. Validate this file against standard YAML rules after editing. Ensure directory keys match the paths configured in the environment variables.
