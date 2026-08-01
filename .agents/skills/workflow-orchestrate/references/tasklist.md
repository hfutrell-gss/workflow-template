# The task list — the durable artifact

Your context is not the state of the run. This file is.

## Two strata — the whole design

"Workflow" names **reusable procedural knowledge**: the repeatable way of doing a kind of
work (`refactor`, `create-web-app`, `onboard-app`) — not a log of one time it was done. That
procedure and any one run of it live at different levels, and the split is load-bearing:

```
workflows/<workflow>/                    # DURABLE — the procedure. Never pruned.
workflows/<workflow>/<target>/tasks.md   # INSTANCE — one run. Disposable after harvest.
workflows/<workflow>/<target>/roster.md  # the tiers this run resolved (see model-classes.md)
workflows/<workflow>/<target>/notes/     # worker artifacts, evidence too big for one line
```

- **`<workflow>`** names the way-of-working. Its directory level holds whatever documents
  that procedure — durable, never keyed to a single run, never pruned by a harvest.
- **`<target>`** is the repo the work lands in — not a date. One `<workflow>`×`<target>` pair
  is a long-lived run: "the more-or-less global task set for doing `<workflow>`-shaped work
  on `<target>`." It is meant to be reopened across sessions, not closed and re-created daily.
- **The stratification rule: everything under `<target>/` is disposable after harvest, by
  definition.** If something there is *not* disposable — a lesson that generalizes beyond this
  one run, a decision future runs of this workflow need — it does not belong there. It belongs
  one level up in `workflows/<workflow>/`, in `<target>`'s own docs (if the knowledge is the
  target's), or in the journal (if it is narrative). This is what stops "workflow" from
  collapsing into "run log" again: pruning `workflows/<workflow>/<target>/` can never damage
  the procedure, because nothing durable was ever allowed to live there. See "Harvest" below —
  this is the gate that enforces it.
- **Both levels always at the workflow repo root** — never inside bound substrate. Run state
  belongs to the workflow that owns the run; the substrate only receives the work.
- **Committed, not gitignored**, at both levels. That is the entire point: a continuation on
  another machine, or after a compaction, resumes from the commit. (Contrast `workspace/`,
  which is per-machine and never committed.) A closed, harvested instance directory may be
  **deleted outright** — it is committed, so `git log` is the archive; no graveyard directory
  is kept.
- **One instance directory per (workflow, target).** `orchestrate.sh init <workflow> <target>`
  refuses if `tasks.md` already exists there — resume the existing run instead of starting a
  parallel one for the same pair.

The harness `TaskCreate`/`TaskUpdate` store may mirror `tasks.md` for the live UI. It is
**never the source of truth**: it does not survive a cold tick, and a run whose state lives
only there cannot be resumed or reviewed.

## Retrieving the procedure stratum

A directory alone cannot be found by a model at the moment of need — `workflows/<workflow>/`
holds the procedure, but nothing loads it unless something points there. The intended pattern,
once a `workflows/<workflow>/` has content worth retrieving: a thin, derivation-local skill
stub (outside the `workflow-*`/`craft-*` reserved prefixes) whose **frontmatter `description`
is the retrieval surface** — written so a model reaching for this kind of work matches it — and
whose body does little more than point at `workflows/<workflow>/` for the actual doctrine. This
skill does not build that stub for any specific workflow; it only names the pattern so the
stratum stays reachable once a derivation's procedure is worth naming.

## Legacy layout

Runs created before this stratification landed live at `.workflow/<slug>/tasklist.md` (one
flat, dated directory — no workflow/target split, no harvest gate). `orchestrate.sh status`,
`ready`, and `list` **keep resolving that path for one version**, so an in-flight legacy run
is not stranded — it can finish, or be migrated, on its own schedule. A resolved legacy run
prints a `NOTE:` naming the path; that is not noise to silence, it is the migration reminder.
**This fallback is scheduled for removal in a future version.** `init` never writes to it —
every new run goes to `workflows/<workflow>/<target>/` only.

## Grammar

One line per task, exact separators (` · `), so it parses mechanically and merges cleanly:

```
- [<marker>] <ID> · <tier> · deps:<deps> · <title>
      <key>: <value>
```

| Part | Rule |
|------|------|
| `<marker>` | one of ` ` `~` `x` `!` `-` (below) |
| `<ID>` | `T` + digits, unique in the file, never reused or renumbered |
| `<tier>` | `flagship` · `workhorse` · `fleet` — a tier, never a model name |
| `<deps>` | `-`, or comma-separated IDs with no spaces: `deps:T001,T004` |
| `<title>` | imperative, one line, what done looks like |
| `<key>: <value>` | continuation fields, indented at least two spaces |

## Markers

| Marker | State | Required field |
|--------|-------|----------------|
| `[ ]` | pending | — |
| `[~]` | claimed, worker in flight | `agent:` — which agent holds it |
| `[x]` | done and verified | `evidence:` — what proves it |
| `[!]` | blocked | `blocked:` — on what, and what was done about it |
| `[-]` | dropped | `why:` **and** `signoff:` — who authorized it, when |

Every task carries `accept:` from the moment it is created — the acceptance test it will be
judged against. A task without one is a wish, and `status` reports it as a violation.

```markdown
## Tasks
- [x] T001 · fleet · deps:- · Inventory config call sites
      accept: every call site enumerated with file:line
      evidence: 14 sites, notes/T001-callsites.md
- [~] T002 · fleet · deps:T001 · Extract the config loader
      accept: single loader; existing suite green
      agent: ocx-gpt-5-6-luna (dispatched 14:20)
- [ ] T003 · workhorse · deps:T002 · Reconcile conflicting loader semantics
      accept: both call sites resolve identical config; parity test passes
- [!] T004 · fleet · deps:T003 · Migrate prod callers
      accept: no caller reads the old path
      blocked: needs staging credentials — escalated to user 2026-07-30
- [-] T005 · fleet · deps:- · Rewrite the legacy shim
      accept: shim deleted, callers migrated
      why: out of scope for this directive; separate session warranted
      signoff: user, 2026-07-30
```

## Exhaustion

**DoD = exhaustion + harvest**, and that is exactly:

- no `[ ]`, no `[~]`, no `[!]` remains,
- `orchestrate.sh status` reports **zero violations**, **and**
- `## Harvest` reads `harvest: done <where it went>` — see "Harvest" below.

`orchestrate.sh status` decides this, not you. It exits `0` when all three hold, `2` when they
do not (an ordinary state, not a failure), `1` on a real error.

### Anti-cheat

The rules exist because every one of them is a way a run can look finished without being
finished. All are mechanically checked:

- **`[x]` requires `evidence:`** — a command and its result, a test name, a diff, a path under
  `notes/`. A worker's assertion that it succeeded is not evidence; what you checked is.
- **`[-]` requires `why:` and `signoff:`** — you cannot drop your way to exhaustion. Dropping a
  task is the user's call, and the signoff records that they made it.
- **`[!]` blocks DoD.** A blocked task must be unblocked or escalated. Converting it to `[-]` to
  clear the board without a signoff is the exact failure this design prevents.
- **Discovered work becomes a new task** — with its own ID, tier, and `accept:`. Never widen an
  existing task's scope to absorb it; that hides the growth and skips the reorganize step.
- **Never renumber or delete task lines.** History of the run is part of the artifact. A wrong
  task is dropped with a signoff, not erased.
- **A cycle in `deps:` is a violation**, not a puzzle — it deadlocks the loop. `status` detects
  cycles; break them in the reorganize step.
- **`harvest:` bare `done` (no destination) is a violation.** Exhausting the task list is not
  harvest; you must say where the durable output went. `pending` is always valid — it is the
  honest default — but any other value that isn't `done <where>` is flagged immediately, not
  only at closing time.

## Harvest

Task-list exhaustion alone used to be DoD. It is not enough: a run can finish every task and
still leave its durable output stranded in a directory that a later prune deletes. **A run is
not done until its durable output has left the run directory.**

Before closing a run:

1. Sweep `notes/` and the `## Log` decisions into (a) `workflows/<workflow>/` if a
   way-of-working stabilized enough to write down, (b) `<target>`'s own docs if the knowledge
   belongs to the target repo, (c) the journal if it is narrative rather than procedure or
   target-specific fact.
2. Record where, in `## Harvest`: `harvest: done <destination(s), briefly>`.
3. Only then may the instance directory be deleted — it is committed, so `git log` is the
   archive. No graveyard directory is kept, and none is needed.

Mechanism: the `## Harvest` section's `harvest:` field, defaulting to `pending` when the
section or field is absent (so a run written before this gate existed is reported honestly
as un-harvested, never silently grandfathered in). This was chosen over a separate
`HARVESTED` marker file because it lives in the one file `status` already parses — no second
place to check, no risk of the marker and the task list disagreeing about whether the run is
really done.

## Resuming cold

A fresh tick has no memory of the run. Reconstruct in this order:

1. `orchestrate.sh list` — find runs that are not done (unexhausted, violating, or harvest
   still pending). Includes legacy `.workflow/<slug>/` runs, each flagged with a NOTE.
2. Read `tasks.md`'s header: the **verbatim directive** and the DoD. Do not re-derive the
   goal from the task titles.
3. Read `roster.md` — reuse the tiers this run already resolved. Re-resolve only if a lane
   is now unavailable, and record the substitution.
4. **Validate `[~]` claims.** After a cold start no worker is still in flight: any `[~]` whose
   evidence is not on disk is a stale claim → reset it to `[ ]` and note the retry. Leaving
   stale claims is how a run stalls while appearing busy.
5. `orchestrate.sh ready` → dispatch. Resume the loop at step 5; do not re-decompose a list
   that already exists. If tasks are exhausted but `status` still reports `harvest pending`,
   resume at "Harvest" above instead — the loop is not the gap, the sweep is.

## Git discipline

- `/usr/bin/git` explicitly, always (`AGENTS.CORE.md`).
- Commit the run state when a batch is verified — an uncommitted `tasks.md` is not a
  continuation. Small, frequent commits beat one commit at the end of the run.
- Run-state commits state the transition, not the file: `orchestrate(<workflow>/<target>):
  T002,T004 done; T007 blocked on staging creds`.
- The instance directory is committed to the workflow repo. Work products go to the substrate
  repo, on its own branch, under its own law — two separate commit streams; never mix them.
- Open the run's journal entry (`journal/YYYY-MM-DD-<slug>.md`) pointing at
  `workflows/<workflow>/<target>/`. The journal is the human narrative of the run; the task
  list is its machine state. Neither replaces the other.
