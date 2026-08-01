---
name: upstream-workflow-management
description: Promote a generalizable concept from this derivation to the upstream template. Use when a fix, doctrine change, script change, or new skill in this repo would be correct in every derivation — or when a managed file was edited in place and the edit must be turned into an upstream release instead of drift. Covers the promotion test, the release steps, convergence, and the update gate.
---

# upstream-workflow-management

The TTPs for moving a concept up: from something learned in one derivation to
something every derivation inherits.

**Application:** `self` — this workflow acts on the derivation it lives in, and on the
template that derivation points at.

## Why this exists

The categorical rule says the template owns every operation on its shapes. A derivation
that edits a managed file in place has not corrected the template. It has created
drift, and the next `update` either reverts the fix or conflicts with it. The correct
move is always the same: make the change upstream, release it, pull it back.

That move has steps that are easy to do in the wrong order and easy to leave half done.
This workflow states them.

## The promotion test

Promote only what passes all four:

1. **General.** The concept holds for a derivation whose area of work you know nothing
   about. A rule that names this derivation's applications is doctrine, not template
   material.
2. **Shaped, not opinionated.** The core owns shapes and operations, and nothing else.
   Opinion goes in a **pack** — the `code-craft` pack is the worked example — and every pack
   ships a derivation-owned overlay slot that wins over it. "This is general but it is an
   opinion" is not a reason to skip promotion; it is the answer to *which repo*.
3. **Owned by a managed set.** Check the destination's manifest —
   `template-manifest.yaml` for the core, `pack.yaml` for a pack. If the target path is
   not managed, `update` will never carry it, and the change belongs here, not upstream.
   Say so rather than shipping it into a file no repo reads.
4. **Evidenced.** The concept came from real work, not from speculation. Record what
   made it necessary.

A concept that fails 1 belongs in this repo's `AGENTS.md`. A concept that fails 3 needs
a manifest entry first, or a different home.

**Choosing the destination.** Ask what breaks without it:

| If the concept… | It goes in |
|---|---|
| defines a shape, or an operation on one | the core |
| is engineering opinion about how code is written | the `code-craft` pack |
| is opinion about something else, general, and nothing existing owns it | a new pack |
| names this derivation's applications | this repo's `AGENTS.md` — not upstream |

A new pack is cheap: a repo, a `pack.yaml`, and the paths it claims. Adding opinion to
the core because no pack exists yet is the failure this structure was built to stop.

## Procedure

Full step list, including the failure modes that cost the most time:
`references/promotion.md`. In short:

1. Open a session. A promotion is a run against the application `self`, not an inline
   checklist: `orchestrate.sh init upstream-workflow-management self <slug>`. The steps
   below become its tasks, and the DoD gate applies to them.
2. Bind the template. It is a standing bind in `binds.yaml` with `kind: upstream`,
   cloned to `workspace/workflow-template`. Confirm `.template.lock` names a reachable
   upstream and that you can push to it.
3. Make the change upstream, in `workspace/workflow-template`. Never in the derivation's
   own managed copy.
4. Bump the version: `VERSION` **and** `template-manifest.yaml`'s `version:` for the
   core, or `pack.yaml`'s `version:` for a pack. Confirm every new path is covered by the
   manifest **before** you bump, or `update` will skip the new file in every repo. Most
   new files land inside a `path/**` glob and need no new entry — verify coverage rather
   than adding one (`references/promotion.md` §3 gives the check that works for globs).
   Removing a path from the manifest deletes it downstream — intended, and worth stating
   in the commit.
5. Run the checks the change touches: `agents-sync.sh`, `bash -n` on any script,
   `orchestrate.sh status` on a live session. Each check records its output as
   `evidence:` on its task.
6. Push.
7. Converge the derivation. Prefer `workflow-template-sync update`. When `update` is
   gated, hand-apply only the bytes that match upstream exactly, and record that the
   copy is converged rather than edited.
8. State any gate that remains — a stale script in the derivation, a live session that
   blocks the update — instead of leaving it to be discovered.
9. Close the session with `orchestrate.sh close`, which writes the ledger line into
   `self/tasks.md` `## History` and deletes the session directory.

## What this workflow refuses

- **Contribution tooling.** Ordinary git against a reachable upstream is enough.
- **Silent drift.** A managed file edited in place, with no upstream change, is a
  defect this workflow exists to prevent.
- **Bumping VERSION for a change that no manifest entry carries.** That ships a version
  number and nothing else.
