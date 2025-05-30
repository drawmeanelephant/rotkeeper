# 🧾 GPT-BURNLIST.md
## Ritual Usage Guide for GPT-4.5 within the Rotkeeper System

This list organizes high-yield GPT-4.5 tasks into thematic categories. 
Use each one when Kindy workflows need enhancement, optimization, or spiritual realignment.

---

## 🔧 1. TEMPLATE SMITHING

- [ ] Refactor a Pandoc template to support $custom_variable$ in a new section. ❌
  > “Can you modify this Pandoc template to support `$emotional_residue$` as a sidebar field?”

- [ ] Flatten a complex `$for$` loop into plain HTML with placeholder comments for static Tikiwiki use. 🟡
  > “Rewrite this loop into hardcoded HTML with comments like `<!-- repeat block -->`.”

- [ ] Add legacy browser support (blink tags, marquee fallbacks) to an existing HTML template. ❌
  > “Make this HTML template intentionally work badly in old browsers.”

---

## 📜 2. SCRIPT ENHANCEMENT (rc-render.sh)

- [ ] Add dry-run mode with a `--dry-run` flag that logs actions but makes no output. ✅
  > “Add dry-run support to this Bash script. It should log what would happen, but not render.”

- [ ] Optimize the `find | while read` loop to render in parallel. ❌
  > “Convert this Bash loop to use `xargs -P 4` for parallel Pandoc rendering.”

- [ ] Add fail-fast logic: exit if required template is missing. ✅
  > “Add an early exit condition to this Bash script if the specified Pandoc template isn’t found.”

- [ ] Add banner/emoji output per file rendered for mood logging. 🟡
  > “Can you add echo output with emoji showing success/failure for each file rendered?”

---

## 📇 3. METADATA VALIDATION

- [ ] Create a Bash/Python tool that scans Markdown files and checks for required frontmatter fields. ✅
  > “Write a script that checks all `.md` files for presence of `title`, `template`, and `mascot_id` fields.”

- [ ] Suggest a canonical schema for mascot metadata in YAML frontmatter. 🟡
  > “What’s a clean YAML frontmatter schema for tracking fictional mascots in an archive project?”

- [ ] Convert old frontmatter formats to the new normalized structure. ✅
  > “Refactor this set of frontmatter to match this new schema: [paste new example].”

---

## 🌀 4. AUTOMATION RITUALS

- [ ] Draft a GitHub Actions file that runs `rc-render.sh` on push and deploys with `rsync`. 🟡
  > “Make me a GitHub Actions workflow to run a static site render script and rsync to my server.”

- [ ] Create a `Makefile` or `justfile` to replace manual Kindy command chains. ❌
  > “Write a Makefile with targets like `make render`, `make bless`, and `make clean`.”

- [ ] Generate a Markdown report of last render session (total files, failures, time). ✅
  > “Add a render summary log at the end of my Bash script showing files rendered and total time.”

---

## 🪦 5. RENDERED OUTPUT EXTENSIONS

- [ ] Add Pandoc commands for multi-format output (PDF, EPUB, DOCX). ❌
  > “Modify this script so it renders `.html` and `.pdf` versions of each file using Pandoc.”

- [ ] Generate a README index of all mascot pages with titles and corruption levels. ❌
  > “Create a Markdown table listing all mascots with their `$title$` and `$corruption_level$`.”

- [ ] Create a `404.html` page using an abandoned mascot and sad haiku. ❌
  > “Write a 404 page in the style of my project with a corrupted mascot and a funeral haiku.”

---

## 🗂 6. BONUS CHAOS TASKS (Low Priority, High Flavor)

- [ ] Add hidden comments to rendered HTML for future AI archaeologists. ✅
  > “Insert `<!-- filed under protest -->` or `<!-- system believes this never happened -->` in rendered output.”

- [ ] Draft ceremonial language for a mascot's metadata error report. 🟡
  > “Write an error message for when a mascot’s YAML frontmatter is malformed, but in a tragic tone.”

- [ ] Refactor mascot biographies into Markdown haikus. ❌
  > “Convert this mascot biography into three haikus that retain the core meaning.”

---

## 🧬 Usage Tips

- Use copy-paste blocks, not full scripts unless you're debugging.
- Ask for *diffs only* when refining code to save tokens.
- Chain context: if GPT rewrites a block, ask follow-ups on that only.

🧾 Track what’s filed. Let nothing escape the index.
