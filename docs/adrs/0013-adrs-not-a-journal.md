# ADR-0013: Decision records are ADRs, in `docs/adrs/`, not a "journal"

**Status:** Accepted
**Date:** 2026-08-03
**Authors:** henning
**Deciders:** henning

**Scope (repos affected):**

- `workflow-template` — retires `journal/`, adds managed `docs/adrs/0000-adr-template.md`, rewrites the law that named the shape
- `stewardship`, `workflow-monolith`, `sandbox` — each renames its own records and renumbers them
- every future derivation — `derive` scaffolds `docs/adrs/` instead of `journal/`

---

## Context

The core invented the term **journal** for a shape that already had a name.

What the law actually described was: one dated file per decision **about this repo**, never
a single growing file, written when the reason would not survive in a diff, recording what
changed and why and what was rejected. That is an **Architecture Decision Record**. It has
been the name for this since Nygard, and this organisation already runs on it — roughly
twenty repos under `~/workbench` carry `docs/adrs/`, `architecture/adrs/` holds 77
system-level records, and `architecture/AGENTS.md` §3 is a written ADR discipline with
numbering, status transitions, promotion, and delivery rules.

Three costs, in order of severity:

1. **The invented word means the opposite of the shape.** A "journal" is ordinarily a
   running log — a chronological record appended to over time. The law explicitly forbade
   exactly that ("never one growing file"). A reader who had not read the law would infer
   the wrong shape from the name, and inferring shape from a name is what a name is *for*.
2. **It cost the organisation's convention.** Someone who writes ADRs in `identity` and
   then opens a workflow repo found a directory they did not recognise holding what they
   already knew how to write, under a heading set that varied file to file. Nothing about
   a workflow repo justifies a private convention here.
3. **The core preaches this exact rule and broke it.** `AGENTS.CORE.md`'s DDD section says
   *"name a term the first time it is ambiguous, not the third"* and *"two names for one
   concept is the defect, wherever it appears."* The core held two names for one concept
   and shipped the wrong one to every derivation.

Also found while fixing it: **nothing ever checked this shape.** There was no `check.sh`
constraint on the directory, the filenames, or the contents — so the one part of the system
with no enforcement was the part with the invented vocabulary.

## Decision

**Decision records in a workflow repo are ADRs, they live in `docs/adrs/`, and they follow
the house discipline in `architecture/AGENTS.md` §3.**

Specifically:

- `journal/` is retired. Existing records move to `docs/adrs/` and are renumbered.
- Filenames are `NNNN-kebab-title.md`, zero-padded to **four** digits. Four, not three,
  because these accumulate fast — the core alone reached 13 in six days, and `architecture`
  is at 77.
- Numbers and filenames are immutable once committed. Abandoned drafts land as
  `Status: Rejected`, never deleted. A superseded ADR is marked `Superseded by NNNN` and
  the file stays.
- Every ADR carries the header block from the template: Status, Date, Authors, Deciders,
  Scope.
- `docs/adrs/0000-adr-template.md` is **managed by the core**, so every derivation gets the
  same starting point and it cannot drift per repo.
- `docs/adrs/README.md` is each repo's own index, updated in the same commit as an ADR.

**A workflow repo's ADRs are per-repo ADRs.** A decision that constrains more than one repo
belongs in the `architecture` repo's system-level set, by the litmus test in that repo's
`AGENTS.md` §1.2. The core is the one repo here where that boundary is subtle: a core
decision does propagate to every derivation, which is why core ADRs list them under Scope —
but the derivations are not part of the system `architecture` catalogues, so these stay
per-repo.

## Consequences

### Positive

- One vocabulary for decision records across every repo in the organisation.
- The name now implies the shape, so the law does not have to fight the word.
- A managed template means a derivation's ADRs are structured on day one rather than after
  someone invents headings.
- `docs/adrs/` is greppable in the way the rest of the estate already is.

### Negative

- 26 files renamed across three repos; every prior reference to a path under `journal/` in
  a commit message or a task list now points at a path that no longer exists. `git log
  --follow` resolves it; a bare path grep does not.
- Numbering restarts per repo, so "ADR-0007" is ambiguous without naming the repo. That is
  already true estate-wide and the house convention already handles it by citing
  `<repo> ADR-NNNN`.
- The retrofitted header blocks carry `Authors: henning` / `Deciders: henning` and a generic
  Scope, because the real values were never recorded. Honest but thin.

### Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Two ADRs claim one number on parallel branches | Medium | Renumbering, which the immutability rule forbids | Allocate the number immediately before commit, never on a long-lived branch — stated in the template |
| `docs/adrs/` shape stays unenforced, as `journal/` was | High | The convention decays exactly as the last one did | Open follow-up: no existing checker owns this shape, and inventing an owner would break the categorical rule. Recorded, not guessed |
| A derivation inherits the core's ADRs on `derive` | Certain if unhandled | A new repo starts with 13 decisions it never made | `derive` clears `docs/adrs/NNNN-*.md` and keeps only `0000-adr-template.md` |

## Alternatives Considered

1. **Keep `journal/`, document that it means ADRs** — Rejected. That is the restatement
   failure mode the core already names: the reader who finds the copy first reads the
   version nothing enforces. A name that needs a gloss is the wrong name.
2. **`adr/` or `decisions/` at the repo root** — Rejected. A flat root is tidier, but every
   existing repo uses `docs/adrs/` and `architecture/AGENTS.md` §1.2 names that path. Being
   consistent with twenty repos beats being tidy in four.
3. **Date-prefixed filenames with a Status field added** — Rejected. Chronology reads well
   at a glance, but there is no stable short ID to cite, so "supersedes" has to name a
   filename, and the house convention is sequential.
4. **Rename only, leave the free-form headings** — Rejected. The 26 files would stay
   structurally inconsistent, and the reason to adopt a convention is that the structure is
   the part that makes them comparable.
5. **Promote these to system-level ADRs in `architecture`** — Deferred. The workflow repos
   are not inside the system boundary that repo catalogues. Revisit if a workflow-repo
   decision starts constraining product repos.

## Implementation notes

Order matters, because the law names the shape the skills act on:

1. Core: migrate `journal/` → `docs/adrs/`, renumber, add `0000-adr-template.md` and the
   index, rewrite `AGENTS.CORE.md`, `GLOSSARY.md`, `README.CORE.md`.
2. Core: the managed skills that reference the shape — `workflow-orchestrate`'s reaping
   table and carried-work template, `workflow-init`, `workflow-bind`,
   `workflow-template-sync`'s `SKILL.md` and `derive` logic.
3. Core: `template-manifest.yaml` gains `docs/adrs/0000-adr-template.md`; bump `VERSION`.
4. Each derivation: `update`, then migrate its own records and write its own index.

## Verification

- `check.sh` green in the core and in each derivation after migration, with only the
  findings that pre-existed this change.
- `grep -rn journal` across managed files returns nothing but this ADR and ADR-0011.

## References

- Related ADRs in this repo: ADR-0011 (introduced the split, and the name now retired)
- House discipline: `architecture` `AGENTS.md` §3 — format, numbering, status transitions,
  promotion, ADR-only delivery
- House template this one is derived from: `architecture` `adrs/0000-adr-template.md`
