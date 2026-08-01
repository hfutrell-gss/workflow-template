# T006 — stewardship converged v17 -> v37

Target: `/home/henning/workflows/stewardship`. Commit **`3ffe847a32c21b074114c29989503895e32ce45d`**
(`3ffe847 core: converge to template v37 and install the code-craft pack`). **Not pushed**
(`## main...origin/main [ahead 37]` — 36 of those pre-date this task).

Every git command ran as `/usr/bin/git`. Working tree was clean before (`git status --porcelain`
empty) and is clean after.

---

## Step 1 — bootstrap (v37 template-sync.sh copied in BEFORE update)

```
cp -r /home/henning/workflows/workflow-template/.agents/skills/workflow-template-sync/. \
      /home/henning/workflows/stewardship/.agents/skills/workflow-template-sync/
```
Result:
```
COPY OK
 M .agents/skills/workflow-template-sync/SKILL.md
 M .agents/skills/workflow-template-sync/template-sync.sh
?? .agents/skills/workflow-template-sync/pack-scan.sh
```
Local `template-manifest.yaml` was still the v17 one at this point, which is what lets the new
script compute `old − new` and emit the `removed` lines below.

## Step 2 — `template-sync.sh update` (literal output)

```
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
workflow-core: 17 -> 37
  removed .agents/skills/craft-code-quality/**
  removed .agents/skills/craft-tdd/**
  removed .agents/skills/workflow-gateway/**
  removed .claude/skills/craft-code-quality/SKILL.md
  removed .claude/skills/craft-tdd/SKILL.md
  removed .claude/skills/workflow-gateway/SKILL.md
  synced AGENTS.CORE.md
  synced .agents/skills/workflow-agents-sync/**
  synced .agents/skills/workflow-bind/**
  synced .agents/skills/workflow-check/**
  synced .agents/skills/workflow-init/**
  synced .agents/skills/workflow-manage/**
  synced .agents/skills/workflow-orchestrate/**
  synced .agents/skills/workflow-template-sync/**
  synced CLAUDE.md
  synced .claude/skills/upstream-workflow-management/SKILL.md
  synced .claude/skills/workflow-agents-sync/SKILL.md
  synced .claude/skills/workflow-bind/SKILL.md
  synced .claude/skills/workflow-check/SKILL.md
  synced .claude/skills/workflow-init/SKILL.md
  synced .claude/skills/workflow-manage/SKILL.md
  synced .claude/skills/workflow-orchestrate/SKILL.md
  synced .claude/skills/workflow-template-sync/SKILL.md
  synced GLOSSARY.md
  synced template-manifest.yaml
  synced VOICE.md
  synced workflows/upstream-workflow-management/references/**
  synced workflows/upstream-workflow-management/SKILL.md
```

The bootstrap was load-bearing: the `removed` block is exactly what the v17 script could not
produce. Without it, `.template.lock` would still have been written to 37 and every later `update`
would have said "up to date" with six orphaned paths on disk.

### On-disk verification that the dropped paths are GONE

```
$ find . -path ./.git -prune -o -path ./workspace -prune -o \( -name '*craft*' -o -name '*gateway*' \) -print
./.agents/craft
```
Only the (empty, unmanaged) overlay directory survived — renamed in step 5. **Nothing had to be
removed by hand.**

```
$ ls .agents/skills/
workflow-agents-sync  workflow-bind  workflow-check  workflow-init
workflow-manage  workflow-orchestrate  workflow-template-sync

$ ls .claude/skills/
upstream-workflow-management  workflow-agents-sync  workflow-bind  workflow-check
workflow-init  workflow-manage  workflow-orchestrate  workflow-template-sync

$ cat .template.lock
template_version: 37
upstream: git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
derived: 2026-07-28
pinned: false
```

`grep -rn "workflow-gateway"` over the repo (excluding `.git`, `workspace/`) → **exit 1, no
matches**. No dangling gateway references to delete.

## Step 3 — AGENTS chain fixed by hand

`update` rewrote `CLAUDE.md` (managed) to the v37 single-import shape. `AGENTS.md` is unmanaged and
had no `@AGENTS.CORE.md` import at all — only prose about it. Two edits to
`/home/henning/workflows/stewardship/AGENTS.md`:

1. Inserted a bare `@AGENTS.CORE.md` line immediately after the frontmatter, before `## Core check`.
2. **Beyond the literal instruction, flagged here:** replaced the stale "Core check" paragraph with
   upstream's v37 wording. The old text told the reader the root `CLAUDE.md` "must import both
   `@AGENTS.CORE.md` and `@AGENTS.md`" — now false, and `agents-sync` enforces the opposite. Left as
   written it was an active trap: a reader following it would re-break the chain. Stewardship's own
   doctrine (everything from `# Stewardship — doctrine` down) is byte-identical.

Chain verified:
```
$ cat CLAUDE.md
# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.md is canonical -->

@AGENTS.md

$ sed -n '1,8p' AGENTS.md
---
tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
---

@AGENTS.CORE.md

## Core check

$ grep -n '^@' AGENTS.CORE.md
7:@VOICE.md
```
`CLAUDE.md` → `@AGENTS.md` → `@AGENTS.CORE.md` → `@VOICE.md`. `agents-sync.sh` reports no root-chain
drift.

## Step 4 — code-craft pack installed (literal output)

```
$ .agents/skills/workflow-template-sync/template-sync.sh add ssh://github-personal/henningfutrell/pack-code-craft.git
HEAD is now at 3662d90 v2: declare requires_core: 30
scanning pack 'code-craft'...

pack-scan: no findings. This is a heuristic pass, not a guarantee — it does not
           detect a competent attacker. Install packs you wrote, or packs whose
           maintainer you already trust with this repo.
HEAD is now at 3662d90 v2: declare requires_core: 30
code-craft: <not installed> -> 2
  synced .agents/skills/code-craft-event-naming/**
  synced .agents/skills/code-craft-quality/**
  synced .agents/skills/code-craft-tdd/**
  synced .agents/skills/code-craft-ubiquitous-language/**
  synced .claude/skills/code-craft-event-naming/SKILL.md
  synced .claude/skills/code-craft-quality/SKILL.md
  synced .claude/skills/code-craft-tdd/SKILL.md
  synced .claude/skills/code-craft-ubiquitous-language/SKILL.md
added pack 'code-craft' from ssh://github-personal/henningfutrell/pack-code-craft.git
EXIT=0
```
`packs.yaml` and `packs.lock` created by the tool. `template-sync.sh list`:
```
PACK                       VERSION   UPSTREAM
workflow-core (core)       37        git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
code-craft                 2         ssh://github-personal/henningfutrell/pack-code-craft.git
```

## Step 5 — craft-* references re-pointed

**Overlay directory:** `/usr/bin/mv .agents/craft .agents/code-craft`. It was empty and untracked
(`git ls-files .agents/craft` → nothing), so no content moved and git records no change; the slot
now sits where the pack looks for it.

**Unmanaged overlays edited:**

| File | Line | Change |
|---|---|---|
| `/home/henning/workflows/stewardship/.agents/orchestrate/roster.local.yaml` | 21 | `/craft-tdd` → `/code-craft-tdd` |
| same | 22 | `/craft-code-quality` → `/code-craft-quality` |
| same | 25 | "no craft skill applies" → "no code-craft skill applies" |
| `/home/henning/workflows/stewardship/.agents/orchestrate/orchestrate.local.md` | 85 | `/craft-tdd` and `/craft-code-quality` → `/code-craft-tdd` and `/code-craft-quality` |

**Whole-repo sweep for any other `craft-` reference** (excluding `.git`, `workspace/`, and the
pack's own `code-craft-*` directories) found, and disposed of, exactly these:

- `.workflow/**` — handled in step 6 below.
- `journal/2026-07-30-template-sync-v13-v17.md:38,40,43,50,70,81` — **deliberately left verbatim.**
  A journal entry is a dated record of what the system was at v17. Rewriting it would make the
  archaeology lie; the v37 entry belongs beside it, not on top of it.
- `.agents/skills/workflow-template-sync/pack-scan.sh:72` — managed core file; upstream already
  matches both `.agents/craft/*` and `.agents/code-craft/*`. No action.
- `workspace/**` — gitignored substrate clones (Envoy Gateway, AWS Transit Gateway, `tool-craft.tfvars`,
  `@ai-sdk/gateway`, …). Unrelated to the skill names and outside this task's boundary.

**`workflow-gateway`:** zero references anywhere in the repo. Nothing to delete.

## Step 6 — the four legacy live sessions

### `orchestrate.sh list` (literal, run after the update; identical before and after the edits)

```
NOTE: legacy session at .workflow/2026-07-30-agents-file-diet/ — migrate to workflows/<workflow>/<app>/<session>/ (this fallback is scheduled for removal in a future version)
2026-07-30-agents-file-diet                          DoD: NOT EXHAUSTED (7 open)
NOTE: legacy session at .workflow/2026-07-30-bulletproof-audit/ — migrate to workflows/<workflow>/<app>/<session>/ (this fallback is scheduled for removal in a future version)
2026-07-30-bulletproof-audit                         DoD: NOT EXHAUSTED (8 open)
NOTE: legacy session at .workflow/2026-07-30-fix-devexpress-masaba/ — migrate to workflows/<workflow>/<app>/<session>/ (this fallback is scheduled for removal in a future version)
2026-07-30-fix-devexpress-masaba                     DoD: NOT EXHAUSTED (36 open)
NOTE: legacy session at .workflow/2026-07-30-ops-tools-83-event-log/ — migrate to workflows/<workflow>/<app>/<session>/ (this fallback is scheduled for removal in a future version)
2026-07-30-ops-tools-83-event-log                    DoD: NOT EXHAUSTED (11 open)
EXIT=2
```
All four resolve, each with its legacy NOTE. Exit 2 is the ordinary "not done" state, not a failure.
(Counts differ from the T001 survey — 36 vs 20, 11 vs 9 — because `orchestrate.sh` counts every
non-terminal marker as open, not only `[ ]`. No marker was changed by this task; see the diff proof
below.)

### Reference repairs — exactly these lines, nothing else

| File | Line | Before → after |
|---|---|---|
| `.workflow/2026-07-30-ops-tools-83-event-log/tasklist.md` | 77 | "Working arrangement" mandate: `/craft-tdd` and `/craft-code-quality` → `/code-craft-tdd` and `/code-craft-quality` |
| `.workflow/2026-07-30-fix-devexpress-masaba/roster.md` | 43, 44 | dispatch rule mandate, same rename |
| same | 58, 59 | lane-unavailability rule, same rename |
| `.workflow/2026-07-30-fix-devexpress-masaba/tasklist.md` | 193 | open task **T024**, `why this exists:` — `` `craft-code-quality` `` → `` `code-craft-quality` `` |
| same | 315 | Log L1, same rename |
| same | 380 | Log entry, lane-state mandate, same rename |

`git diff --stat -- .workflow`: `8 insertions(+), 8 deletions(-)` across 3 files. Line-for-line
substitutions only.

**Proof no task marker moved:**
```
$ git diff -U0 -- .workflow | grep -E '^[+-]- \['
$ echo $?
1
```
No added or removed line begins a task. No `[ ]` became `[x]`; no `evidence:`, `accept:`, `carried:`
or `landed:` field was added, removed, or altered.

### Deliberately NOT changed inside the sessions

Historical evidence on **completed** tasks keeps the name the skill had when the work was done:
- `.workflow/2026-07-30-ops-tools-83-event-log/tasklist.md:98,105,140`
- `.workflow/2026-07-30-fix-devexpress-masaba/tasklist.md:78`
- `.workflow/2026-07-30-agents-file-diet/tasklist.md:53`

Generic class references ("craft-skill", "no craft skill applies") that name no skill:
- `.workflow/2026-07-30-bulletproof-audit/roster.md:29`
- `.workflow/2026-07-30-agents-file-diet/roster.md:29`, `tasklist.md:99`
- `.workflow/2026-07-30-fix-devexpress-masaba/roster.md:70`, `tasklist.md:384`

Rewriting either class would edit the record of what was decided, which is a status change in
everything but name.

### What a migration to `workflows/<workflow>/<app>/<session>/` would require

Not done here — it is per-session judgment, and the fallback buys one more version. What it needs:

1. **A workflow name per session.** The four are not one nature of work:
   `agents-file-diet` and `bulletproof-audit` are doctrine/audit work on this repo and its
   substrate; `fix-devexpress-masaba` is application defect work; `ops-tools-83-event-log` is
   feature work with a gitops dependency. Two or three `workflows/<name>/SKILL.md` bodies must
   exist first (`orchestrate.sh init` will not invent them) — scaffold with
   `/workflow-manage new-workflow <name>`. Names must avoid the reserved `workflow-*` prefix, the
   `code-craft-*` pack prefix, and the managed `upstream-workflow-management`.
2. **An application per session**, with `workflows/<wf>/<app>/profile.md` (LAYOUT-005) and
   `workflows/<wf>/<app>/tasks.md` carrying both a `## Open` and a `## History` section
   (LAYOUT-008). Candidates read off the sessions: `global-shop-solutions`, `ops-tools`,
   `self`/`stewardship`. Deciding whether `fix-devexpress-masaba` is one application or two
   (`global-shop-solutions` + `gitops`) is the real judgment call — T017 in
   `ops-tools-83-event-log` is already a gitops task inside an ops-tools session, so the
   one-session-one-application rule does not fit these four cleanly.
3. **Rename `tasklist.md` → `tasks.md`** in each session directory; `roster.md` and `notes/` keep
   their names. Session directory name becomes `<date>-<slug>`, which the existing slugs already are.
4. **Re-validate against the v37 grammar.** `orchestrate.sh check` applies TASK rules to the new
   path that the legacy fallback does not enforce: `[^]` needs `carried:` naming an entry in
   `<app>/tasks.md`; `[-]`/`[^]` need `landed:` at harvest. Some existing `accept-partial` /
   `blocked-on-owner` fields will need re-expressing.
5. **`.workflow/` must end up empty and deleted** — `LAYOUT-001` fires while it exists, and it is
   currently one of the six LAYOUT violations below.
6. **`SUBSTRATE-001` will still fire afterward.** Substrate repos cite `.workflow/...` paths and
   `T###` IDs (23 296 lines in `global-shop-solutions`, 254 in `workflow-console`, 1 in `ops-tools`).
   Migration does not fix those citations; it makes them dead sooner. Most are build artefacts and
   `.trx`/`.ndjson` files, so the count is textual, not verified.

## Step 7 — verification, literal output

### `template-sync.sh --check`
```
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
workflow-core: up to date (37)
HEAD is now at 3662d90 v2: declare requires_core: 30
code-craft: up to date (2)
status: up to date
EXIT=0
```
**No drift.**

### `template-sync.sh --audit`
```
EXIT=0
```
Silent, exit 0 — no managed file locally modified.

### `template-sync.sh list`
```
PACK                       VERSION   UPSTREAM
workflow-core (core)       37        git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
code-craft                 2         ssh://github-personal/henningfutrell/pack-code-craft.git
EXIT=0
```

### `.agents/skills/workflow-check/check.sh` — **exit 2, NOT clean**
```
workflow-check — organizational constraints (registry: .agents/skills/workflow-check/references/constraints.md)

TOOL       VIOLATIONS
           WARNING: 'git' is aliased to a Windows binary at /home/henning/.zshenv:39 — this shadows native git in interactive shells (this script itself is unaffected; bash doesn't source /home/henning/.zshenv). Always invoke /usr/bin/git explicitly for this repo, or fix/guard the alias in /home/henning/.zshenv.
           init.lock version '4' != required '6'
AGENTS     VIOLATIONS
           MISSING .github: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
           MISSING identity: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
           MISSING platform: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
           MISSING global-shop-solutions: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
           DRIFT   gitops: CLAUDE.md does not import @AGENTS.md — move its content into AGENTS.md, replace with the bridge
           MISSING infrastructure-as-code: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
           MISSING ops-tools: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
           MISSING launchpad: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
LAYOUT     VIOLATIONS
             ! LAYOUT-001 .workflow/ still exists — sessions live at workflows/<workflow>/<app>/<session>/
             ! SUBSTRATE-001 global-shop-solutions cites workflow-repo session paths — 23296 citing lines across 157 files; worst: source/GlobalShopSolutions/GlobalShopSolutions.Server.Tests/TestResults/full_suite_final.trx (3868), source/GlobalShopSolutions/GlobalShopSolutions.Server.Tests/TestResults/full_suite.trx (3769), source/GlobalShopSolutions/GlobalShopSolutions.Server.Tests/obj/Debug/net8.0/GlobalShopSolutions.Server.Tests.csproj.FileListAbsolute.txt (2861). The session directory is deleted at close; substrate cites its own repo's paths only.
             ! SUBSTRATE-001 global-shop-solutions cites session task IDs (T###) — 491 citing lines across 21 files; worst: source/GlobalShopSolutions/ReadOnlyApi/bin/Release/net8.0/Catalog/v1/manufacturing/engineering-change-notices.json (40), source/GlobalShopSolutions/GlobalShopSolutions.Server/bin/Debug/net8.0/Catalog/v1/manufacturing/engineering-change-notices.json (40), source/GlobalShopSolutions/ReadOnlyApi/bin/Release/net8.0/Catalog/v1/manufacturing/engineering-change-notice-histories.json (40). A task ID is session-local. This is a textual citation count, not a verified one: a hash or a fixture can match, so read each site before editing.
             ! SUBSTRATE-001 ops-tools cites session task IDs (T###) — 1 citing line across 1 file; worst: apps/launchpad/visit-bridge/internal/mcpevent/map.go (1). A task ID is session-local. This is a textual citation count, not a verified one: a hash or a fixture can match, so read each site before editing.
             ! SUBSTRATE-001 workflow-console cites workflow-repo session paths — 255 citing lines across 16 files; worst: external-sessions/2026-07-30.ndjson (186), external-sessions/2026-07-29.ndjson (27), external-sessions/2026-08-01.ndjson (13). The session directory is deleted at close; substrate cites its own repo's paths only.
             ! SUBSTRATE-001 workflow-console cites session task IDs (T###) — 13 citing lines across 1 file; worst: external-sessions/2026-07-30.ndjson (13). A task ID is session-local. This is a textual citation count, not a verified one: a hash or a fixture can match, so read each site before editing.
           layout     6 violations
PACK       ok
TEMPLATE   ok

constraints unmet — see above; each line names the rule it broke
```
(The first run also reported `MISSING root: GLOSSARY.local.md`. Fixed — see below. `PACK ok` and
`TEMPLATE ok` are the two sections this convergence owns; both pass.)

### `orchestrate.sh check` — exit 2
```
  ! LAYOUT-001 .workflow/ still exists — sessions live at workflows/<workflow>/<app>/<session>/
  ! SUBSTRATE-001 global-shop-solutions cites workflow-repo session paths — 23296 citing lines across 157 files; …
  ! SUBSTRATE-001 global-shop-solutions cites session task IDs (T###) — 491 citing lines across 21 files; …
  ! SUBSTRATE-001 ops-tools cites session task IDs (T###) — 1 citing line across 1 file; …
  ! SUBSTRATE-001 workflow-console cites workflow-repo session paths — 254 citing lines across 16 files; …
  ! SUBSTRATE-001 workflow-console cites session task IDs (T###) — 13 citing lines across 1 file; …
layout     6 violations
```
No TASK-* violation in any of the four sessions — the task lists parse clean against the v37
grammar.

### `orchestrate.sh list` — as in step 6, all four resolve. Exit 2 (not exhausted).

### `agents-sync.sh` — exit 1
```
MISSING .github: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
MISSING identity: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
MISSING platform: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
MISSING global-shop-solutions: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
DRIFT   gitops: CLAUDE.md does not import @AGENTS.md — move its content into AGENTS.md, replace with the bridge
MISSING infrastructure-as-code: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
MISSING ops-tools: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
MISSING launchpad: AGENTS.md has no CLAUDE.md bridge (--fix creates it)
```
**Zero findings about this repo.** Every line names a standing-bind repo under the gitignored
`workspace/`. Fixed in the first run: `MISSING root: GLOSSARY.local.md` — created
`/home/henning/workflows/stewardship/GLOSSARY.local.md` by copying
`.agents/skills/code-craft-ubiquitous-language/assets/GLOSSARY.local.template.md`, which is exactly
what `--fix` does. `--fix` itself was **not** run, because it would have written into eight other
repos and this task's boundary is stewardship only.

---

## Acceptance test

| Criterion | Result |
|---|---|
| `.template.lock` reads 37 | **PASS** |
| `--check` no drift | **PASS** (`status: up to date`, exit 0) |
| `--audit` clean | **PASS** (silent, exit 0) |
| AGENTS chain correct | **PASS** — `CLAUDE.md` → `@AGENTS.md` → `@AGENTS.CORE.md` → `@VOICE.md`, verified by grep and by `agents-sync` raising no root finding |
| No orphaned craft-*/gateway path | **PASS** — six paths removed by `update`, verified absent on disk; zero `workflow-gateway` references remain |
| All four legacy sessions resolve | **PASS** — `orchestrate.sh list` resolves all four with a legacy NOTE each |
| No task marker altered | **PASS** — `git diff -U0 -- .workflow \| grep -E '^[+-]- \['` returns nothing |
| Committed | **PASS** — `3ffe847a32c21b074114c29989503895e32ce45d`, not pushed |
| `check.sh` / `orchestrate.sh check` / `agents-sync.sh` clean | **NOT MET** — see below |

### Why the three checkers are not clean, and why none is a regression from this task

None of the remaining findings is inside stewardship's own tracked files, and none was introduced
here.

1. **`init.lock version '4' != required '6'`** — per-machine, gitignored state. Clearing it means
   running `/workflow-init`, which installs/verifies system tooling outside the repo boundary this
   task was scoped to. **Left for the owner: run `/workflow-init` in stewardship on this machine.**
2. **`WARNING: 'git' is aliased to a Windows binary at /home/henning/.zshenv:39`** — a
   `~/.zshenv` finding, not a repo finding. Every git command in this task used `/usr/bin/git`.
3. **Eight AGENTS bridge findings** — all in standing-bind repos under `workspace/` (`.github`,
   `identity`, `platform`, `global-shop-solutions`, `gitops`, `infrastructure-as-code`, `ops-tools`,
   `launchpad`). Pre-existing, and stewardship's own doctrine puts them under "agent-law
   distribution across substrate" — a separate piece of work in eight other repos.
4. **`LAYOUT-001 .workflow/ still exists`** — the deliberate deferral. It clears when the four
   sessions migrate.
5. **Five `SUBSTRATE-001` findings** — citations inside substrate repos, mostly build artefacts.
   Pre-existing; not reachable from this repo.
