# Consultation and escalation

Three tiers of judgment, each more expensive than the last: **decide it yourself → consult the
flagship consultant → ask the user.** Climb only when the tier below genuinely cannot settle it.

## Tier 1 — you (the orchestrator)

Decide anything derivable from the directive, the substrate, the bound repos' law, and
conventional defaults. A choice with an obvious conventional answer is not a fork: pick it,
record it in the task line or the session's `## Log`, move on. Escalating a decision you are
equipped to make is not caution, it is latency.

## Tier 2 — the consultant (`flagship` tier)

Dispatched like a worker, briefed like an advisor: it returns judgment, never work products.
Four legitimate uses:

| Use | When | Ask for |
|-----|------|---------|
| **Directive intake** | the directive is vague enough that decomposing it is guessing | the goal restated as testable acceptance criteria, plus what it deliberately excludes |
| **Decomposition review** | the task graph is large, or you suspect a missing or duplicated slice | what is missing, what is redundant, what is mis-tiered |
| **Reorganization sign-off** | the ordering is non-obvious, or two orderings imply materially different work | the ordering it recommends and the deciding factor |
| **Fork adjudication** | a genuine design trade-off inside a task | a recommendation with reasoning, not a verdict |

### How to brief it

- **It starts cold.** Give the full relevant context: the verbatim directive, the current task
  list (or the slice at issue), the constraints, what you already ruled out and why.
- **One specific question.** "Given [context], A or B — state a recommendation and the deciding
  factor" beats "thoughts?".
- **Ask for reasoning, not a verdict.** You are the one who decides; you need the argument in
  order to decide, and to defend the choice later.
- **High-stakes forks: two or three consultants with different framings**, then compare. Where
  they converge, proceed. Where they split, that split is the thing to escalate to the user —
  it is real evidence the decision is a preference, not a fact.
- **Adversarial framing on plans you are close to**: "find what is wrong with this
  decomposition" surfaces more than "is this decomposition good".

### Rules

- The consultant's answer is **advice**. You decide, and you record why — an unrecorded
  decision gets re-litigated on the next cold tick. While the run is live, that record is the
  task line or the session's `## Log`. At harvest it goes where the outcome belongs: the
  stewarded repo's own docs, or `<app>/profile.md`, named in the task's `landed:`.
- **Never route work to the consultant.** A `flagship` model executing a `fleet` task is the
  most expensive possible way to do it, and it starves the tier of the judgment you actually
  need from it.
- **If the flagship tier is unavailable** (lane down, no roster entry): say so, then assess it
  yourself — deliberately adversarially, arguing the opposite case before choosing. Record that
  consultation was skipped and why. Never treat unavailability as permission to skip the
  judgment step itself.
- Consultation is not a lever for indecision. If you already know the answer, the consultant is
  a rubber stamp you paid `flagship` rates for.

## Tier 3 — the user

`AskUserQuestion`, and only when:

- The decision is **theirs by nature** — scope, budget, risk tolerance, authorization, priority
  between two things they value, or a fact only they hold.
- **A `[-]` drop needs a signoff.** Dropping a task always comes here; no exceptions
  (`tasklist.md`, anti-cheat).
- **A `[!]` block cannot be cleared** by any means available to you — missing credentials,
  access, or an external decision.
- **You and the consultants remain split** on something that materially changes the outcome.
- The next action is **hard to reverse or outward-facing** and you lack durable authorization
  for it.

When you ask: recommendation first and labelled as such, options mutually exclusive, enough
context that the choice is real. Keep it rare — each interrupt spends attention that the whole
point of orchestration is to conserve. Between asks, keep the rest of the list moving: a
question about one task never idles the fleet on the others.
