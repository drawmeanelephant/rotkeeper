# ☠️ Rotkeeper Structural & Stability Audit — v0.2.4-dev

A living ledger of script rituals, docs, and decay states.

---

## ✅ Script Compliance Matrix

| Script              | `main()` | `trap` | `init_log` | `check_deps` | `--dry-run` | Docs? |
|---------------------|---------|--------|------------|---------------|-------------|--------|
| rc-api.sh           | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-assets.sh        | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-audit.sh         | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-bless.sh         | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-cleanup-bones.sh | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-docbook.sh       | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-docs-fix.sh      | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-verify.sh        | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-render.sh        | ✅      | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-test.sh          | ✅      | ✅     | ✅         | ✅            | ✅          | ⚠️ stub |
| rc-unpack.sh        | ⚠️ stub| ❌     | ❌         | ❌            | ❌          | ❌     |
| rc-expand.sh        | ✅     | ✅     | ✅         | ✅            | ✅          | ✅     |
| rc-pack.sh          | ✅     | ✅     | ✅         | ✅            | ✅          | ✅     |

---

## 📚 Docs Coverage

Every script now has a doc page **except**:

- `rc-unpack.sh`

---

## 📦 Pending Improvements (carryover or new)

- [x] Add `.vscode/extensions.json` with shell + YAML tooling
- [ ] Add footer component injection into rendered HTML
- [ ] Build `rc-expand.sh` YAML unpacker
- [ ] Add `--help` flag standardization across scripts

---

## 🧪 Peer Review (v0.2.3-pre)

A first-reader walkthrough and system critique, recorded from the perspective of a curious outsider encountering `rotkeeper-manual.md` for the first time.

### Perspective
A mix of puzzled hacker and occult documentation anthropologist. The goal: decipher what this system is, what it assumes, and when it begins to feel usable.

### Observations

1. **The project is metaphoric by design.**
   Files aren’t just rendered — they’re entombed. Docs aren’t hosted — they’re embalmed. This is not a CMS. It’s a static death engine.

2. **`rc-scriptbook.sh` gives a strong overview.**
   It pulls every script’s doc-comments into a unified manual, which reads like scripture. It’s strange and wonderful.

3. **But there’s no clear starting point.**
   The ritual sequence (expand → render → pack) is implied, not taught. First-time users have to piece together the path from comments and osmosis.

4. **Glossary and flow diagram are missing.**
   Terms like “tomb”, “manifest”, and “blessing” are used consistently, but not defined. A flowchart would demystify a lot.

5. **Rendering and packing are modular, but not explained that way.**
   It *feels* like I can skip steps, but there’s no diagram or doc explaining what is truly required.

### Suggested Artifacts

- `rotkeeper-peer-review.md` (archived here instead)
- `rotkeeper-flow.md` (proposed, but unmade)
- `rotkeeper-first-ritual.md` (starter pack, TBD)
- Glossary stub for internal use

This peer review is preserved in the audit so the project can remember what it looked like from the outside — before entropy set in.

---

## 📌 Followups

See `rotkeeper-followups.md` for all next-phase tasks, spec drafts, and unresolved system questions.
