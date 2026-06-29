---
title: "Root Workspace"
description: "Maps top-level scripts, Git wrappers, and root entry-points."
status: "complete"
---

### Architectural Intent
The primary dispatcher for the Rotkeeper system. It acts as the gateway cli to bootstrap the environment, invoke scripts like `rc-init.sh`, `rc-render.sh`, `rc-dip.sh`, and `rc-release.sh`, and coordinate test suites.

### Directory / File Schema Expectations
It is a wrapper with high expectations. It requires `rc-utils.sh` and `rc-env.sh` to exist in the same directory, failing immediately if the environment variables are not populated. If child scripts exit with unhandled errors, it occasionally fails to report the specific failure origin. Always execute `rotkeeper.sh` from the workspace root or ensure script directories are accessible. Verify environment paths, or the dispatcher will fail to bootstrap.
