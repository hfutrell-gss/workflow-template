# T005 — workflow-monolith v19 → v37 convergence (EXECUTED)

Target: `/home/henning/workflows/workflow-monolith`. Only that repo touched. All git
commands run with `/usr/bin/git`. Not pushed.

## Step 0 — commit pre-existing README.md change

`README.md` was an unstaged full rewrite of the template-derived boilerplate into
monolith-specific content (own upstream-link section, area-of-work table,
static-analysis section, layout/skills tables) — already using old (pre-v37)
craft/gateway terminology, as flagged by the T002 survey.

```
On branch main
Your branch is up to date with 'origin/main'.

Changes not staged for commit:
	modified:   README.md
```

Committed alone as `241706c` — "docs: rewrite README for monolith workflow content".

## Step 1 — bootstrap: copy v37 workflow-template-sync skill first

```
cp -r /home/henning/workflows/workflow-template/.agents/skills/workflow-template-sync/. \
      /home/henning/workflows/workflow-monolith/.agents/skills/workflow-template-sync/
```

Verified after copy:
```
template-sync.sh executable: YES
pack-scan.sh executable: YES
```
(v19 copy had no `pack-scan.sh` at all; both present and executable afterward.)

## Step 2 — `template-sync.sh update`

Literal output:
```
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
workflow-core: 19 -> 37
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

Verified on disk — all six dangling paths reported gone, none survived (no explicit
removal needed):
```
gone: .agents/skills/workflow-gateway
gone: .claude/skills/workflow-gateway
gone: .agents/skills/craft-tdd
gone: .claude/skills/craft-tdd
gone: .agents/skills/craft-code-quality
gone: .claude/skills/craft-code-quality
```
Broader `find -iname "*gateway*" -o -iname "craft-*"` (excluding `workspace/`): no
matches.

## Step 3 — AGENTS chain hand-fix

`AGENTS.md` had zero `@` imports before this. Added a bare `@AGENTS.CORE.md` line
immediately after the frontmatter block (matching upstream's placement):

```diff
 ---
 tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
 ---
+@AGENTS.CORE.md
 
 ## Core check
```

Chain is now `CLAUDE.md` (`@AGENTS.md`, synced by `update`) → `AGENTS.md`
(`@AGENTS.CORE.md`, hand-added) → `AGENTS.CORE.md` (`@VOICE.md`, managed).

Note (surfaced, not fixed — out of the assigned scope of AGENTS.md:76-81):
`AGENTS.md`'s own "Core check" section (lines 8-11) still says the old-doctrine line
"it must import both `@AGENTS.CORE.md` and `@AGENTS.md`" about `CLAUDE.md`, which is no
longer how the chain works post-v37. Left untouched since it wasn't in the assigned
reconciliation scope; flagging per "surface, don't suppress."

## Step 4 — install code-craft pack

```
.agents/skills/workflow-template-sync/template-sync.sh add ssh://github-personal/henningfutrell/pack-code-craft.git
```

Literal output:
```
workflow-template-sync: cloning remote upstream 'ssh://github-personal/henningfutrell/pack-code-craft.git' into cache (/home/henning/.cache/workflow-template-sync/969d385ffafa30651c72c8b53af80373f20d104f)...
Cloning into '/home/henning/.cache/workflow-template-sync/969d385ffafa30651c72c8b53af80373f20d104f'...
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
```

Pack's real skill names confirmed: `code-craft-tdd`, `code-craft-quality`,
`code-craft-event-naming`, `code-craft-ubiquitous-language` — matches the names named in
the task.

## Step 5 — reconcile stale references

`AGENTS.md` "Craft defaults" section (was lines 76-81): `/craft-tdd` → `/code-craft-tdd`,
`/craft-code-quality` → `/code-craft-quality`, `.agents/craft/tdd.local.md` →
`.agents/code-craft/code-craft-tdd.local.md`, `.agents/craft/code-quality.local.md` →
`.agents/code-craft/code-craft-quality.local.md`. Confirmed exact overlay filenames by
grepping the installed skill bodies (`code-craft-tdd/SKILL.md:22`,
`code-craft-quality/SKILL.md:24`) rather than guessing.

`README.md` (was lines 64-88): layout table `.agents/craft/` row → `.agents/code-craft/`;
skills table `craft-*` prefix mention → `code-craft-*`; dropped the `/workflow-gateway`
row outright; renamed `/craft-tdd`/`/craft-code-quality` rows to
`/code-craft-tdd`/`/code-craft-quality`; updated the trailing overlay-path sentence to
`.agents/code-craft/<skill>.local.md`.

Post-edit repo-wide grep for stale names (excluding `journal/` and `workspace/`) turned
up one more dangling case **outside the assigned scope**: this repo's own bespoke
`.agents/skills/static-analysis/SKILL.md` (unmanaged, hand-authored) still references
`/craft-code-quality` (old name) and the old `.agents/craft/static-analysis.local.md`
overlay convention throughout. Surfaced, not fixed — it wasn't named in the assigned
reconciliation scope (AGENTS.md:76-81, README.md:64-88) and none of the verification
commands in step 6 check skill-body prose, so it doesn't block the acceptance test, but
it is now stale and should be reconciled in a follow-up.

## Step 6 — verification (all re-run after fixes below; literal output)

**`template-sync.sh --check`**
```
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
workflow-core: up to date (37)
HEAD is now at 3662d90 v2: declare requires_core: 30
code-craft: up to date (2)
status: up to date
```
Exit 0.

**`template-sync.sh --audit`** — first pass found a real gap:
```
MISSING PACK-005: pack 'code-craft' is installed but its overlay directory '.agents/code-craft/' does not exist — create it; it is where this repo's answers to 'code-craft' live, and without it that content lands in a bound repo and is inherited by nothing
```
Fixed by creating `.agents/code-craft/.gitkeep` (empty overlay directory — no doctrine
invented, purely the categorical mechanism the pack install requires; matches the
existing convention of tracked-but-empty overlay dirs, e.g.
`.agents/orchestrate/roster.local.yaml.example`). Re-run, clean:
```
(no output)
```
Exit 0.

**`template-sync.sh list`**
```
PACK                       VERSION   UPSTREAM
workflow-core (core)       37        git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
code-craft                 2         ssh://github-personal/henningfutrell/pack-code-craft.git
```

**`.agents/skills/workflow-check/check.sh`** — first pass had 3 real findings:
```
workflow-check — organizational constraints (registry: .agents/skills/workflow-check/references/constraints.md)

TOOL       VIOLATIONS
           WARNING: 'git' is aliased to a Windows binary at /home/henning/.zshenv:39 — this shadows native git in interactive shells (this script itself is unaffected; bash doesn't source /home/henning/.zshenv). Always invoke /usr/bin/git explicitly for this repo, or fix/guard the alias in /home/henning/.zshenv.
           init.lock version '5' != required '6'
AGENTS     VIOLATIONS
           MISSING root: GLOSSARY.local.md — this workflow has no glossary of its own (--fix creates it)
LAYOUT     VIOLATIONS
             ! LAYOUT-001 .workflow/ still exists — sessions live at workflows/<workflow>/<app>/<session>/
           layout     1 violation
PACK       ok
TEMPLATE   ok

constraints unmet — see above; each line names the rule it broke
```
Exit 2. Fixed:
- Ran `.agents/skills/workflow-init/init.sh` (no new tool installs needed — all
  required/decided tools already present at the old lock) → `init.lock` rewritten to
  version 6. The `git` alias WARNING (`~/.zshenv:39`, points at a Windows git binary) is
  pre-existing **machine** state outside the repo's boundary — untouched, and irrelevant
  to this task since every git command here used `/usr/bin/git` explicitly throughout.
- Ran `.agents/skills/workflow-agents-sync/agents-sync.sh --fix` → created
  `GLOSSARY.local.md`.
- Confirmed `.workflow/` was empty (`find .workflow -type f` → no output, per the T002
  survey too) and removed it with `rmdir` (LAYOUT-001: "sessions predating this layout
  resolve for one more version at `.workflow/<slug>/`" — this repo had zero sessions in
  it, nothing to migrate).

Re-run, clean:
```
workflow-check — organizational constraints (registry: .agents/skills/workflow-check/references/constraints.md)

TOOL       ok
AGENTS     ok
LAYOUT     ok
PACK       ok
TEMPLATE   ok

all constraints met
```
Exit 0.

**`.agents/skills/workflow-orchestrate/orchestrate.sh check`** — first pass:
```
  ! LAYOUT-001 .workflow/ still exists — sessions live at workflows/<workflow>/<app>/<session>/
layout     1 violation
```
Exit 2. After the same `.workflow/` removal above, re-run, clean:
```
layout     all conforming
```
Exit 0. (No sessions existed to report either way — not the failure mode this note
anticipated.)

**`.agents/skills/workflow-agents-sync/agents-sync.sh`** — first pass:
```
MISSING root: GLOSSARY.local.md — this workflow has no glossary of its own (--fix creates it)
```
Exit 1. After `--fix` above, re-run, clean:
```
agents-sync: all conforming
```
Exit 0.

## Step 7 — commit

```
git add -A
git commit -m "core: converge v19 -> v37, install code-craft pack ..."
```

```
6719782 core: converge v19 -> v37, install code-craft pack
241706c docs: rewrite README for monolith workflow content
d55b46a chore: drop template orchestration state carried in by derive
```

Not pushed (branch is ahead of `origin/main` by 2 commits — `241706c` and `6719782`).

## Acceptance test — verified

- `.template.lock`: `template_version: 37` — confirmed (shown above).
- `--check`: `status: up to date` — confirmed.
- `check.sh`, `orchestrate.sh check`, `agents-sync.sh`: all clean (`all constraints met`
  / `all conforming` / `all conforming`) — confirmed after the three fixes in step 6.
- AGENTS chain: `CLAUDE.md` → `@AGENTS.md` → `@AGENTS.CORE.md` → `@VOICE.md` — confirmed
  (step 3).
- No orphaned gateway or `craft-*` path anywhere in the tree — confirmed (step 2), plus a
  repo-wide grep post-edit found none outside `journal/` (historical, harmless) and the
  one surfaced-but-out-of-scope `static-analysis/SKILL.md` prose reference (step 5).
- Committed: `6719782`, not pushed.

## Blockers

None. Every step completed; three additional real findings (PACK-005 overlay dir,
init.lock version, GLOSSARY.local.md, `.workflow/` LAYOUT-001) turned up only in
verification and were fixed before the final commit, all within the target repo.
