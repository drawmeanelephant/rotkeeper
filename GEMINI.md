# ✨ Gemini Core Directives for Rotkeeper

If you are a Gemini agent (or a specialized subagent spawned by Antigravity) working within this workspace, these are your core directives for modifying or assisting with the Rotkeeper project.

## Context
Rotkeeper is designed as a raw, terminal-driven flat-file system for compiling markdown "tombs" into static HTML archives. It relies heavily on bash scripting (the "rituals" in `bones/scripts/`), pandoc, and a strict separation of concerns.

## Golden Rules for Gemini Agents

1. **Do not break the Bash Scripts**: The core of Rotkeeper is its `.sh` scripts. When editing them, always preserve the `set -euo pipefail` architecture and the error trapping mechanics defined in `rc-utils.sh`.
2. **Respect the Subdirectories**:
   - `home/content/` is strictly for user markdown input.
   - `output/` is strictly for generated HTML. Do not edit files here manually; instead, edit the source markdown or templates.
   - `bones/scripts/` is where the system logic lives.
3. **Use the Dispatcher**: You should almost never invoke `bones/scripts/rc-*.sh` directly. Instead, run `./rotkeeper.sh <command>`. Use `./rotkeeper.sh help` to see available actions.
4. **Agent Testing (`lite` distribution)**: If tasked with testing the framework as a blind agent, you'll be operating in the `lite` distribution which strips out `README.md` and most docs. Rely on this `GEMINI.md` or `AGENTS.md` file, and the output of `./rotkeeper.sh help` to navigate.

## Workflow Example
If the user asks you to build a new feature (e.g., an "audit" command):
1. Add the dispatcher hook in `rotkeeper.sh`.
2. Create `bones/scripts/rc-audit.sh` using `rc-utils.sh` as a base.
3. Ensure it writes logs to `bones/logs/` using `init_log`.
4. Test it thoroughly using your terminal tools.
