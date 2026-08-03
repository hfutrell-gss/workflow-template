# ADR-0009: Composition: the core plus packs

**Status:** Accepted
**Date:** 2026-08-01
**Authors:** henning
**Deciders:** henning

**Scope (repos affected):**

- `workflow-template` — the core itself
- every derivation — receives this through the managed set

---

## What changed

The template was a single parent, vendored wholesale. It is now a **core** plus any
number of **packs**.

- `pack.yaml` (`name`, `version`, `provides:`) is a pack's manifest. The core keeps
  `template-manifest.yaml` (`managed:`) and its `VERSION`; both forms read through one
  code path, so nothing below `manifest_file()` branches on the kind.
- `packs.yaml` declares a repo's packs; `packs.lock` records the version and **exact
  installed path list** of each.
- `template-sync.sh` gained `add`, `remove`, `list`, `--audit`; `update` now iterates the
  core and every pack.
- `craft-*` left the core for **pack-craft** — 146,427 B of a 363,408 B managed set, 40%
  of the "core", none of it mechanism.

## Why not more inheritance

The prior design was not really inheritance — no dispatch, no base-class callbacks, just
vendoring — so the fragile-base-class argument never applied cleanly. Two real failures
did:

1. **Single parent.** There was no way to say "add this repo too."
2. **Bespoke extension points.** Four override conventions had been invented one at a
   time (`.agents/craft/<skill>.local.md`, `.agents/orchestrate/*.local.*`,
   `.agents/init/tools.local.d/`, `GLOSSARY.local.md`) because each new piece of opinion
   needed its own escape hatch.

The disagreement worth recording: "even the core should be configurable" is wrong in its
strong form. Something must define the shapes a pack plugs into, and that thing cannot
itself be a plugin. The core is therefore **minimal and invariant** — shapes and the
operations on them — and everything that is a guess about someone's area of work is a
pack they can decline.

## Path removal — the ten-version orphan bug, fixed

`copy_managed_paths` only ever added or overwrote. A path retired upstream sat on disk in
every derivation forever; v8's skills refactor left orphaned scripts that were still
being tripped over. The SKILL.md documented it as a known caveat and proposed a "retired
paths" list.

No list was needed. The previously-installed path set was already recoverable:

- **For a pack** — `packs.lock` holds it.
- **For the core** — the derivation's own copy of `template-manifest.yaml` holds it,
  because the manifest is itself a managed path. Read it *before* the overwrite.

`removed = old − new`, then delete, then prune emptied parents. Verified both directions:
dropping `craft-event-naming` from `pack.yaml` deleted it on the next `update`; a
simulated v29→v30 core update deleted the craft paths the core gave up.

## Invariants, and why each is enforced rather than advised

| Invariant | Enforcement |
|---|---|
| One owner per path | refused at `add` **before any write**, re-checked offline as `PACK-001` |
| A dropped path is removed | `update`, both kinds |
| No inter-pack dependencies | no resolver exists to write one |

A collision resolved by copy order is a collision nobody can see. That is the failure
mode that sinks plugin systems, so it is an error at both ends, never a merge.

New rules: `PACK-001` (collision), `PACK-002` (a claimed path is missing — half-applied
update), `PACK-003` (declaration and installation disagree — a hand-edited `packs.yaml`).
`--audit` is deliberately **offline**: no upstream contact, so it stays cheap and works
with no network. Version drift stays `TEMPLATE-*`, which does contact upstreams.

## Two aggregator bugs found while wiring PACK-*

`check.sh` reported `agents-sync.sh` and `template-sync.sh --check` as **ERROR (exit 1)**
— a tool defect — when both exit 1 to mean "not conforming", which is a constraint
result. Both moved to `run_nonzero_is_violation`. The lesson generalizes: a checker's
exit convention is part of its contract with the aggregator, and getting it wrong hides
real violations behind a word that means "ignore this".

## Rejected

- **Inter-pack dependencies.** Version solving for four skills is not a trade worth
  making. A pack that needs another pack's file wants the wrong shape.
- **A new `/workflow-packs` skill.** Two tools operating on the same shape violates the
  categorical rule. `workflow-template-sync` already owned "copy a managed set from an
  upstream"; this is that operation, generalized.
- **Renaming the skill.** `workflow-template-sync` now covers more than the template
  link, but a rename costs every derivation's stub for a naming improvement.

## Action items

1. `pack-craft` exists only at `workspace/pack-craft` with no remote. Create the
   repository and push it; until then every workflow repo must register it by local path.
