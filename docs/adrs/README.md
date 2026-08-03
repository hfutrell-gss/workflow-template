# ADRs — workflow-template

Architecture Decision Records for **this repo's own shape** — why the core is built the way
it is. One file per decision; never a growing file.

A decision that constrains more than one repo belongs in the `architecture` repo's
system-level set, not here (`architecture/AGENTS.md` §1.2). The core is a subtle case: a core
decision does propagate to every derivation, so core ADRs name them under **Scope** — but the
derivations are not part of the system `architecture` catalogues, so these stay per-repo.

**Start from [`0000-adr-template.md`](0000-adr-template.md).** It is managed by the core, so
it is identical in every derivation. Conventions — four-digit numbering, immutable numbers,
status transitions, allocating the next number just before commit — are in its trailing
comment.

Add a row below in the same commit as the ADR.

| # | Title | Status | Date |
|---|-------|--------|------|
| [0001](0001-gateway-claude-models.md) | Gateway Claude model selection | Accepted | 2026-07-28 |
| [0002](0002-craft-enforcement.md) | Craft enforcement: push the rules into the build | Accepted | 2026-07-29 |
| [0003](0003-craft-ratchet.md) | Craft ratchet: a path from non-compliant substrate to the mandates | Accepted | 2026-07-29 |
| [0004](0004-craft-skills.md) | Craft skills: code quality and TDD doctrine | Accepted | 2026-07-29 |
| [0005](0005-craft-covenants.md) | Craft covenants | Accepted | 2026-07-30 |
| [0006](0006-derivation-tool-overlays.md) | Derivation-owned tool overlays for `workflow-init` | Accepted | 2026-07-30 |
| [0007](0007-orchestrate.md) | Task-based orchestration bound to tiers, not model names | Accepted | 2026-07-30 |
| [0008](0008-orchestrate-run-layout.md) | Split procedure from run, and add the reaping gate | Accepted | 2026-07-31 |
| [0009](0009-packs.md) | Composition: the core plus packs | Accepted | 2026-08-01 |
| [0010](0010-code-craft-published.md) | The first pack, published | Accepted | 2026-08-01 |
| [0011](0011-ledger-and-journal.md) | The run ledger, and what the decision record is for | Accepted — its name for the record superseded by 0013 | 2026-08-01 |
| [0012](0012-no-routed-provider.md) | The core names no model provider | Accepted | 2026-08-01 |
| [0013](0013-adrs-not-a-journal.md) | Decision records are ADRs, in `docs/adrs/`, not a "journal" | Accepted | 2026-08-03 |
