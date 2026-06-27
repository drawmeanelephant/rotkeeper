---
target_file: bones/config/rotkeeper.yaml
source: generated
generated: 2026-06-27
model: jules-model
version: 0.1.0
status: final
---

### Bones of the Code
The central configuration file for Rotkeeper's build process. It defines site variables, metadata defaults, theme styling switches, and paths used during static site generation.

### Restless Spirits
Errors or typos in the YAML syntax (such as indentation or missing quotes) will cause `yq` parsing to collapse, breaking script configurations and halts execution.

### Ritual Warnings
Validate this file against standard YAML rules after editing. Ensure directory keys match the paths configured in the environment variables.
