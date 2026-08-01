# T003 — sandbox (template_version 13 → upstream v37)

Target: `/home/henning/workflows/sandbox`. Read-only survey; no files in the target
touched. All git commands run with `/usr/bin/git`.

## 1. `.template.lock` contents

`/home/henning/workflows/sandbox/.template.lock`:
```
template_version: 13
upstream: git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
derived: 2026-07-28
pinned: false
```

## 2. `template-sync.sh --check` — literal output

Run from repo root (`cd /home/henning/workflows/sandbox && bash
.agents/skills/workflow-template-sync/template-sync.sh --check`):

```
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
template_version: 13
upstream:         git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
upstream version: 37
pinned:           false
status: behind (run 'update' to pull the managed set forward)
```
Exit code: 1 (expected — "behind" is a non-zero-but-informational exit per the script's
own `cmd_check`, not a crash).

**The v13 script does NOT understand the v37 packs mechanism, and this matters for how
`update` must be driven.** Evidence:
- `sandbox/.agents/skills/workflow-template-sync/template-sync.sh` (the v13 copy, 254
  lines) has exactly three subcommands: `derive`, `update`, `--check` (script tail,
  case statement). No `add` subcommand exists.
- Upstream's v37 copy (`/home/henning/workflows/workflow-template/.agents/skills/workflow-template-sync/`)
  ships a second script, `pack-scan.sh`, plus `packs.yaml`/`packs.lock` handling
  (`declared_packs`, `locked_packs`, pack install/remove helpers) — none of this exists
  in the v13 script at all.
- `copy_managed_paths()` in the v13 script (lines 132-151) **only copies paths listed in
  the NEW manifest it's given — it never diffs against the OLD manifest to delete paths
  that were dropped.** It has no concept of "this path used to be managed, now isn't,
  remove it." This is a real defect for this jump: v37's core manifest drops
  `workflow-gateway` entirely (see §3) and the v13 script would leave it as
  orphaned/undeleted dead weight after `update`, silently.
- Manifest shape is otherwise compatible (both v13 and v37 `template-manifest.yaml` use
  a flat `managed:` list, so `yq -r '.managed[]'` still parses v37's file without
  erroring) — the script won't crash, it will just silently under-clean.

## 3. `craft-*` paths

**None exist.** `find /home/henking/workflows/sandbox -iname '*craft*' -not -path
'*/.git/*'` returned nothing — no `craft-tdd`, no `craft-code-quality`, no
`.agents/craft/` directory anywhere in this derivation. Confirmed also: `craft-*` is
absent from sandbox's own `template-manifest.yaml` managed list (13 entries, none
craft-related) — it was never pulled into this derivation in the first place.
**Conclusion: the craft→code-craft pack rename is a non-issue for this derivation** —
nothing to delete, nothing to dangle, nothing to rename.

## 4. AGENTS chain

`sandbox/CLAUDE.md` (4 lines, in full):
```
# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.CORE.md + AGENTS.md are canonical -->

@AGENTS.CORE.md
@AGENTS.md
```
This is the **v13 shape**: `CLAUDE.md` imports both `@AGENTS.CORE.md` and `@AGENTS.md`
directly.

Upstream v37 `CLAUDE.md` (`/home/henning/workflows/workflow-template/CLAUDE.md`, in
full):
```
# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.md is canonical -->

@AGENTS.md
```
v37 requires `CLAUDE.md -> @AGENTS.md` ONLY, with `AGENTS.md -> @AGENTS.CORE.md ->
@VOICE.md` carrying the rest of the chain.

`sandbox/AGENTS.md:1-11` does NOT contain an `@AGENTS.CORE.md` or `@VOICE.md` import
line — line 10 only *mentions* `AGENTS.CORE.md` in prose ("This session must ALSO have
loaded `AGENTS.CORE.md`... run `/workflow-agents-sync`... `AGENTS.CORE.md` is picked up
the same way house `AGENTS*.md` discovery already covers this file"). It relies on
Claude Code's own multi-`AGENTS*.md` discovery, not an explicit `@` import.

**Blocker: `CLAUDE.md` is template-managed (listed in `template-manifest.yaml`'s
`managed:`), so `update` WILL overwrite it to the v37 `@AGENTS.md`-only form. But
`AGENTS.md` is NOT in the managed list (confirmed: absent from both sandbox's v13 and
upstream's v37 `template-manifest.yaml`) — it is unmanaged, derivation-owned, and
`update` will never touch it.** Net effect of a mechanical `update`: `CLAUDE.md` drops
its direct `@AGENTS.CORE.md` import, and `AGENTS.md` is never rewritten to add one — the
constitution-loading chain breaks post-update unless someone hand-edits `AGENTS.md` to
add `@AGENTS.CORE.md` (which itself would need to import `@VOICE.md`, per v37's
required shape — also unmanaged and not automatic). This is a required manual step for
any 13→37 update path, not something `update` resolves on its own.

## 5. Legacy `.workflow/<slug>/` sessions and `workflows/`

- No `.workflow/` directory exists anywhere under sandbox (`find ... -iname
  '.workflow*'` → nothing).
- No `workflows/` directory exists at all (`find sandbox/workflows` → "No such file or
  directory"). v37's managed set adds `workflows/upstream-workflow-management/SKILL.md`
  and `references/**` under this path — an `update` would create it fresh, no
  collision, no prior content to preserve or lose.

## 6. Working tree, branch, remote

- `git status`: **clean** — "On branch main, nothing to commit, working tree clean."
- `git branch -vv`: `* main 8068cf7 chore: point template upstream at
  GlobalShopSolutionsR-D/workflow-template` (tip of 21 commits total, `git log
  --oneline` head to `d9fb33c feat: constitution, substrate manifest, and repo
  scaffolding`).
- `git remote -v`: **empty — no remote configured at all.**
- `git ls-remote origin`: `fatal: 'origin' does not appear to be a git repository` (exit
  128) — confirms no remote, consistent with `sandbox/AGENTS.md`'s own doctrine
  ("Local-only — this derivation has no `origin` remote of its own... never pushed
  anywhere, only ever exercised on this machine").

## 7. Viability verdict: update vs. re-derive

### What this derivation actually owns (its real content)

| Path | Size | Nature |
|---|---|---|
| `AGENTS.md` | 2074 bytes / 44 lines | Doctrine — describes sandbox's role as a disposable second workflow for testing derive/binds/console E2E. Thin but real; references a "no origin remote" convention. |
| `binds.yaml` | 1744 bytes / 33 lines | One real standing bind: `docs` repo (`git@github-gss:globalshopsolutions-internaltools/docs.git`), `kind: reference`, `default: true` — used for console E2E testing. |
| `playbooks/README.md` | 344 bytes / 4 lines | Boilerplate stub only — "no dedicated playbooks yet" per AGENTS.md. Zero real procedure content. |
| `journal/` | `.gitkeep` only, 0 bytes | Empty — no journal entries have ever been written. |
| `README.md` | 6042 bytes | Unmanaged, derivation-local — not surveyed in depth here but present; likely template-derived boilerplate rather than sandbox-specific narrative (not in any managed list either way). |
| `workspace/docs/` | gitignored, per-machine | The cloned `docs` substrate — reproducible from `binds.yaml`, not itself precious. |

Everything else present (`AGENTS.CORE.md`, `VOICE.md`, `CLAUDE.md`,
`template-manifest.yaml`, all six `.agents/skills/workflow-*` dirs and their
`.claude/skills/` proxy stubs, `init.lock`) is **stock template scaffolding**,
byte-for-byte reproducible by a fresh `derive` from v37 plus re-adding the one real
`binds.yaml` entry and the 44-line `AGENTS.md`.

### Verdict: **re-derive fresh from v37, don't mechanically `update`.**

Evidence weighing:
- **Total derivation-owned, non-boilerplate content is trivial**: ~44 lines of doctrine
  + one binds.yaml entry + an empty journal + a stub playbooks README. Nothing here
  represents work that's expensive to recreate — the repo's own doctrine (§ Area of
  work) explicitly says it exists to be "disposable" and "never used for real
  stewardship... work."
- **The update path is not clean even mechanically**: the v13 `template-sync.sh` has no
  concept of packs (no `add` subcommand at all, so it can't even ask for the
  `code-craft` pack that superseded craft-*, though that's moot here since craft-* was
  never present) and, more seriously, `copy_managed_paths()` never deletes paths dropped
  from the manifest — so a mechanical `update` would leave the removed
  `workflow-gateway` skill (both `.agents/skills/workflow-gateway/` and
  `.claude/skills/workflow-gateway/SKILL.md`, confirmed present) as **orphaned dead code
  after update**, requiring a manual cleanup step regardless.
- **The AGENTS chain requires a manual, non-mechanical fix no matter which path is
  taken**: since `AGENTS.md` is unmanaged, `update`ing `CLAUDE.md` alone breaks the
  constitution-load chain (§4) — this has to be hand-fixed whether via `update` or via
  fresh `derive` + doctrine transplant.
- **No remote, no collaborators, no in-flight work to preserve**: clean working tree,
  no origin, no branches to reconcile, no journal history, no playbooks in progress.
  There is no cost to discarding the current checkout other than retyping ~80 lines of
  real content.
- Given the update mechanism itself is the "furthest behind" and demonstrably
  under-equipped for this jump (no packs support, no deletion-of-dropped-paths logic),
  and the actual unique content is small and fully enumerable, a fresh `derive` from
  v37 (carrying forward the `docs` binds.yaml entry and the AGENTS.md doctrine
  paragraph by hand) is materially lower-risk than debugging a 13→37 `update` run and
  then manually patching the gateway-orphan and AGENTS-chain issues on top of it.

No changes were made to the sandbox repo. This is a recommendation only, per the task's
read-only constraint.
