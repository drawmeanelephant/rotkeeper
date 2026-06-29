---
title: "Config Folder"
description: "Describes parameters, schemas, and skipping whitelists."
status: "complete"
---

### Architectural Intent
The `bones/config/` directory acts as the centralized vault for validation parameters, runtime behavior constraints, and rigid project boundaries. It dictates the configuration for the dispatcher (`rotkeeper.sh`) and our archaic build rituals. This is where you declare the rules of the engine, not where you write the code to enforce them. If the engine behaves unexpectedly, start your autopsy here.

### Directory / File Schema Expectations
This directory is a pristine configuration schema, not a dumping ground. Ad-hoc scripts or spontaneous code files are strictly prohibited. The structural expectation dictates the following core assets:
- `rotkeeper.yaml`: The primary YAML configuration file. It binds critical parameters like site title, description, and the default Pandoc layout template.
- `dip-whitelist.txt`: A plain-text, newline-delimited manifest of file paths explicitly shielded from the destructive obsolete-purging capabilities of `rc-dip.sh`.
