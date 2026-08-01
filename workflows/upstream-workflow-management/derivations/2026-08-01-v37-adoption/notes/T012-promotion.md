# T012 — promote the update-bootstrap defect into the core

Worked in the core itself (`/home/henning/workflows/workflow-template`), not a
derivation. All git via `/usr/bin/git`. Released as **v41**, commit `190ff4b`.

## 1. The four-part promotion test — applied

Test from `workflows/upstream-workflow-management/SKILL.md`, "The promotion test".

**1 — General. PASS.** The claim contains no reference to any area of work: *a
derivation performs its update with its own copy of `template-sync.sh`, so update
semantics reach a repo one release after the manifest they govern.* True for a workflow
repo whose subject is schema management, incident response, or anything else. The three
repos that exhibited it (`workflow-monolith`, `stewardship`, `sandbox`) share only that
they are derivations.

**2 — Shaped, not opinionated. PASS.** `update` is an operation on a shape the core
owns — the managed set declared by `template-manifest.yaml`. The defect is that the
operation does not do what the shape's own documentation says it does. No engineering
opinion is involved and there is no pack this could belong to instead.

**3 — Owned by a managed set. PASS.** Every path touched is already in `managed:`:

```
.agents/skills/workflow-template-sync/template-sync.sh -> .agents/skills/workflow-template-sync/**
.agents/skills/workflow-template-sync/SKILL.md         -> .agents/skills/workflow-template-sync/**
template-manifest.yaml                                 -> template-manifest.yaml
workflows/upstream-workflow-management/references/promotion.md -> workflows/upstream-workflow-management/references/**
```

No new manifest entry needed, so the ordering rule of `promotion.md` §3 (coverage before
bump) is satisfied trivially. Coverage was verified with that section's glob check
before `VERSION` was touched.

**4 — Evidenced. PASS.** Three converges in this run (T005, T006, T007) each needed the
same manual pre-step, and each recorded the literal `removed …` lines that appeared only
because of it. `notes/T007-sandbox-converge.md` §1 holds the clearest instance: the
bootstrap copy, then `update`, with `.template.lock` still reading `13` at copy time,
proving the stage happened before the manifest moved.

**Verdict: passes all four. Promote.**

### One correction to the task's premise

The task states the removal logic arrived in **v37**. It arrived in **v30** —
`c0707e7 v30: composition — the core plus packs` is the commit that introduced
`remove_paths` and the `comm -23` diff in `update_core`:

```
$ /usr/bin/git show c0707e7:.agents/skills/workflow-template-sync/template-sync.sh \
    | grep -n 'update_core' -A 45 | grep -E 'comm -23|remove_paths|copy_paths'
431-  comm -23 "$old" "$new" > "$gone"
432-  remove_paths "$ROOT" "$gone"
433-  copy_paths "$upstream_root" "$ROOT" "$new"
```

The v17-era script has `copy_managed_paths` and no removal of any kind, exactly as the
task describes. Nothing about the finding changes — the three affected derivations were
on 13, 17 and 19, all well below either number — but the threshold written into the
skill and the commit is **v30**, because that is the version an operator will compare
`.template.lock` against.

## 2. The approach

**Chosen: `update_core` self-hosts the update.** When the core is behind and not pinned,
it stages the upstream's `.agents/skills/workflow-template-sync/` over this repo's copy
and re-execs it before doing anything else.

Why this and not the alternatives:

- It is the categorical rule applied (`AGENTS.CORE.md`, Composition): the core owns
  every operation on its shapes. A footgun that needs a human to remember a manual
  pre-step is not an operation the core owns.
- It is general, not symptom-specific. Every future change to update semantics applies
  on the release that introduces it instead of the one after.
- Staging touches only that directory — never `template-manifest.yaml` — so the OLD
  manifest is still on disk when the new script reads it. The dropped-path diff is
  computed by new logic against old data, which is exactly the arrangement the manual
  workaround produced by hand.

Guards: one stage per run (`WORKFLOW_TEMPLATE_SYNC_RESTAGED`, so no re-exec loop);
strictly after the pinned / up-to-date / upstream-behind gates, so a run that will not
update anything does not rewrite the repo's script either; and the staged copy is
`bash -n`-parsed in a temp directory before it replaces anything, because a half-written
stage leaves the repo with no working sync skill at all — worse than the stale one.

**Rejected — capture the old manifest's path list before overwriting it.** Fixes this
one symptom and nothing else. The next change to update semantics is late again, and a
pre-v30 script would not write the record either, so it does not even reach the
derivations that motivated the task.

**Rejected — documentation only, an explicit scripted pre-step.** Leaves a correct
update contingent on an operator reading the right section first. Kept as the fallback
for the case code cannot reach (below), not as the fix.

**What it does NOT cover.** A derivation whose installed script predates this staging
step — every core below v41, and destructively below v30. That script stages nothing, so
its first update still runs old logic. Nothing in a release can reach code that is never
executed. Those repos need the hand-stage, now stated in
`.agents/skills/workflow-template-sync/SKILL.md` → "The stale-script constraint", with
the verification that it took: one `removed <path>` line per retired path.

Also not covered: a derivation already damaged by a past silent update. The orphans are
on disk and the record of what the core used to own is gone; finding them is an
inspection, not an update.

## 3. What changed

| File | Change |
|---|---|
| `.agents/skills/workflow-template-sync/template-sync.sh` | `ORIG_ARGV`, `SYNC_SKILL_REL`, `stage_sync_skill()`, the stage+re-exec in `update_core`, and the "stale-script problem" comment block that states why |
| `.agents/skills/workflow-template-sync/SKILL.md` | new section "The stale-script constraint" under `update` — the mechanism, its guards, the pre-v30 case, and the hand-stage commands |
| `workflows/upstream-workflow-management/references/promotion.md` | §5 gains a pointer (not a restatement) to that rule |
| `VERSION`, `template-manifest.yaml` | 40 → 41, together |

## 4. Verification — literal output

Manifest coverage check (`promotion.md` §3), run BEFORE the version bump:

```
.agents/skills/workflow-template-sync/template-sync.sh -> .agents/skills/workflow-template-sync/**
.agents/skills/workflow-template-sync/SKILL.md -> .agents/skills/workflow-template-sync/**
template-manifest.yaml -> template-manifest.yaml
workflows/upstream-workflow-management/references/promotion.md -> workflows/upstream-workflow-management/references/**
```

Syntax:

```
$ bash -n .agents/skills/workflow-template-sync/template-sync.sh && echo "bash -n template-sync.sh: OK"
bash -n template-sync.sh: OK
```

Functional test — synthetic derivation at v41 against a synthetic upstream at v42, with
one managed path (`.agents/skills/fake-retired/**`) retired by the upstream manifest and
a marker line appended to the upstream's `template-sync.sh`:

```
workflow-core: 41 -> 42
  staged .agents/skills/workflow-template-sync from upstream — re-running update with it
workflow-core: 41 -> 42
  removed .agents/skills/fake-retired/**
exit=0
=== orphan ===
GONE
=== lock ===
template_version: 42
=== staged script is upstream's? ===
1
```

One stage, one re-exec, no loop; removal computed by the NEW script against the OLD
manifest; lock stamped.

Gates:

```
=== re-run (now up to date) ===
workflow-core: up to date (42)
=== pinned ===
workflow-core: pinned — not updating. installed=41, available=42
derivation script touched by the pinned run? (expect 0)
0
```

`check.sh`:

```
$ .agents/skills/workflow-check/check.sh
workflow-check — organizational constraints (registry: .agents/skills/workflow-check/references/constraints.md)

TOOL       ok
AGENTS     ok
LAYOUT     ok
PLUGIN     ok

all constraints met
check.sh exit=0
```

`orchestrate.sh status` — the live session still parses and reports; exit 2 is the open
session, not a failure:

```
$ .agents/skills/workflow-orchestrate/orchestrate.sh status
session: upstream-workflow-management/derivations/2026-08-01-v37-adoption
tasks       18
  pending   7
  in flight 2
  done      9
  blocked   0
  carried   0
  dropped   0
harvest     pending
DoD: NOT EXHAUSTED (9 open)
orchestrate status exit=2
```

## 5. Commit

`190ff4b` — `core: v41 — an update runs the release's own logic, not the derivation's`.
Not pushed; the orchestrator pushes.

## 6. For the orchestrator

- The core is now **v41**. T015–T017 converge onto 41, not 40. None of the three needs a
  hand-stage: all are on 37 or later, so their own scripts remove dropped paths, and
  from this release forward they will also self-stage.
- T014 is serialized behind this task for the shared `VERSION` / manifest bump. That bump
  is done and committed; T014 starts from 41 and releases 42.
- No journal entry written, per the task. Whether the rejected-alternatives reasoning
  qualifies for `journal/` is the harvest decision; the commit body carries it either way.
