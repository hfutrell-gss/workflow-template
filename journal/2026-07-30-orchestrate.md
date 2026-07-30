# workflow-orchestrate — task-based orchestration bound to tiers, not model names

Added `/workflow-orchestrate` to the managed set (v17). Prior art was a personal skill,
`~/.claude/skills/orchestrate/` — the same coordinate → delegate → synthesize shape, with two
properties that made it unshippable as template law: it names models (`Opus 4.8`,
`cursor-grok-4.5-high`) and it keeps the task list in the harness `TaskCreate` store. The
first rots on every vendor release; the second evaporates on a cold tick, which means the
run has no resumable state and its DoD is whatever the orchestrator says it is. The personal
skill stays where it is, untouched.

## Three concepts, because two collapse wrong

The request was "classes of models, not models." The naive encoding — one axis, `fable ·
opus · sonnet` renamed to something vendor-neutral — breaks on the first cross-vendor
roster, because "which model" is really three independent questions:

- **lane** — provider family *and dispatch mechanism*. These are inseparable in practice:
  the native lane goes through the Agent tool's `model:` argument, routed lanes through
  `agentType:` — and a routed agent **pins its model in its own definition, ignoring
  `model:` entirely**. A design that models only "which model" cannot express that, and the
  failure is silent: work lands on a model nobody chose and the transcript looks fine.
- **tier** — capability class within a lane: `flagship · workhorse · fleet`.
- **role** — the job: `consultant · orchestrator · worker`.

Role→tier is a default (`consultant→flagship`, `orchestrator→workhorse`, `worker→fleet`),
not an identity. Collapsing them would leave no vocabulary for a design-heavy workflow that
wants its orchestrator on `flagship`, or a mechanical one that wants it on `fleet`. That is
one extra concept buying a whole axis of movement, so it stays.

Tiers are ordered by capability and explicitly **not interchangeable downward**: a task
needing `flagship` judgment escalates or blocks. It never quietly becomes a `fleet` task.

## Genericity is a procedure, not a longer list

The roster will always be stale — that is a property of the domain, not a defect to fix by
enumerating harder. So the seed table is labeled data, dated, and subordinate to a
resolution order (session roster → derivation overlay → seed, filtered by runtime
discovery) and a classification rule for models the file has never heard of:

- Classify by the **vendor's own published tier statement**. Vendors that ship tiers say
  which is which.
- Never infer from a name, a version number, or ordering. Two models in one release can sit
  in different tiers, and a release can add a tier that did not previously exist.
- Never infer from a benchmark table alone — a model can top one index and trail two tiers
  down on another. GPT-5.6 Sol is the live example: state of the art on BrowseComp and
  OSWorld, ~15 points *behind* on SWE-Bench Pro. Benchmarks break ties within a tier; they
  do not assign one.
- Unresolvable → ask the user once, write it to the overlay, never ask twice.
- An unclassified model is not dispatched. Guessing is how frontier judgment work lands on
  a bulk model unnoticed.

Verified rather than assumed while writing this: GPT-5.6 ships Sol/Terra/Luna as *durable
capability tiers advancing on their own cadence* (GA 2026-07-09) — the same shape this skill
models, which is why the routed lane maps onto it cleanly. `ocx models live` on this machine
confirms all three plus gpt-5.5, gpt-5.4, gpt-5.4-mini, gpt-5.3-codex-spark. The Agent
tool's native enum is `opus | sonnet | haiku | fable`. Both facts are recorded as dated data
in `references/model-classes.md`, not as doctrine.

## Per-tier lane preference

Requested mid-design and it fits the same slot: each tier gets an **ordered** lane list in
`.agents/orchestrate/roster.local.yaml`, so a workflow can run its fleet on a cheap routed
lane while keeping judgment native. Two rules keep it honest — a single-lane tier whose lane
is down is a hard stop for that tier (not a substitution), and any fallback actually taken
is recorded in the session roster *and* stated to the user. Preference is about lanes; it is
never permission to skip a tier.

This is the `craft-*` overlay mechanism applied outside `.agents/craft/`, which is the first
time the template has needed it for a `workflow-*` skill. `AGENTS.CORE.md` now says so
explicitly, so the pattern reads as general rather than as a craft peculiarity.

## Exhaustion has to be mechanical or it is theater

DoD is task-list exhaustion. The whole design question is who decides it, and an
orchestrator asserting its own completion is worth nothing. So the state lives in a
committed file (`.workflow/<session-slug>/tasklist.md`) under a strict grammar, and
`orchestrate.sh status` renders the verdict — exit 0 exhausted-and-clean, 2 not exhausted,
1 error. The script deliberately **cannot** mark a task done: recording completion is a
judgment about evidence, and a script with a `complete` subcommand is an invitation to use it
without any.

Every anti-cheat rule is mechanically checked, because a rule that only exists in prose is
a rule the next cold tick will not honor: `[x]` requires `evidence:`, `[~]` requires
`agent:`, `[!]` requires `blocked:` and blocks DoD, `[-]` requires `why:` **and** a
`signoff:` — you cannot drop your way to exhaustion. Plus structural checks the grammar
makes possible: duplicate IDs, unknown deps, deps on dropped tasks, dependency cycles,
missing `accept:`.

Three of those checks exist because writing the fixture found the holes:

1. **A fresh session reported `EXHAUSTED`** — zero open tasks is vacuously "done". Now an
   empty list is a violation, as is a `## Directive` section that was never filled in. An
   unstarted run must not be indistinguishable from a finished one.
2. **A rejected task line left its continuation fields orphaned**, and they were credited to
   the *previous* task — so a duplicate line silently supplied the `accept:` that the task
   above it was missing. Rejection now clears the attachment target.
3. **A task line filed outside `## Tasks` was silently ignored.** Found by accident: an
   append landed after `## Log` and the parser dropped it, so a blocked task simply did not
   count. Now a violation — silently ignored work is precisely how a list reaches exhaustion
   without the work being done.

All three are the same failure in different clothes: a way for the run to *look* finished.
That is what the mechanical layer exists to catch, so they are checks, not warnings in prose.

## Verification

- `bash -n` clean (shellcheck not installed on this machine — noted, not skipped silently).
- Fixture with 14 task lines exercising every marker and every violation class: 12 tasks
  registered, duplicate and malformed lines rejected, 10 violations reported including both
  halves of a dependency cycle, `ready` correctly listing only deps-satisfied pending tasks
  (and a title containing the ` · ` separator round-tripping intact).
- Verdict transitions: clean all-done list → `EXHAUSTED` rc=0; add one `[!]` → back to `NOT
  EXHAUSTED`; comment-only directive → violation; authorized `[-]` with `signoff:` does not
  block.
- Session resolution: single session implicit, single *open* session among several implicit,
  two open → error naming all candidates, unknown slug → error. `init` refuses to clobber,
  rejects a bad name, honors an explicit date prefix.
- `agents-sync.sh --check`: all conforming. Manifest at 20 → 22 managed paths; `VERSION`
  (17) matches manifest `version` (17).

## Gap found in agents-sync, not fixed here

`agents-sync.sh` iterates `.claude/skills/*/` — the proxy side — so it validates existing
stubs but **cannot see a canonical skill that has no stub at all**. It reported "all
conforming" while `workflow-orchestrate` had no proxy stub and was therefore undiscoverable.
The stub was generated with that script's own `create_stub_from_canonical` logic to
guarantee conformance, but the detection hole is real and belongs to `/workflow-agents-sync`
— a reverse sweep over `.agents/skills/*/` reporting canonical skills with no counterpart.
Left for a separate change rather than folded in silently.
