# The task list — the durable artifact

Your context is not the state of the run. This file is.

## Where it lives

```
.workflow/<session-slug>/
├── tasklist.md     # the run: directive, DoD, tasks
├── roster.md       # the tiers this session resolved (see model-classes.md)
└── notes/          # worker artifacts, evidence too big for one line
```

- **Always at the workflow repo root** — never inside bound substrate. Session state belongs to
  the workflow that owns the run; the substrate only receives the work.
- **`<session-slug>` is `YYYY-MM-DD-<name>`**, matching journal naming. `orchestrate.sh init
  <name>` prepends today's date if you omit it.
- **Committed, not gitignored.** That is the entire point: a continuation on another machine, or
  after a compaction, resumes from the commit. (Contrast `workspace/`, which is per-machine and
  never committed.)
- **One session per directive.** A new directive gets a new session, even on the same day. Do
  not append unrelated work to a live list — that makes exhaustion unreachable by construction.

The harness `TaskCreate`/`TaskUpdate` store may mirror this file for the live UI. It is **never
the source of truth**: it does not survive a cold tick, and a run whose state lives only there
cannot be resumed or reviewed.

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

**DoD = exhaustion**, and exhaustion is exactly:

- no `[ ]`, no `[~]`, no `[!]` remains, **and**
- `orchestrate.sh status` reports **zero violations**.

`orchestrate.sh status` decides this, not you. It exits `0` on exhausted-and-clean, `2` on not
exhausted (an ordinary state, not a failure), `1` on a real error.

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

## Resuming cold

A fresh tick has no memory of the run. Reconstruct in this order:

1. `orchestrate.sh list` — find sessions that are not exhausted.
2. Read `tasklist.md`'s header: the **verbatim directive** and the DoD. Do not re-derive the
   goal from the task titles.
3. Read `roster.md` — reuse the tiers this session already resolved. Re-resolve only if a lane
   is now unavailable, and record the substitution.
4. **Validate `[~]` claims.** After a cold start no worker is still in flight: any `[~]` whose
   evidence is not on disk is a stale claim → reset it to `[ ]` and note the retry. Leaving
   stale claims is how a run stalls while appearing busy.
5. `orchestrate.sh ready` → dispatch. Resume the loop at step 5; do not re-decompose a list
   that already exists.

## Git discipline

- `/usr/bin/git` explicitly, always (`AGENTS.CORE.md`).
- Commit the task list when a batch is verified — an uncommitted task list is not a
  continuation. Small, frequent commits beat one commit at the end of the run.
- Task-list commits state the transition, not the file: `orchestrate(<slug>): T002,T004 done;
  T007 blocked on staging creds`.
- The session dir is committed to the workflow repo. Work products go to the substrate repo, on
  its own branch, under its own law — two separate commit streams; never mix them.
- Open the run's journal entry (`journal/YYYY-MM-DD-<slug>.md`) pointing at the session dir.
  The journal is the human narrative of the run; the task list is its machine state. Neither
  replaces the other.
