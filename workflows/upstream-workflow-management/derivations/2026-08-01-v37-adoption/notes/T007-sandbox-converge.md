# T007 — sandbox converge (template_version 13 → 37)

Target: `/home/henning/workflows/sandbox`. All git commands run with `/usr/bin/git`.
Orchestrator overruled T003's re-derive recommendation: bootstrap the v37
`template-sync.sh` before running `update`, retiring both objections (no packs
support, no deletion-of-dropped-paths logic) before the script is ever invoked.

## 1. Bootstrap

```
cp -r /home/henning/workflows/workflow-template/.agents/skills/workflow-template-sync/. \
      /home/henning/workflows/sandbox/.agents/skills/workflow-template-sync/
```

Before copy, sandbox's copy: `SKILL.md`, `template-sync.sh` (11242 bytes) — no
`pack-scan.sh`, no `add` subcommand. After copy:

```
-rwxr-xr-x 1 henning henning  6621 Aug  1 16:39 pack-scan.sh
-rw-r--r-- 1 henning henning 11634 Aug  1 16:39 SKILL.md
-rwxr-xr-x 1 henning henning 35390 Aug  1 16:39 template-sync.sh
```

Executability confirmed: `template-sync.sh: executable`, `pack-scan.sh: executable`.
`.template.lock` still read `template_version: 13` at this point (manifest not yet
touched) — confirms the bootstrap happened strictly before `update`.

Pre-update inventory:
```
./.agents/skills/workflow-gateway
./.claude/skills/workflow-gateway
```
(both present, as the survey found). `craft-*` search: empty (nothing to lose, per
survey §3).

## 2. `update` — literal output

```
$ bash .agents/skills/workflow-template-sync/template-sync.sh update
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
workflow-core: 13 -> 37
  removed .agents/skills/workflow-gateway/**
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
EXIT CODE: 0
```

Dropped-paths reporting confirmed literally: `removed .agents/skills/workflow-gateway/**`
and `removed .claude/skills/workflow-gateway/SKILL.md`.

Post-update verification:
- `find . -iname '*workflow-gateway*' -not -path './.git/*'` → empty. Both paths gone;
  no manual removal needed.
- `find . -iname '*craft*' -not -path './.git/*'` → empty. Confirms survey §3: no
  craft-shaped content existed here, nothing to lose in the rename.
- `.template.lock` → `template_version: 37` (upstream/derived/pinned unchanged).

## 3. AGENTS chain — hand fix

`AGENTS.md` is unmanaged (absent from `template-manifest.yaml` in both v13 and v37);
`update` cannot touch it, confirmed by diff showing it untouched by step 2. Added a
bare `@AGENTS.CORE.md` line immediately after the frontmatter, per reference shape at
`/home/henning/workflows/workflow-template/AGENTS.md`:

```diff
 tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
 ---
 
+@AGENTS.CORE.md
+
 ## Core check
```

Resulting chain, confirmed:
- `CLAUDE.md` → `@AGENTS.md` only (synced by `update` to v37 shape).
- `AGENTS.md` → `@AGENTS.CORE.md` (this hand-fix).
- `AGENTS.CORE.md` → `@VOICE.md` (synced by `update`, v37 shape ships this import).

This repo's own ~44 lines of doctrine (Area of work / Responsibilities / Conditions /
Procedures / Typical checkouts) preserved verbatim below the new import line — confirmed
by reading the full file post-edit. `binds.yaml` diff: empty (`git diff --stat
binds.yaml` produced no output) — the one standing bind (`docs`, kind `reference`) is
untouched.

## 4. code-craft pack — deliberately not installed

No `craft-*` path or reference exists anywhere in this derivation (search in step 2,
repeated in step 5). Per `AGENTS.CORE.md`'s Composition section, "a repo with no packs
is complete, not degraded." Installing engineering doctrine (`code-craft`) this
repo never asked for and has no substrate to apply it to would be exactly the guess
packs exist to avoid. This is a deliberate decision, not an omission.

## 5. Dangling-reference sweep

Searched the whole repo for `workflow-gateway`, `craft-`, `.workflow/`, `playbooks/`.

- `craft-` and `.workflow/` hits are all inside managed files synced fresh from
  upstream (`AGENTS.CORE.md`, `.agents/skills/workflow-*`, `GLOSSARY.md`) — expected
  upstream content, not drift.
- `playbooks/` hits are all in `README.md`, describing the (still-present, still
  accurate) `playbooks/` directory — not dangling.
- `workflow-gateway` hit: one, in unmanaged `README.md` line 69 — a skills-table row
  documenting the now-removed gateway skill. Genuinely dangling (unmanaged file,
  never touched by `update`). Fixed by deleting the row:

```diff
 | `/workflow-bind` | Bind a session: attach default standing binds (and anything else asked for) via `/add-dir` |
-| `/workflow-gateway` | Manage the local opencodex model gateway (start/stop/status) and print the strictly opt-in, per-session `ANTHROPIC_BASE_URL` override |
```

No doctrine invented; only the stale row was dropped.

## 6. Verify — literal output

```
$ bash .agents/skills/workflow-template-sync/template-sync.sh --check
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
workflow-core: up to date (37)
status: up to date
EXIT: 0
```

```
$ bash .agents/skills/workflow-template-sync/template-sync.sh --audit
EXIT: 0
```
(no findings — empty output, clean exit)

```
$ bash .agents/skills/workflow-template-sync/template-sync.sh list
PACK                       VERSION   UPSTREAM
workflow-core (core)       37        git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
EXIT: 0
```

```
$ bash .agents/skills/workflow-check/check.sh
```
First run (before `init.sh`) reported the pre-existing per-machine `init.lock` at
version 4 vs. required 6 (both plain per-machine drift, not repo drift) plus the
pre-existing WSL git-alias warning; exit 2. Per `AGENTS.CORE.md`'s "MANDATORY FIRST —
verify initialization" mandate, ran `.agents/skills/workflow-init/init.sh` (idempotent,
touches only the gitignored `init.lock` at this repo's root — no other repo touched):

```
$ bash .agents/skills/workflow-init/init.sh
WARNING: 'git' is aliased to a Windows binary at /home/henning/.zshenv:39 — ...
init complete — wrote /home/henning/workflows/sandbox/init.lock (version 6)
EXIT: 0
```

Re-run of `check.sh` after that, literal output:
```
workflow-check — organizational constraints (registry: .agents/skills/workflow-check/references/constraints.md)

TOOL       ok
AGENTS     ok
LAYOUT     ok
PACK       ok
TEMPLATE   ok

all constraints met
EXIT: 0
```

```
$ bash .agents/skills/workflow-orchestrate/orchestrate.sh check
layout     all conforming
EXIT: 0
```
(No sessions exist — expected for a scratch repo with no orchestration runs yet. Per
task instruction, this is not a failure.)

```
$ bash .agents/skills/workflow-agents-sync/agents-sync.sh
agents-sync: all conforming
EXIT: 0
```

## 7. Commit

```
$ /usr/bin/git add -A
$ /usr/bin/git commit -m "chore: converge template core from v13 to v37" ...
[main 235ce48] chore: converge template core from v13 to v37
 45 files changed, 4007 insertions(+), 960 deletions(-)
$ /usr/bin/git status
On branch main
nothing to commit, working tree clean
```

**Commit SHA: `235ce4805dce00a4cecb1d63b12782e634aeadeb`**

`init.lock` is gitignored (per-machine state) — confirmed not staged, not part of the
commit.

## Acceptance test — verified

| Check | Result |
|---|---|
| `.template.lock` reads 37 | yes |
| `--check` no drift | yes — "up to date (37)" |
| `check.sh` clean | yes — "all constraints met", exit 0 |
| `orchestrate.sh check` clean | yes — "layout all conforming", exit 0 |
| `agents-sync.sh` clean | yes — "all conforming", exit 0 |
| AGENTS chain correct | yes — `CLAUDE.md → @AGENTS.md → @AGENTS.CORE.md → @VOICE.md` |
| No orphaned gateway path | yes — both paths removed by `update` itself, none survived |
| Own doctrine + binds.yaml intact | yes — `AGENTS.md`'s 44 lines preserved verbatim below the new import; `binds.yaml` diff empty |
| Committed | yes — `235ce4805dce00a4cecb1d63b12782e634aeadeb` |
| No push | correct — no remote configured (unchanged from survey) |

No blockers.
