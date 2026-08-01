# T001 — stewardship survey for v17 -> v37 adoption

Target: `/home/henning/workflows/stewardship`. Read-only survey. No files in the target
were modified; `template-sync.sh --check` performs a `fetch` against origin only.

## 1. `.template.lock`

```
template_version: 17
upstream: git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
derived: 2026-07-28
pinned: false
```
(`stewardship/.template.lock:1-4`). Not pinned — an `update` is permitted to act.

## 2. `template-sync.sh --check` (literal output, run from repo root)

```
From github-gss:GlobalShopSolutionsR-D/workflow-template
 + 6c943f9...c53f201 main       -> origin/main  (forced update)
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
template_version: 17
upstream:         git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
upstream version: 37
pinned:           false
status: behind (run 'update' to pull the managed set forward)
```
Note the cached upstream clone required a **forced update** (`+ 6c943f9...c53f201`),
i.e. history was rewritten upstream between the cache's last fetch and now.

## 3. `craft-*` surface — BLOCKER, this is not a simple rename

Between v17 and v37 the core did not just rename `craft-*` — it left the core
entirely (workflow-template `journal/2026-08-01-code-craft-published.md`,
`journal/2026-08-01-packs.md`). v37's `template-manifest.yaml` (repo root, upstream)
no longer lists `craft-tdd`/`craft-code-quality` at all; they only exist now as the
external `code-craft` pack (`pack.yaml` at `git@github.com:henningfutrell/pack-code-craft`),
installed via `template-sync.sh add`, never via `update`.

Consequence for stewardship: `update` (managed-set diff, "removed = old − new") will
**delete**, not rename:
- `.agents/skills/craft-tdd/**`
- `.agents/skills/craft-code-quality/**`
- `.claude/skills/craft-tdd/SKILL.md`
- `.claude/skills/craft-code-quality/SKILL.md`

(all four listed in stewardship's own `template-manifest.yaml:34-35,45-46` as
core-managed today). No `code-craft-*` replacement is installed automatically — that
requires a separate `template-sync.sh add` against the pack-code-craft repo, done by
hand, after `update`.

`.agents/craft/` (the unmanaged overlay slot) exists but is **empty** — no
`*.local.md` overlay files, so no overlay content is lost. It is not itself a managed
path, so `update` will leave the empty directory in place; it should become
`.agents/code-craft/` once the pack is added (empty dir → trivial, but not automatic).

Every `craft-*` path found:
```
.agents/craft/                                    (empty overlay dir)
.agents/skills/craft-tdd/SKILL.md
.agents/skills/craft-code-quality/  (SKILL.md, references/, assets/arch-tests/)
.claude/skills/craft-tdd/SKILL.md   (proxy stub)
.claude/skills/craft-code-quality/SKILL.md (proxy stub)
```

**Dangling references after deletion** (all unmanaged — `update` will not touch them,
so they go stale silently unless hand-fixed):
- `.agents/orchestrate/roster.local.yaml:21-25` — "`/craft-tdd` + `/craft-code-quality`
  are mandatory before production code"
- `.agents/orchestrate/orchestrate.local.md:85` — same mandate, same wording
- Four `.workflow/<slug>/{tasklist,roster}.md` sessions reference `/craft-tdd` /
  `/craft-code-quality` repeatedly, including **open, not-yet-executed tasks** that
  presume these skills exist (e.g. `.workflow/2026-07-30-fix-devexpress-masaba/tasklist.md:315,380`
  state the mandate for tasks still `[ ]`).
- Stewardship's own `AGENTS.CORE.md:115,149,154,156,161,217,219,222,224` mention
  `craft-*` — but this file **is** managed, so `update` overwrites it with upstream's
  v37 text and these mentions disappear on their own (not dangling, just changed
  under the reader).

Also note: v37 additionally **removes `workflow-gateway`** from the core manifest
(commit message: "remove the gateway"). Stewardship still has
`.agents/skills/workflow-gateway/` and `.claude/skills/workflow-gateway/SKILL.md`,
both listed in its own `template-manifest.yaml:23,39`, both referenced in
`AGENTS.CORE.md`'s baked-in skill list — `update` will delete these too, same
lossy-if-referenced pattern as craft-*.

## 4. AGENTS chain — BLOCKER, hand-edit required, `update` will NOT fix it

Current state:
- `stewardship/CLAUDE.md:4-5` imports **both** `@AGENTS.CORE.md` and `@AGENTS.md`
  (two flat imports). `CLAUDE.md` **is** managed (in manifest), so `update` **will**
  overwrite it to v37's shape automatically: `@AGENTS.md` only (per upstream
  `workflow-template/CLAUDE.md:4`, confirmed live).
- `stewardship/AGENTS.md` (unmanaged) has **no `@AGENTS.CORE.md` import at all** — it
  only *talks about* AGENTS.CORE.md in prose (`AGENTS.md:7-12`, "Core check" section).
  There is no literal `@AGENTS.CORE.md` line anywhere in the file.

v37's required chain is `CLAUDE.md` → `@AGENTS.md` → `@AGENTS.CORE.md` → `@VOICE.md`
(confirmed in upstream `workflow-template/AGENTS.md:5` — a bare `@AGENTS.CORE.md`
import line right after frontmatter, before its own "Core check" prose).

**The break**: once `update` rewrites `CLAUDE.md` to `@AGENTS.md`-only (which it does
automatically, since CLAUDE.md is managed), nothing in the repo imports
`AGENTS.CORE.md` any more — stewardship's `AGENTS.md` never picked up the actual
import statement, only the prose warning about it. Result: **AGENTS.CORE.md, and
transitively VOICE.md, stop loading in every session**, silently (the prose in
`AGENTS.md:7-9` even tells the reader to check the CLAUDE.md bridge for the fix, but
that bridge will no longer be where the import lives).

**Exact hand-edit needed** (since `AGENTS.md` is unmanaged, this is on the
derivation): insert a bare `@AGENTS.CORE.md` line into `stewardship/AGENTS.md`,
immediately after the frontmatter closing `---` (line 3) and before the "Core check"
heading (currently line 5) — mirroring upstream `AGENTS.md:5`. Nothing else in that
file needs to change; the existing "Core check" prose already describes the chain
correctly, it just isn't backed by an actual import today.

`VOICE.md` itself already exists in stewardship and is managed — no action needed
there once the import chain is fixed.

## 5. Legacy `.workflow/<slug>/` sessions — all four are in flight, none finished

No `workflows/` directory exists yet in stewardship (v37 introduces
`workflows/upstream-workflow-management/**` as a new managed core path — arrives
fresh on update, nothing to lose).

| session | total tasks | open (`[ ]`) | done (`[x]`) | state |
|---|---|---|---|---|
| `2026-07-30-agents-file-diet` | 10 | 7 | 3 | in flight |
| `2026-07-30-bulletproof-audit` | 13 | 8 | 5 | in flight |
| `2026-07-30-fix-devexpress-masaba` | 30 | 20 | 10 | in flight |
| `2026-07-30-ops-tools-83-event-log` | 17 | 9 | 8 | in flight |

All four are committed (per `AGENTS.CORE.md` session-state doctrine) and all have a
majority-to-large minority of open tasks — none look finished. Several open tasks in
`fix-devexpress-masaba` and `ops-tools-83-event-log` explicitly gate production-code
work on `/craft-tdd` + `/craft-code-quality` (see §3) — those tasks cannot be executed
as written the moment `update` deletes those skills, until the `code-craft` pack is
added by hand.

## 6. Working tree / branch / remote

- `git status --porcelain`: **empty** — clean.
- Branch: `main`.
- `origin`: `https://github.com/hfutrell-gss/workflow-stewardship.git` (fetch+push).
- One line if fine: working tree is clean, nothing else to say here.

## 7. Skill-name collisions with v37 core / code-craft pack

No literal on-disk name collisions today: stewardship's `.agents/skills/` and
`.claude/skills/` contain `craft-code-quality`, `craft-tdd`, `workflow-agents-sync`,
`workflow-bind`, `workflow-gateway`, `workflow-init`, `workflow-manage`,
`workflow-orchestrate`, `workflow-template-sync` — none named `workflow-check`
(new in v37) or any `code-craft-*` name yet. One line if fine: no direct collisions
exist right now; the risk is entirely in the deletion/rename gap described in §3, not
in a name clash.

## 8. Other findings that would make `update` lossy or surprising

- **The template mechanism itself changed shape**, not just its contents: v17's
  single-parent vendor model became a **core + packs** model (`packs.yaml`,
  `packs.lock`, `pack.yaml` — see upstream `journal/2026-08-01-packs.md`). Stewardship
  has no `packs.yaml`/`packs.lock` (confirmed absent) and its own
  `.agents/skills/workflow-template-sync/template-sync.sh` is still the pre-pack
  script — no `pack`, `add`, `remove`, or `PACK-*` logic in it at all. `update` will
  overwrite this script with the pack-aware v37 version (it's managed), which is
  necessary and fine, but the derivation should expect the *tool's own vocabulary and
  commands* to change underneath it, not just the payload.
- **Upstream cache required a forced update** (`+ 6c943f9...c53f201`) — history was
  rewritten upstream since this cache was last synced; worth a beat of suspicion
  before trusting a diff against that history for anything version-sensitive.
- **`workflow-check` is new** in v37 (`.agents/skills/workflow-check/**` now managed
  upstream) and **`GLOSSARY.md`** is newly managed at root — neither exists in
  stewardship today; both arrive additively, non-lossy.
- **`init.lock` (version 4) matches `.agents/skills/workflow-init/VERSION` (4)** — one
  line: this is fine, no re-init forced by version skew.
- `binds.yaml` has no references to `pack`/`gateway` — one line: nothing there needs
  attention from this migration.
