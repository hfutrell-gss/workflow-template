---
name: workflow-orchestrate
description: >-
  Task-based orchestration bound to model tiers, not model names. Take a directive, decompose
  it into a committed task list at workflows/<workflow>/<app>/<session>/tasks.md, reorganize that into
  a streamlined flow, dispatch each task to the fitting tier (flagship consultant · workhorse
  orchestrator · fleet workers) resolved from a lane roster, and loop until the list is
  exhausted AND its durable output reaped out of the run directory. Use when asked to
  orchestrate or coordinate a multi-task job, when a directive needs decomposing into tasks,
  when resuming a prior run's task list, or when work must survive across sessions and cold
  /loop ticks.
---

# workflow-orchestrate

## Precedence

Defaults, not supremacy:

1. **A bound repo's own law wins inside its boundaries** (`AGENTS.CORE.md`, bind law) — read
   its `AGENTS.md` before dispatching any work into it, and brief every worker to do the same.
2. **This workflow's overlays win over these defaults** —
   `.agents/orchestrate/roster.local.yaml` (tier→lane preference, roster additions) and
   `.agents/orchestrate/orchestrate.local.md` (everything else). Read both on invocation if
   present; where either conflicts with this file, it wins.
3. **Where all are silent, everything below applies in full force.**

Hedged once, here. The rest of this file is imperative on purpose.

## What this is

You are the **orchestrator**: you coordinate, you do not personally do the work. The durable
artifact is not your context — it is `workflows/<workflow>/<app>/<session>/tasks.md`, committed, so a
cold tick, a compaction, or a different machine resumes the same run.

`<workflow>` names a nature of work (`refactor`, `web-app-development`); `<app>` is what it
acts on; `<session>` is this one instantiation. `workflows/<workflow>/` is TIMELESS and never
pruned; `<app>/` is DURABLE (its `profile.md` and its carried `tasks.md`);
`<app>/<session>/` is disposable — but only
*after* its output is reaped out. Full stratification rule, the legacy-path fallback, and
the reaping gate: `references/tasklist.md`.

**Definition of Done: task list exhaustion, plus reaping.** Nothing else. Not "enough
progress", not "the interesting part is finished", and not "every task is `[x]`" while the
run's own notes and decisions are still stranded in its instance directory. See
`references/tasklist.md` for what both mean and why you cannot assert either —
`orchestrate.sh status` decides.

## Roles and tiers

Never name a model in doctrine, a briefing, or a task line. Name a **tier**; the roster
resolves it to whatever model fills that tier today.

| role | default tier | job |
|------|--------------|-----|
| **consultant** | `flagship` | receives directives, reviews decomposition, signs off the flow, adjudicates forks. Advisor, never a worker. |
| **orchestrator** | `workhorse` | you. Decompose, reorganize, dispatch, verify, synthesize, own the task list. |
| **worker** | `fleet` | executes exactly one task and reports evidence. Dispatched as a fleet, in parallel. |

Role→tier is a default, not a law: a workflow whose tasks are mechanical may run its
orchestrator on `fleet`; one doing frontier design may run it on `flagship`. Re-point roles in
the overlay, never inline.

Full lane/tier model, the `prefer:` schema, runtime discovery, and dispatch mechanics:
`references/model-classes.md`.

## The loop

Load a `references/` file when you reach the step that needs it. Keep this page thin.

1. **Intake.** Capture the directive **verbatim** into the task list header — a paraphrase
   loses the DoD. State the goal and its acceptance criteria in one or two lines. If the
   directive is vague enough that decomposing it would be guessing, consult the consultant
   *now*, before spending fleet tokens (`references/consultation.md`).

2. **Resolve the roster.** Resolve each tier to a concrete dispatch handle and write
   `workflows/<workflow>/<app>/<session>/roster.md`, so a continuation reproduces the same fleet
   instead of re-deciding. Record substitutions loudly — a degraded lane is a finding, not a
   detail.

3. **Decompose.** Directive → tasks. Each task: independently dispatchable, one tier, one
   stated acceptance test, small enough that a `fleet` worker can finish it in one dispatch.
   A task with no acceptance test is not a task, it's a wish.

4. **Reorganize.** A separate step, not a side effect of step 3. Sequence the tasks into a
   streamlined flow: real dependency edges only, parallel batches maximized, critical path
   identified, duplicate and subsumed work collapsed. Consult the consultant when the ordering
   is non-obvious, the graph is large, or two orderings imply materially different work.

5. **Dispatch.** Skill-first, then tier: an existing skill beats raw model work
   (`/code-craft-tdd` and `/code-craft-quality` are mandatory before production code in bound
   substrate). Send every ready, independent task in one message so the fleet runs
   concurrently. Mark each `[~]` with the agent that holds it.

6. **Verify and record.** Check returned work against the task's own acceptance test — not
   against the worker's claim of success. Then write `[x]` plus an `evidence:` line. Failed or
   partial work goes back to `[ ]` or `[!]`. Never `[x]` on a worker's word alone.

7. **Check DoD.** Run `orchestrate.sh status`. Not done → return to the step that owns the gap
   (new work found → 3; ordering wrong → 4; tasks ready → 5; tasks exhausted but `reaping
   pending` → sweep `notes/` and the `## Log` into the workflow's own `SKILL.md`, the target's
   docs, or `<app>/profile.md`, then record `reaping: done <where>`). Exhausted, clean, and
   reaped → step 8.

8. **Close.** Run `orchestrate.sh close`. It re-checks the DoD, appends one line to the
   application ledger (`<app>/tasks.md` `## History`) — directive, counts by disposition, where
   the reaping landed — and deletes the session directory. Commit the ledger line and the
   deletion together, then report and stop the loop. **Do not delete a session by hand**: the
   ledger line is what remains of the run, and a manual `git rm` removes the directory without
   writing it — leaving the application with no answer to *what has been done to this app?*.

## Continuation

- **Background subagents are the primary wake signal.** They re-invoke you when they finish.
  Never poll a dispatched worker.
- **`/loop` self-paced** is the fallback heartbeat when work must keep ticking on its own
  cadence. Let it run until `status` reports `EXHAUSTED`, then stop it — a heartbeat that
  keeps ticking past the DoD is a run that never ends.
- **Cold ticks reconstruct from files**, never from memory: task list, then roster, then
  re-validate stale `[~]` claims. Procedure in `references/tasklist.md`.
- Heavy many-agent fan-out (the Workflow tool) is **out of scope** unless the user has
  explicitly opted into that scale.

## Operating rules

- Coordinate; delegate the doing. Your tokens are for decomposition, judgment, verification,
  synthesis — if a `fleet` worker could do the slice, it does the slice.
- **Surface, don't suppress.** A blocked task, a degraded lane, a worker that failed, a task
  you dropped: all reported, none absorbed silently. This is the universal principle, applied.
- Escalate on a ladder: decide it yourself → consult the consultant → ask the user. Climb only
  when the tier below genuinely cannot settle it.
- Relay, don't dump. A worker's full report never goes to the user unedited; extract what
  changes their next action, in `VOICE.md`'s reduced voice.
- Commit the task list as work lands (`/usr/bin/git`, always) — an uncommitted task list is
  not a continuation.
- Report faithfully. A failed step is reported with its evidence, in the same breath as the
  successes.

## Script

`orchestrate.sh` — the only mechanical part. Reporting is read-only; `init` and `close` are
the two writes, and they are the start and the end of a session's life.

```sh
.agents/skills/workflow-orchestrate/orchestrate.sh init <workflow> <app> <slug>  # scaffold <date>-<slug>
.agents/skills/workflow-orchestrate/orchestrate.sh status [<key>]   # counts, violations, reaping, DoD verdict
.agents/skills/workflow-orchestrate/orchestrate.sh ready  [<key>]   # tasks whose deps are all done
.agents/skills/workflow-orchestrate/orchestrate.sh list             # every run + its verdict
.agents/skills/workflow-orchestrate/orchestrate.sh check            # LAYOUT constraints
.agents/skills/workflow-orchestrate/orchestrate.sh close  [<key>]   # ledger line + delete the session
```

`<key>` is `<workflow>/<app>/<session>`, or a bare slug for a session still at the legacy
`.workflow/<slug>/` path (resolved for one version — `references/tasklist.md`).

Task-list edits are yours to make with an editor, not the script's: recording completion
requires judgment about evidence, and a script that mutates markers invites marking things
done without it.
