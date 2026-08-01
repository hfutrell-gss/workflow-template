# AGENTS.CORE.md — the constitution

<!-- TEMPLATE-MANAGED: this file is owned by workflow-template-sync. In a derivation it is
     updated by `workflow-template-sync update`, never hand-edited. Edit it here, in
     workflow-template itself, to change what every derivation inherits. -->

## MANDATORY FIRST — verify initialization

Before any other work in any session under this repo: read `init.lock` at this repo
root and `.agents/skills/workflow-init/VERSION`. If `init.lock` is missing, or its
`version:` differs → **run `/workflow-init` now** (installs/verifies required tooling,
writes `init.lock`). If they match, proceed.

`init.lock` is per-machine state (gitignored); `VERSION` bumps whenever init changes —
a stale lock means this machine hasn't run the latest init.

---

A **workflow repo** captures the techniques, tactics, procedures, and doctrine for a
whole **area of work** (stewardship, schema management, incident response, …). Code
repos are **substrate** — operated *on*, not *in*. This repo is the core every derived
workflow repo shares: managed law, a package of skills, a live link upstream. Read "The
shapes" below before adding anything.

## Canonical file format

**`AGENTS.md` is canonical, here and in every bound repo.** `CLAUDE.md` is at most a
header importing the sibling `AGENTS.md` (root also imports `AGENTS.CORE.md`) — no
content of its own; `/workflow-agents-sync` enforces this. **The proxy rule: `.claude`
is a proxy for `.agents`.** Canonical content — `AGENTS.md`, `.agents/skills`
bodies/scripts — lives under `.agents`; `.claude` keeps only what tooling mechanically
requires (a skill's doctrine is `.agents/skills/<name>/SKILL.md`,
`.claude/skills/<name>/SKILL.md` a thin proxy stub). Nothing executable under
`.claude`. At root, law splits across `AGENTS.CORE.md` (this file) and `AGENTS.md`
(derivation's own doctrine); `CLAUDE.md` bridges to both.

## Bind law

You work by **binding** repos to a session, not by "being in a repo." **Standing
binds** are repos related to this workflow, declared in `binds.yaml` (`kind` + `why`)
— a registry, not a session state. **Session binds** are repos attached to *this*
session, via `/add-dir` or `claude --add-dir`; `/workflow-bind` attaches `default:
true` standing binds plus anything asked for.

Every bind: **read the target's `AGENTS.md` first**, honor its acknowledgement
protocol — **repo law wins inside its own boundaries.** And **surface, don't
suppress** — report drift, conflicts, anomalies; never resolve or hide them silently.
Universal, true everywhere below.

## The workspace

Every workflow owns `workspace/` — a per-machine, gitignored area where standing
binds get cloned; inside `workspace/<repo>`, its own git and `AGENTS.md` apply.
Resolution detail: `/workflow-manage`.

## The shapes

**"Workflow" carries four senses**, kept separate after conflating them once cost real
confusion: **a workflow repo** (the container); **`workflow-*`/`craft-*`** (an
*ownership* marker only); **a workflow** (sense 3, primary — a reusable way of
working, e.g. `refactor`); **a run** (one application to one target — state,
disposable once harvested).

Six kinds of thing live here; one home each — the wrong home makes it unfindable:

| Kind | What it is | Home | Retrieved by |
|------|-----------|------|--------------|
| **Law** | the managed constitution | `AGENTS.CORE.md` | always loaded |
| **Doctrine** | this workflow's standing judgment | `AGENTS.md` | always loaded |
| **Procedure** | a reusable way of working (sense 3) | a derivation-local skill | **lazily, by the Skill tool** |
| **Knowledge** | what is true, and why | substrate repo's docs, or `knowledge/` if cross-app | index line, then on demand |
| **Run** | a task list and working notes | `workflows/<workflow>/<target>/` | only the run that owns it |
| **Narrative** | what happened on a given day | `journal/` | humans, archaeology |

**Procedures are skills; derivation-local skills are expected** — frontmatter
description, thin body, `references/` for detail, named outside `workflow-*`/`craft-*`
(`/workflow-manage` scaffolds one). Not a categorical-rule violation: that rule covers
template-concept tooling, not a workflow authoring its own procedures. Prose is not a
lesser procedure — it needs lazy retrieval too.

**Harvest law:** a run is done only when its durable output has **left** the run
directory — a stabilized way → a procedure skill; substrate understanding → that
repo's own docs; what merely happened → the journal. Then it closes and is deleted,
not archived — `git log` is the archive.

## Journal, session state, git

- **Journal** — one dated file per run/decision (`journal/YYYY-MM-DD-slug.md`), never
  one growing file. A day's session binds belong in that day's entry.
- **Session state** — a run keeps state at `workflows/<workflow>/<target>/`,
  **committed** (unlike `workspace/`) so it survives compaction or a machine change.
  `workflows/<workflow>/` is the DURABLE procedure; `<target>/` is disposable INSTANCE
  state, gated shut by harvest before the run may close. Runs predating this layout
  resolve for one more version at `.workflow/<slug>/`. See `/workflow-orchestrate`.
- **Git** — **always native git, `/usr/bin/git` explicitly**, never a bare `git` that
  may resolve to a Windows binary (a WSL `git=...git.exe` alias is the common trap).
  `/workflow-init --check` warns if detected.

## Template link, the categorical rule, and the covenant

`AGENTS.CORE.md` and `.agents/skills/` are **managed by the upstream template**,
tracked in `.template.lock` (`pinned: true` freezes updates). Full mechanics:
`/workflow-template-sync`. **Covenant:** the template facilitates, never constrains —
everything outside the managed set is entirely the derivation's, ejectable any time
(delete `.template.lock`). **Categorical rule:** the template owns every operation on
its shapes, as managed skills; a derivation contributes data/doctrine only, never a
parallel tool (`binds.yaml`: template owns the operations, a derivation owns only its
entries and why). **Craft overlays:** a precedence ladder — bound repo's law → the
workflow's `.agents/craft/<skill-name>.local.md` overlay (full name, prefix included:
`craft-tdd.local.md`), which wins → skill defaults — in
full at `/craft-tdd` or `/craft-code-quality`.

## Tiers (RBAC)

`AGENTS.md` declares `tier:` — roles/credentials procedures presume. Write access via
CODEOWNERS; execution via the credentials required. Reads stay open — secret doctrine
goes in a separate restricted repo, never here.

## Voice

Agents adopt `VOICE.md`'s reduced voice for output, reports, commit bodies, PR
descriptions. Loaded every session via the root `CLAUDE.md` bridge.

## Baked-in skills

Index only — descriptions load via frontmatter:

- `/workflow-init` — tooling, `init.lock`, tool tiers, MCP wrapper doctrine.
- `/workflow-agents-sync` — canonical-format enforcement.
- `/workflow-template-sync` — the upstream link.
- `/workflow-manage` — bind registry, workspace assembly.
- `/workflow-bind` — attach standing binds to a session.
- `/workflow-gateway` — local opencodex gateway, opt-in per session.
- `/workflow-orchestrate` — directive → task list → tiered dispatch → loop; DoD is
  exhaustion **plus** harvest, decided by `orchestrate.sh status`.
- `/craft-event-naming` — canonical event/command naming, progressive omission.
- `/craft-tdd` — test-first protocol.
- `/craft-code-quality` — size budgets, lint, architecture, ratchet.
