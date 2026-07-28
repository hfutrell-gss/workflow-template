# Workflows — the constitution

## MANDATORY FIRST — verify initialization

Before any other work in any session under this repo:

1. Read `init.lock` at this repo root and `.claude/skills/workflows-init/VERSION`.
2. If `init.lock` is missing, or its `version:` differs from `VERSION` → **run `/workflows-init` now** (it installs/verifies the required tooling and writes `init.lock`).
3. If they match, proceed.

`init.lock` is per-machine state (gitignored). `VERSION` is bumped whenever the init
procedure changes; a stale lock means this machine hasn't run the latest init.

---

This monorepo is the org's methodology: every **workflow** is a directory capturing the
techniques, tactics, procedures, and doctrine for a whole **area of work** (stewardship,
schema management, incident response, …). Code repos are substrate — things workflows
operate *on*, not *in*. A developer clones this one repo and can do anything anywhere.

## Canonical file format

**`AGENTS.md` files (and `.agents/` rule dirs) are the canonical sources — here and in
every substrate repo.** `CLAUDE.md` files are at most a header with an import of their
sibling `AGENTS.md`; they carry no content of their own. `/workflows-agents-sync` manages
this invariant (creates missing bridges, reports non-conforming files). Never author
doctrine in a `CLAUDE.md`.

## Checkout model

You never work "in a repo"; you check out a workflow and **bind targets** at session time:

```sh
wf <workflow> [target-repo ...]     # bin/wf — cd into the workflow, claude --add-dir each target
```

- The workflow directory is the session cwd: this constitution + the area's `AGENTS.md`
  doctrine + the baked-in `.claude/skills/` govern the session. Each workflow's
  `CLAUDE.md` reaches this constitution via a same-directory `.constitution.md` symlink
  to this file, imported as `@.constitution.md` — a direct `@../AGENTS.md` import does
  not expand in headless sessions, so the symlink is what actually delivers this file.
  `/workflows-agents-sync` maintains the symlink; don't hand-edit it.
- Targets are any repos, resolved (and cloned if absent) via `manifest.yaml`.
- A workflow is target-agnostic: same doctrine, different substrate each checkout.

## Git discipline

This repo contains committed symlinks (`.constitution.md` in each workflow dir). **Always
use native git — `/usr/bin/git` explicitly — for every git operation here**, never a bare
`git` that might resolve to a Windows binary. A common WSL trap: a `git=...git.exe` alias
in `~/.zshenv` (or `~/.zshrc`) shadows native git on PATH. Symptoms if you're hit by it:
a phantom `typechange` on `.constitution.md` in `git status`/`git diff`, or `git diff`
failing outright with `"Function not implemented"`. **Never run
`git checkout -- .constitution.md`-style commands through Windows git** — it silently
converts the symlink to a plain file with no error, corrupting the checkout.
`/workflows-init`'s `--check` warns if such an alias is detected (see `init.sh`).

## Binding law (applies to every workflow)

1. **On binding a target, read its `AGENTS.md` before operating in it**, and honor its
   acknowledgement protocol. Workflow doctrine governs *how you work*; repo law governs
   *how to behave inside that repo*. Both apply; repo law wins inside the repo's boundaries.
2. Cross-repo/system-level implications → read `architecture/AGENTS.md` (the source of
   record) and follow its cataloguing mandate.
3. **Surface, don't suppress** — the universal principle, same as every repo.

## Journal discipline

Each workflow keeps `journal/` — one dated file per run/decision (`YYYY-MM-DD-slug.md`),
never a single growing file (atomic files merge cleanly across people and agents).

## Tiers (RBAC)

Each workflow's `AGENTS.md` declares `tier:` in frontmatter — the roles/credentials its
procedures presume (e.g. `dev`, `ops`, `admin`). Enforcement is real, not cosmetic:
- **Write** access is governed per-directory via CODEOWNERS.
- **Execution** is governed by the credentials the procedures require (AWS roles,
  kubeconfigs, GitHub perms) — if you lack the tier's credentials, the procedures fail.
- Reads are open by design: doctrine is transparent. Truly secret doctrine (rare) belongs
  in a separate restricted repo, never here.

## Baked-in skills

- `/workflows-init` — install/verify required tooling (yq, Obsidian, codegraph); writes `init.lock`.
- `/workflows-agents-sync` — enforce the canonical-format invariant here and across substrate repos.

## Adding a workflow

Copy `_template/` to a new top-level directory, write its `AGENTS.md` doctrine, add it to
the index in `README.md`. New top-level directories mean new areas of work — name them by
the work, not the tool.
