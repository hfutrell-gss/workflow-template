# T002 — workflow-monolith v19 → v37 adoption survey (READ-ONLY)

Target: `/home/henning/workflows/workflow-monolith`. No files changed in target repo.
All git commands run with `/usr/bin/git`.

## 1. `.template.lock`

```
template_version: 19
upstream: git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
derived: 2026-07-30
pinned: false
```
(`/home/henning/workflows/workflow-monolith/.template.lock`)

## 2. `template-sync.sh --check` (literal output, exit 1)

```
HEAD is now at c53f201 core: v37 — remove the gateway, stop restating rules, add PACK-005 and SUBSTRATE-001
template_version: 19
upstream:         git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
upstream version: 37
pinned:           false
status: behind (run 'update' to pull the managed set forward)
```

## 3. craft-* survey — bigger break than "rename to code-craft"

Paths present, all listed as `managed` in the monolith's own
`template-manifest.yaml:29-30,40-41` (v19 manifest):
- `.agents/skills/craft-tdd/**`, `.agents/skills/craft-code-quality/**`
- `.claude/skills/craft-tdd/SKILL.md`, `.claude/skills/craft-code-quality/SKILL.md`

References: `AGENTS.md:76-78,81`; `README.md:64-65,84-86,88` (unmanaged, hand-authored);
`AGENTS.CORE.md:254,256` (managed — replaced wholesale by update); `journal/2026-07-30-derived-and-ndepend.md` (historical, harmless).

**v37 does not rename craft-* → code-craft-*.** Upstream's current
`template-manifest.yaml` (v36-stamped, shipped in v37) has NO craft-tdd/craft-code-quality
entries at all — confirmed by diff against upstream `/home/henning/workflows/workflow-template/template-manifest.yaml`.
Per `AGENTS.CORE.md`'s own "Composition" section (upstream), craft became the **optional
`code-craft` pack**, a separate repo installed via `template-sync.sh add <url>`, shipping
`/code-craft-tdd`, `/code-craft-quality`, plus two new skills
(`/code-craft-event-naming`, `/code-craft-ubiquitous-language`). `update` alone:
- **Deletes** all 4 craft-tdd/craft-code-quality paths above (dropped from manifest = deleted, per the manifest's own deletion rule).
- Does **not** create `.agents/code-craft/`, does not install the pack, does not touch AGENTS.md/README.md.
- Also silently deletes `.agents/skills/workflow-gateway/**` + `.claude/skills/workflow-gateway/SKILL.md` (present on disk, confirmed) — dropped from the v37 manifest too (commit message: "remove the gateway"). Referenced at `AGENTS.CORE.md:239` (managed, self-heals) and `README.md:84` (unmanaged — dangles).
- Adds new managed paths not yet present: `.agents/skills/workflow-check/**`, `.claude/skills/workflow-check/SKILL.md`, `GLOSSARY.md`, `workflows/upstream-workflow-management/**` (confirmed absent on target).

**Dangling after a bare `update`:** `AGENTS.md:76-78,81` (`/craft-tdd`, `/craft-code-quality`, `.agents/craft/tdd.local.md`, `.agents/craft/code-quality.local.md` — skills gone, and `.agents/craft/` never existed locally anyway — `ls` confirms no such directory); `README.md:64-65,84-86,88` (craft-* table rows + gateway row + `.agents/craft/` overlay mention). None of this self-heals; both files are unmanaged.

## 4. AGENTS chain

Current (monolith): `CLAUDE.md` → `@AGENTS.CORE.md` + `@AGENTS.md` (two imports, root-special-case under the *old* doctrine). `AGENTS.md` itself has **zero** `@` imports (`grep -n "^@" AGENTS.md` → no match) — it does not import `AGENTS.CORE.md` or `VOICE.md` itself; the old chain relied on CLAUDE.md importing both directly.

v37 requirement (confirmed in upstream `AGENTS.CORE.md`, "Canonical file format"): `CLAUDE.md` → `@AGENTS.md` **only**; `AGENTS.md` → `@AGENTS.CORE.md` → `@VOICE.md`.

- `CLAUDE.md` **is** managed (in manifest) → `update` will rewrite it to the single-import form automatically. No action needed there.
- `AGENTS.md` is **unmanaged** → `update` will not touch it. It has no `@AGENTS.CORE.md` line today. **Required hand-edit:** add `@AGENTS.CORE.md` as its own line near the top (upstream skeleton places it at `AGENTS.md:5`, right after frontmatter, before "## Core check"). Without this edit, post-update the constitution (incl. the MANDATORY-FIRST init check) and `VOICE.md` stop loading entirely — CLAUDE.md only reaches AGENTS.md, and nothing then pulls in AGENTS.CORE.md/VOICE.md.

## 5. Uncommitted change — README.md

`/usr/bin/git status`: `On branch main … Changes not staged for commit: modified: README.md`. `README.md` is **unmanaged** (not in `template-manifest.yaml`), so `update` never touches it and cannot conflict with this diff mechanically. Full diff captured (114 lines changed) — it's a full rewrite of the template-derived boilerplate README into monolith-specific content (own upstream-link section, area-of-work table, static-analysis section, layout/skills tables) — already drafted with the *old* (pre-v37) craft/gateway terminology baked in, i.e. it already needs the same craft-*/gateway edits as item 3 once v37 lands. Not required to be committed or stashed before `update` runs (no path overlap with the managed set), but it should be committed (or at least reconciled) before or immediately after `update`, since it currently documents things (`/craft-tdd`, `/workflow-gateway`, `.agents/craft/`) that a v37 `update` deletes — leaving a dirty tree with self-contradicting docs is the real risk, not a git conflict.

## 6. Legacy session state / `workflows/`

- `.workflow/` exists but is **empty** (`find .workflow -type f` → no output; only the bare directory). No session data to migrate.
- `workflows/` does **not** exist yet (`find`: "No such file or directory"). Upstream v37 ships a managed `workflows/upstream-workflow-management/**` — `update` will create `workflows/` for the first time on this repo.
- Per upstream `AGENTS.CORE.md`: "Sessions predating this layout resolve for one more version at `.workflow/<slug>/`" — worth flagging that the grace period is finite; being empty now, this repo has nothing at stake here, but the directory itself is stale scaffolding.

## 7. Local skill name collisions

`.agents/skills/` and `.claude/skills/` both contain (mirrored): `craft-code-quality`, `craft-tdd`, `static-analysis`, `workflow-agents-sync`, `workflow-bind`, `workflow-gateway`, `workflow-init`, `workflow-manage`, `workflow-orchestrate`, `workflow-template-sync`.

- No collision with v37 core `workflow-*` names (all local `workflow-*` skills ARE the core skills, correctly named/managed — not derivation-local extras).
- No collision with `code-craft-*` (nothing here is named `code-craft-*` yet).
- `static-analysis` is this workflow's own bespoke skill, correctly named outside both reserved prefixes (`workflow-*`, `craft-*`/`code-craft-*`) — safe.
- The real risk isn't a name collision, it's the craft-tdd/craft-code-quality **deletion** (item 3) — those names go away, not clash.

## 8. Repo completion state — do not read `update` as "finishing" this repo

- `AGENTS.md` (`/home/henning/workflows/workflow-monolith/AGENTS.md:19`): "**Unfinished.** The Responsibilities, Conditions, and Procedures below are a starting frame, not settled doctrine, and `binds.yaml` is still empty." Still true: `Responsibilities` line 31 and `Conditions` line 44 both still literal placeholder angle-bracket text (`<what else this workflow is accountable for...>`, `<the remaining invariants...>`); `Procedures` (line 47) is `<no playbooks yet>`.
- `binds.yaml`: `standing: []` — confirmed empty, only commented-out example entries.
- `.agents/craft/` overlay slot referenced by `AGENTS.md:78` was never created (`ls`: no such directory) — even pre-v37 this repo hadn't filled in its craft overrides.
- Only settled part, per the repo's own doctrine: the static-analysis/NDepend capability.
- A v37 `update` only touches the managed set; it does not and cannot fill any of the above. Post-update this repo is exactly as unfinished, plus newly broken craft-*/gateway references.

---

Notes file: `/home/henning/workflows/workflow-template/workflows/upstream-workflow-management/derivations/2026-08-01-v37-adoption/notes/T002-monolith.md`
