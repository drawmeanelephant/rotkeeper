---
target_file: "bones/scripts/rc-oliver-adapter.sh"
reviewed: "2026-10-01"
reviewed_against: "0.8.1"
---

### Design

This internal batch worker is reached through `bash rotkeeper.sh render`,
not a separate dispatcher command. It reads the TSV plan produced by Oliver,
checks source and destination boundaries, extracts metadata with `oliver
meta`, renders a body, and wraps it with `oliver wrap`.

Nonempty sidecar fields override title, description, author, date, template,
and palette. The adapter reads subtitle, tags, and asset metadata with `yq`;
sidecar subtitle also takes precedence. It joins tags and asset metadata
into display strings, injects the loaded Rotkeeper version, and merges
additional source frontmatter keys with those typed values taking precedence.
See the [Oliver contract](../../oliver-contract.html).

For Docs and Help pages, shared helpers add navigation from the current batch
inventory and normalize body H1 headings before wrapping. A literal
`<site-nav></site-nav>` slot is filled from site configuration after wrapping.

### Limits

The source extension forces `.textile` or `.cook` input; other sources use
the configured input format. `render_profile` comes from page frontmatter or
the site default, not sidecar metadata. Selecting an XHTML body profile does
not select an XHTML wrapper automatically. See the
[XHTML profile](../../xhtml-profile.html).

The script has no static help block or standalone command interface. A
manifest row marked dry-run still extracts metadata and renders the body,
but skips wrapping and page writes. The dispatcher's `render --dry-run`
does not execute this worker at all.

### Cautions

The adapter rejects source, destination, sidecar, and final template paths
outside their respective boundaries. An invalid metadata-selected template
leaves the planned template in use; the final template must still exist
inside the template directory.

Metadata and body scratch files, warning accumulators, and bootstrap logs
are filesystem writes. Body-render failure stops the batch without writing
that page. Wrapping writes directly to the destination; on wrap failure the
adapter removes the destination, including a previously rendered copy.

Renderer stderr is logged separately from the body. Raw HTML rejected under
XHTML stops the page and produces guidance rather than a repaired document.
