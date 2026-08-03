# The task list — the durable artifact

Your context is not the state of the run. This file is.

## Two strata — the whole design

"Workflow" names **reusable procedural knowledge**: the repeatable way of doing a kind of
work (`refactor`, `create-web-app`, `onboard-app`) — not a log of one time it was done. That
procedure and any one run of it live at different levels, and the split is load-bearing:

```
workflows/<workflow>/SKILL.md                     # TIMELESS — the TTPs. Never pruned.
workflows/<workflow>/references/                  # depth for those TTPs
workflows/<workflow>/<app>/profile.md             # DURABLE — that application's particulars
workflows/<workflow>/<app>/tasks.md               # CARRIED — epics, deferred work. Crosses sessions.
workflows/<workflow>/<app>/<session>/tasks.md     # SESSION — one run. Deleted after reaping.
workflows/<workflow>/<app>/<session>/roster.md    # the tiers this session resolved
workflows/<workflow>/<app>/<session>/notes/       # worker artifacts, evidence too big for one line
```

Four levels, four lifetimes (`AGENTS.CORE.md` "The shapes"):

- **`<workflow>`** names the nature of work — `web-app-development`, `refactor`,
  `upstream-workflow-management`. Timeless. It does not know when it runs or what it ran
  against. Its `SKILL.md` is the retrieval surface; see "Retrieving the workflow" below.
- **`<app>`** is what the workflow acts on. Durable. `profile.md` holds its operational
  particulars — the facts the workflow needs to operate it, distinct from its own repo docs.
- **`<app>/tasks.md`** is **carried work**: epics, deferred tasks, threads that must survive
  any one session. `orchestrate.sh` never reads it as a session list. It is the reason the
  application level exists.
- **`<session>`** is one discrete instantiation, named `<date>-<slug>`. **Everything under it
  is disposable after reaping, by definition.**

  The slug carries the name and the date carries the order, and both are needed. A bare date
  says nothing about what the session was, and two sessions in one day collide. A bare slug
  loses the ordering that makes a directory listing readable and makes a second session on
  the same subject impossible to name. `init` takes the slug and adds the date, and refuses a
  bare date outright. Anything there that is not disposable has one of
  three other homes, and reaping is the gate that moves it.

- **Every level at the workflow repo root** — never inside bound substrate. Session state
  belongs to the workflow that owns the session; the substrate only receives the work.
- **Committed, not gitignored**, at every level. That is the entire point: a continuation on
  another machine, or after a compaction, resumes from the commit. (Contrast `workspace/`,
  which is per-machine and never committed.) A reaped session directory is **deleted
  outright** — `git log` is the archive; no graveyard directory is kept.
- **One session directory per (workflow, app, session).** `orchestrate.sh init <workflow> <app> <slug>` refuses if
  `tasks.md` already exists there. It never overwrites `<app>/tasks.md` or `<app>/profile.md`:
  clobbering carried work is how cross-session threads are lost.

The harness `TaskCreate`/`TaskUpdate` store may mirror `tasks.md` for the live UI. It is
**never the source of truth**: it does not survive a cold tick, and a session whose state
lives only there cannot be resumed or reviewed.

## Retrieving the workflow

A directory alone cannot be found by a model at the moment of need. `workflows/<workflow>/`
holds the TTPs, and `.claude/skills/<workflow>/SKILL.md` is the thin discovery stub that makes
them reachable: frontmatter `description` written so a model reaching for this kind of work
matches it, and a body that points at `workflows/<workflow>/SKILL.md`. `/workflow-manage
new-workflow <name>` scaffolds both. A workflow must not take the core's `workflow-*` prefix, nor any
machinery name — both namespaces reach the Skill tool.

## Legacy layout

Sessions created before this layout live at `.workflow/<slug>/tasklist.md` (one flat, dated
directory — no workflow/app split, no reaping gate). `orchestrate.sh status`, `ready`, and
`list` **keep resolving that path for one version**, so an in-flight legacy session is not
stranded. A resolved legacy session prints a `NOTE:` naming the path; that is the migration
reminder, not noise to silence. **This fallback is scheduled for removal in a future
version.** `init` never writes to it.

`workflows/<workflow>/<app>/tasks.md` is carried work, never a session list. A session
found stored directly there moves down one level into a `<session>/` directory before
running `status`.

## Grammar

One line per task, exact separators (` · `), so it parses mechanically and merges cleanly:

```
- [<marker>] <ID> · <tier> · deps:<deps> · <title>
      <key>: <value>
```

| Part | Rule |
|------|------|
| `<marker>` | one of ` ` `~` `x` `!` `^` `-` (below) |
| `<ID>` | `T` + digits, unique in the file, never reused or renumbered |
| `<tier>` | `flagship` · `workhorse` · `fleet` — a tier, never a model name |
| `<deps>` | `-`, or comma-separated IDs with no spaces: `deps:T001,T004`. The hyphen is ASCII (`-`); an em dash reads identically in rendered markdown and is silently wrong |
| `<title>` | imperative, one line, what done looks like |
| `<key>: <value>` | continuation fields, indented at least two spaces |

**A task ID is session-local and never appears in substrate.** A comment, doc, commit
message, or test name in a bound repo that cites `T039` — or cites a path under
`workflows/` or `.workflow/` — is a dead reference by construction: the session directory
is deleted at close, so the citation points at nothing the moment the run ends. Substrate
cites its own repo's paths, its own issues, and the facts themselves. `orchestrate.sh
check` reports escaped identifiers as `SUBSTRATE-001`.

## Markers

| Marker | State | Required field |
|--------|-------|----------------|
| `[ ]` | pending | — |
| `[~]` | claimed, worker in flight | `agent:` — which agent holds it |
| `[x]` | done and verified | `evidence:` — what proves it |
| `[!]` | blocked | `blocked:` — on what, and what was done about it |
| `[^]` | carried | `carried:` — its entry in `<app>/tasks.md`, and why it could not finish here |
| `[-]` | dropped | `why:` **and** `signoff:` — who authorized it, when |

`[-]` and `[^]` take one more field **at reaping**: `landed:` — where the decision's
rationale went. See the reaping gate below.

Every task carries `accept:` from the moment it is created — the acceptance test it will be
judged against. A task without one is a wish, and `status` reports it as a violation.

```markdown
## Tasks
- [x] T001 · fleet · deps:- · Inventory config call sites
      accept: every call site enumerated with file:line
      evidence: 14 sites, notes/T001-callsites.md
- [~] T002 · fleet · deps:T001 · Extract the config loader
      accept: single loader; existing suite green
      agent: fleet/haiku (dispatched 14:20)
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

**DoD = exhaustion + reaping**, and that is exactly:

- no `[ ]`, no `[~]`, no `[!]` remains,
- `orchestrate.sh status` reports **zero violations**, **and**
- `## Reaping` reads `reaping: done <where it went>` — see "Reaping" below.

`orchestrate.sh status` decides this, not you. It exits `0` when all three hold, `2` when they
do not (an ordinary state, not a failure), `1` on a real error.

### Anti-cheat

The rules exist because every one of them is a way a run can look finished without being
finished. All are mechanically checked:

- **`[x]` requires `evidence:`** — a command and its result, a test name, a diff, a path under
  `notes/`. A worker's assertion that it succeeded is not evidence; what you checked is.
- **`[^]` requires `carried:`** — promoting is not dropping. The work leaves this session and
  arrives in `<app>/tasks.md` with the session that raised it and why it stopped. A `[^]` with
  no destination is work thrown away with extra steps. Use it when a task is real, still
  wanted, and cannot finish here — a blocker owned by someone else, an epic larger than this
  session. `[^]` is not open, so a session with carried work still reaches DoD: **unfinished
  work never blocks a session forever.**
- **`[-]` requires `why:` and `signoff:`** — you cannot drop your way to exhaustion. Dropping a
  task is the user's call, and the signoff records that they made it.
- **`[-]` and `[^]` require `landed:` at reaping** — a decision to refuse work is a fact about
  the application, and it is the fact most easily lost. Name the destination: the stewarded
  repo's own docs (`workspace/<app>/docs/...`) when the workflow stewards it,
  `<app>/profile.md` otherwise, or `disposable — <reason>` when the rationale genuinely adds
  nothing. Checked only once `reaping:` says done, so it is never noise on work in flight.
  Without it, an application's status section reading *not built* cannot be told apart from a
  gap awaiting closure, and the next session re-opens a settled question.

  ```markdown
  - [-] T045 · fleet · deps:- · Split the app server out of the dev host
        accept: `createAppServer` holds what an application needs.
        why:    de-scoped from this run.
        signoff: user, 2026-07-31 — "ejecting isn't a prime concern, it was just a
                 modeling constraint"
        landed: workspace/tempest/docs/ejectability.md — recorded as a decision taken,
                so the status section is not read as a gap awaiting closure
  ```
- **`[!]` blocks DoD.** A blocked task must be unblocked or escalated. Converting it to `[-]` to
  clear the board without a signoff is the exact failure this design prevents.
- **Discovered work becomes a new task** — with its own ID, tier, and `accept:`. Never widen an
  existing task's scope to absorb it; that hides the growth and skips the reorganize step.
- **Never renumber or delete task lines.** History of the run is part of the artifact. A wrong
  task is dropped with a signoff, not erased.
- **A cycle in `deps:` is a violation**, not a puzzle — it deadlocks the loop. `status` detects
  cycles; break them in the reorganize step.
- **`reaping:` bare `done` (no destination) is a violation.** Exhausting the task list is not
  reaping; you must say where the durable output went. `pending` is always valid — it is the
  honest default — but any other value that isn't `done <where>` is flagged immediately, not
  only at closing time.

## Reaping

Exhaustion alone is not DoD: a run can finish every task and still leave its durable output
stranded in a directory that a later prune deletes. **A run is not done until its durable
output has left the run directory.**

Before closing a run:

1. Sweep `notes/` and the `## Log` decisions into (a) `workflows/<workflow>/` if a
   way-of-working stabilized enough to write down, (b) `<app>`'s own docs or `<app>/profile.md`
   if the knowledge belongs to the target repo, (c) `<app>/tasks.md` `## Open` if it is work
   still wanted, (d) a new ADR in `docs/adrs/` **only** if it is a decision about this
   workflow repo itself that would not survive in a diff.
2. Record where, in `## Reaping`: `reaping: done <destination(s), briefly>`.
3. Then run `orchestrate.sh close`. It re-checks the DoD, writes the ledger line, and deletes
   the directory in one step.

**Nothing here is a narrative of the run.** That the session ran, against what, and with what
result is the ledger's job — `close` derives that line from the task list itself, so it cannot
flatter the run. A hand-written account of the same session as an ADR is a second record
that will drift from `git log` and from the ledger both.

Mechanism: the `## Reaping` section's `reaping:` field. It defaults to `pending` when the
section or the field is absent, so a run that omits it is reported as un-reaped rather
than passed. It lives in the one file `status` already parses — no second place to check,
and nothing that can disagree with the task list about whether the run is done.

A *missing section* is also a violation in its own right, not only a `pending` default.
Defaulting alone is honest but mute: the run can never reach done and the file does not
say why. The violation names the section and the line to write. It is what catches a
session written against an older grammar — a heading this parser no longer recognizes
reads as an **absent** section, not as a different one.

## Resuming cold

A fresh tick has no memory of the run. Reconstruct in this order:

1. `orchestrate.sh list` — find runs that are not done (unexhausted, violating, or reaping
   still pending). Includes legacy `.workflow/<slug>/` runs, each flagged with a NOTE.
2. Read `tasks.md`'s header: the **verbatim directive** and the DoD. Do not re-derive the
   goal from the task titles.
3. Read `roster.md` — reuse the tiers this run already resolved. Re-resolve only if a lane
   is now unavailable, and record the substitution.
4. **Validate `[~]` claims.** After a cold start no worker is still in flight: any `[~]` whose
   evidence is not on disk is a stale claim → reset it to `[ ]` and note the retry. Leaving
   stale claims is how a run stalls while appearing busy.
5. `orchestrate.sh ready` → dispatch. Resume the loop at step 5; do not re-decompose a list
   that already exists. If tasks are exhausted but `status` still reports `reaping pending`,
   resume at "Reaping" above instead — the loop is not the gap, the sweep is.

## Git discipline

- `/usr/bin/git` explicitly, always (`AGENTS.CORE.md`).
- Commit the run state when a batch is verified — an uncommitted `tasks.md` is not a
  continuation. Small, frequent commits beat one commit at the end of the run.
- Run-state commits state the transition, not the file: `orchestrate(<workflow>/<app>/<session>):
  T002,T004 done; T007 blocked on staging creds`.
- The instance directory is committed to the workflow repo. Work products go to the substrate
  repo, on its own branch, under its own law — two separate commit streams; never mix them.
- **Do not write an ADR for the run.** `docs/adrs/` holds decisions about this workflow
  repo, not accounts of sessions. The run's permanent record is the ledger line `close`
  writes; its detail is `git log`. Write an ADR only if the run changed the *system* — a
  shape renamed, a constraint added — and the reason would not survive in a diff.
- The closing commit carries the ledger line and the session deletion together, so a reader
  hitting the deletion in `git log` finds the line that replaced it in the same commit.
