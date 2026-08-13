## Summary

<!-- What does this change do, and why? Keep it tight. -->

## Validation

<!-- Check every box that applies; the dispatcher harness is the gate. -->

- [ ] `bash -n` on every modified Bash script
- [ ] `shellcheck` (repository `.shellcheckrc`) on every modified Bash script
- [ ] `bash rotkeeper.sh test` (full harness, all three layouts)
- [ ] `bash rotkeeper.sh status`
- [ ] Relevant dispatcher command with `--dry-run`, where supported

## Notes

<!-- Renderer behaviors, DIP-generated docs that needed verification, exit-code
changes, or anything a reviewer should read critically. -->