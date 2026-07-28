# AGENTS.CORE.md — the constitution

<!-- TEMPLATE-MANAGED: this file is owned by workflow-template-sync. In a derivation it is
     updated by `workflow-template-sync update`, never hand-edited. Edit it here, in
     workflow-template itself, to change what every derivation inherits. -->

## MANDATORY FIRST — verify initialization

Before any other work in any session under this repo:

1. Read `init.lock` at this repo root and `.claude/skills/workflow-init/VERSION`.
2. If `init.lock` is missing, or its `version:` differs from `VERSION` → **run
   `/workflow-init` now** (it installs/verifies the required tooling and writes
   `init.lock`).
3. If they match, proceed.

`init.lock` is per-machine state (gitignored). `VERSION` is bumped whenever the init
procedure changes; a stale lock means this machine hasn't run the latest init.

---

A **workflow repo** captures the techniques, tactics, procedures, and doctrine for a
whole **area of work** (stewardship, schema management, incident response, …). Code
repos are **substrate** — things a workflow operates *on*, not *in*. This repo — the
workflow-template — is the core every derived workflow repo shares: managed law, a
package of skills, and a live link back upstream.

## Canonical file format

**`AGENTS.md` (and any `.agents/` rule dirs) are the canonical sources — here and in
every bound repo.** `CLAUDE.md` files are at most a header with an import of the
sibling `AGENTS.md` (and, at repo root, of `AGENTS.CORE.md` too); they carry no content
of their own. `/workflow-agents-sync` enforces this invariant (creates missing bridges,
reports non-conforming files). Never author doctrine in a `CLAUDE.md`.

At this repo's root specifically, the law is split in two files, both canonical:
`AGENTS.CORE.md` (this file — the managed constitution) and `AGENTS.md` (this
derivation's own doctrine — entirely yours). The root `CLAUDE.md` bridges to both.

## Bind law

You work by **binding** repos to a workflow session, not by "being in a repo." Two
kinds of bind:

- **Standing binds** — repos *related to* this workflow, declared in `binds.yaml` with
  the relationship (`kind` + `why`): reference material, repos that tend to co-change
  with this workflow's work, repos this workflow stewards, upstream/downstream
  dependencies. Standing binds are a registry, not a session state — declaring one
  doesn't attach it to anything yet.
- **Session binds** — repos actually attached to the *current* session, via `/add-dir`
  once running or `claude --add-dir <path>` at launch. `/workflow-bind` automates
  binding a session to the standing binds marked `default: true`, plus any repos asked
  for on top.

Rules that apply to every bind, standing or session:

1. **On binding a target, read its `AGENTS.md` first**, and honor its acknowledgement
   protocol before operating in it. Workflow doctrine governs *how you work*; the
   target repo's own law governs *how to behave inside it*. Both apply — **repo law
   wins inside the repo's own boundaries.**
2. **Surface, don't suppress** — the universal principle, same as every repo: report
   drift, conflicts, and anomalies rather than silently resolving or hiding them.

## Journal discipline

Keep `journal/` — one dated file per run/decision (`YYYY-MM-DD-slug.md`), never a
single growing file. Atomic files merge cleanly across people and agents. Session binds
made for a given day belong in that day's journal entry (see `/workflow-bind`).

## Git discipline

**Always use native git — `/usr/bin/git` explicitly — for every git operation in this
repo and its derivations**, never a bare `git` that might resolve to a Windows binary.
A common WSL trap: a `git=...git.exe` alias in `~/.zshenv` (or `~/.zshrc`) shadows
native git on PATH. `/workflow-init`'s `--check` warns if such an alias is detected.

(Earlier revisions of this doctrine relied on a committed `.constitution.md` symlink
per workflow directory, with its own Windows-git symlink-corruption risk. That mechanism
is dead: a workflow is now one repo, not a directory inside a monorepo, so there is no
same-repo ancestor path to bridge with a symlink. Same-directory imports only.)

## Template link — how this repo relates to a derivation

This file (`AGENTS.CORE.md`) and the `workflow-*` skills under `.claude/skills/` are
**managed by the upstream template** (this repo, or wherever a derivation was cloned
from). The `workflow-*` skill namespace is reserved for the template; name
derivation-local skills anything else, or a future `update` may clobber them. A
derivation records the relationship in `.template.lock` at its root: `template_version`,
`upstream` (a local path **or a git URL** — `https://`, `git@...`, `ssh://`, `file://`;
a URL upstream is synced through a cached shallow clone under
`${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync/`, degrading to the stale cache
with a loud warning if offline rather than failing outright), `derived` (date), and
`pinned`.

- `pinned: false` (default) — `workflow-template-sync update` may copy forward changes
  to the managed set (see `template-manifest.yaml`) when the upstream's `VERSION` is
  ahead of the derivation's recorded `template_version`.
- `pinned: true` — the derivation has chosen to freeze its core. `update` (and
  `--check`) still **report** the available upstream version but **never touch
  anything** in a pinned derivation. Pinning is reversible by editing `.template.lock`.

**The covenant: the template facilitates, never constrains.** Everything outside the
managed set (`template-manifest.yaml` lists it exactly) belongs entirely to the
derivation — doctrine in `AGENTS.md`, `binds.yaml`, `playbooks/`, `journal/`, anything
else added later. A derivation may eject from the template relationship entirely at any
time (delete `.template.lock`) and is supported for the full lifetime of its project
either way, linked or not.

## Tiers (RBAC)

This repo's `AGENTS.md` declares `tier:` in frontmatter — the roles/credentials its
procedures presume (e.g. `dev`, `ops`, `admin`). Enforcement is real, not cosmetic:
- **Write** access is governed per-directory via CODEOWNERS.
- **Execution** is governed by the credentials the procedures require (cloud roles,
  kubeconfigs, VCS perms) — if you lack the tier's credentials, the procedures fail.
- Reads are open by design: doctrine is transparent. Truly secret doctrine (rare)
  belongs in a separate restricted repo, never here.

## Baked-in skills

- `/workflow-init` — install/verify required tooling (yq, Obsidian, codegraph); writes
  `init.lock`.
- `/workflow-agents-sync` — enforce the canonical-format invariant here and across
  standing-bind repos present on disk.
- `/workflow-template-sync` — the upstream link: `derive` a new workflow repo from a
  template copy, `update` a derivation's managed set from upstream, `--check` report
  drift.
- `/workflow-manage` — administer this workflow: add/remove/edit standing binds,
  clone-if-absent their repos, review the registry.
- `/workflow-bind` — bind a session: attach default standing binds (and any requested
  extras) via `/add-dir`, per the bind law above.
