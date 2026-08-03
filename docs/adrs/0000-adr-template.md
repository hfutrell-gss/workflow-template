# ADR-NNNN: <Short Title>

**Status:** Proposed
**Date:** YYYY-MM-DD
**Authors:** <names>
**Deciders:** <names or groups>

**Scope (repos affected):**

- `<this repo>` — <how it is affected>
- `<repo>` — <how it is affected>

---

## Context

What is the situation that forced this decision? What problem does it solve? What constraints apply?

Cite evidence: paths, commits, existing ADRs (by repo + number), observed behaviour, a constraint that fired.

## Decision

The decision in clear, declarative terms. "We will do X." Not "we are considering X."

Be specific enough that a reader can tell whether a future change is consistent with this decision.

## Consequences

### Positive

- What becomes easier or better.

### Negative

- What becomes harder, more expensive, or more constrained.

### Risks and mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
|  |  |  |  |

## Alternatives Considered

For each alternative: what it was, why it was not chosen.

1. **<Name>** — Rejected/Deferred. Reason.
2. **<Name>** — Rejected/Deferred. Reason.

## Implementation notes (optional)

High-level sequencing, migration notes. Not a full project plan; pointers to where that plan lives.

## Verification (optional)

What was run, and what it returned. A claim nobody checked is a claim, not a result.

## References

- Related ADRs in this repo: ADR-NNNN
- Related per-repo ADRs elsewhere: `<repo>` ADR-NNNN
- Related system-level ADRs: `architecture` ADR-NNNN
- External: specs, RFCs, vendor docs

---

<!--
This file is MANAGED by the core (template-manifest.yaml). Do not hand-edit it in a
derivation -- the next `update` overwrites it. Change it upstream via
/upstream-workflow-management.

House conventions this template follows, so an ADR reads the same in a workflow repo as
in any substrate repo:

  Location   docs/adrs/ -- per-repo decisions. A decision that constrains more than one
             repo belongs in the `architecture` repo's system-level ADRs instead.
  Numbering  Zero-padded four digits: 0000, 0001, ... Never skip a number. Numbers and
             filenames are FOREVER once committed; abandoned drafts land as
             Status: Rejected rather than being deleted.
  Allocation Take the next number immediately before commit (ls docs/adrs/0*.md | sort |
             tail -1). Do not reserve numbers on a long-lived branch -- that is how two
             ADRs claim one number.
  Status     Proposed | Accepted | Superseded by NNNN | Rejected | Deferred.
             Proposed -> Accepted is an edit in place, never a new ADR.
             Superseding: mark the original "Superseded by NNNN" and KEEP the file.
  Index      Add a row to docs/adrs/README.md in the same commit as the ADR.
-->
