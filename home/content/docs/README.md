---
title: "Repository overview"
description: "The README entry point and the basic Rotkeeper workflow."
template: rotkeeper-doc.html
reviewed: "2026-10-01"
---

# Repository overview

[README.md](https://github.com/drawmeanelephant/rotkeeper/blob/main/README.md)
is the repository entry point. It introduces Rotkeeper, the system/content/output
layout, requirements, setup, and the command list.

Rotkeeper uses Bash and Oliver to turn flat-file content into static HTML.
It does not require Node or an application framework. In the default
layout, source content is under `home/content`, assets under `home/assets`,
and generated pages under `output`.

## Starting a site

```bash
bash rotkeeper.sh preflight
bash rotkeeper.sh init --with-sample
bash rotkeeper.sh render
bash rotkeeper.sh status
```

Use the [workflow guide](workflow.html) for the full sequence and the
[Oliver contract](oliver-contract.html) for renderer setup. Read the
[agent operating manual reference](AGENTS.html) before changing the project.
