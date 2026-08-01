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
2. **Shaped, not opinionated.** The template owns shapes and operations. Where the
   template must carry opinion — the `craft-*` skills do — it ships with a
   derivation-owned overlay slot that wins over it.
3. **Owned by the managed set.** Check `template-manifest.yaml`. If the target path is
   not managed, `update` will never carry it, and the change belongs here, not
   upstream. Say so rather than shipping it into a file no derivation reads.
4. **Evidenced.** The concept came from real work, not from speculation. Record what
   made it necessary.

A concept that fails 1 belongs in this repo's `AGENTS.md`. A concept that fails 3 needs
a manifest entry first, or a different home.

## Procedure

Full step list, including the failure modes that cost the most time:
`references/promotion.md`. In short:

1. Bind the template. It is a standing bind in `binds.yaml` with `kind: upstream`,
   cloned to `workspace/workflow-template`. Confirm `.template.lock` names a reachable
   upstream and that you can push to it.
2. Make the change upstream, in `workspace/workflow-template`. Never in the derivation's
   own managed copy.
3. Bump `VERSION`, and `template-manifest.yaml`'s `version:` to match. Add any new path
   to the manifest **before** you bump, or `update` will skip the new file in every
   derivation.
4. Run the checks the change touches: `agents-sync.sh`, `bash -n` on any script,
   `orchestrate.sh status` on a live session.
5. Push.
6. Converge the derivation. Prefer `workflow-template-sync update`. When `update` is
   gated, hand-apply only the bytes that match upstream exactly, and record that the
   copy is converged rather than edited.
7. State any gate that remains — a stale script in the derivation, a live session that
   blocks the update — instead of leaving it to be discovered.

## What this workflow refuses

- **Contribution tooling.** Ordinary git against a reachable upstream is enough.
- **Silent drift.** A managed file edited in place, with no upstream change, is a
  defect this workflow exists to prevent.
- **Bumping VERSION for a change that no manifest entry carries.** That ships a version
  number and nothing else.
