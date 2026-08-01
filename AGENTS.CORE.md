# AGENTS.CORE.md — the constitution

<!-- TEMPLATE-MANAGED: this file is owned by workflow-template-sync. In a derivation it is
     updated by `workflow-template-sync update`, never hand-edited. Edit it here, in
     workflow-template itself, to change what every derivation inherits. -->

@VOICE.md

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
repos are **substrate** — operated *on*, not *in*. This repo is the **core** every
workflow repo composes in: managed law, the shapes, the operations on those shapes, and
a live link upstream. Read "The shapes" and "Composition" below before adding anything.

## Canonical file format

**`AGENTS.md` is canonical, here and in every bound repo.** `CLAUDE.md` is at most a
header importing the sibling `AGENTS.md` — one pointer, no content of its own, and the
same single-import form at the root as anywhere else; `/workflow-agents-sync` enforces
this. **Composition never lives on the Claude side.** What else loads is decided by the
AGENTS chain: root `AGENTS.md` imports `@AGENTS.CORE.md`, which imports `@VOICE.md`. A
`CLAUDE.md` that imports two or three files has taken over a decision that is not its
to make, and a derivation that reads its law through Claude-specific plumbing has the
dependency backwards — `AGENTS.md` is the law; `CLAUDE.md` is one vendor's way of
finding it.

**The proxy rule: `.claude` holds no content.** Every `.claude/skills/<name>/SKILL.md`
is a thin stub with discovery frontmatter and a pointer to a canonical body elsewhere:
`.agents/skills/<name>/SKILL.md` for machinery, `workflows/<name>/SKILL.md` for a
workflow. Nothing executable under `.claude`. At root, law splits across `AGENTS.CORE.md` (this file) and `AGENTS.md`
(derivation's own doctrine); `AGENTS.md` imports `AGENTS.CORE.md`, and `CLAUDE.md`
points at `AGENTS.md` alone.

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

Four levels, each with a different lifetime. Collapsing any two makes work unfindable
or throws it away:

| Level | What it is | Lifetime | Home |
|-------|-----------|----------|------|
| **Workflow** | the TTPs of one nature of work (`web-app-development`, `refactor`) | timeless | `workflows/<workflow>/SKILL.md` |
| **Application** | a thing the workflow acts on, with its own particulars | durable | `workflows/<workflow>/<app>/profile.md` |
| **Carried work** | epics, deferred tasks, threads that link sessions | outlives any session | `workflows/<workflow>/<app>/tasks.md` |
| **Session** | one discrete instantiation of a workflow against an application | temporal | `workflows/<workflow>/<app>/<session>/tasks.md` |

A workflow does not know when it runs. A session does not know anything but its own
run. Carried work is the only thing that crosses sessions, and it is the reason the
application level exists: delete a session and its unfinished work must survive, or the
next session starts blind.

These four are defined again in `GLOSSARY.md`, with every other term this system uses —
bind, substrate, derivation, harvest, tier, lane, overlay, promotion. Look a term up
there rather than re-deriving it.

Six kinds of thing live here; one home each:

| Kind | What it is | Home | Retrieved by |
|------|-----------|------|--------------|
| **Law** | the managed constitution | `AGENTS.CORE.md` | always loaded |
| **Doctrine** | this workflow repo's standing judgment | `AGENTS.md` | always loaded |
| **Workflow** | the TTPs of a nature of work | `workflows/<workflow>/SKILL.md` | **lazily, by the Skill tool** |
| **Knowledge** | what is true, and why | substrate repo's docs; `<app>/profile.md` for operational particulars | index line, then on demand |
| **Session** | one run's task list and notes | `workflows/<workflow>/<app>/<session>/` | only the session that owns it |
| **Narrative** | what happened on a given day | `journal/` | humans, archaeology |

**A workflow is a skill with state.** Its body is the timeless part — frontmatter
description, thin body, `references/` for depth, retrieved lazily. Its directory also
holds the durable state the TTPs act on: applications, their particulars, their carried
work, and the sessions run against them. `/workflow-manage new-workflow <name>`
scaffolds both halves and the `.claude/skills/<name>/` discovery stub.

**The proxy rule applies unchanged.** `.claude/skills/<name>/SKILL.md` is a stub that
points at the canonical body. For a workflow the canonical body is
`workflows/<name>/SKILL.md`, not `.agents/skills/`. `.agents/skills/` holds skill bodies
only: the core's `workflow-*` machinery, plus whatever a pack installs there. Both
namespaces reach the Skill tool, so a workflow must not take a skill's name.

**Managed workflows.** The template ships workflows too, not only skills.
`upstream-workflow-management` is one, present in every derivation: the TTPs for
finding a generalizable concept in a derivation and promoting it upstream. Its
application is `self`. Managed workflows are listed in `template-manifest.yaml`; a
derivation must not create a workflow with a managed name.

**Harvest law:** a session is done only when its durable output has **left** the
session directory:

| Output | Goes to |
|--------|---------|
| a stabilized way of working | the workflow's `SKILL.md` or `references/` |
| understanding of an application | that repo's own docs, or `<app>/profile.md` |
| work not finished, still wanted | `<app>/tasks.md` — carried, not lost |
| what merely happened | `journal/` |

Then the session directory closes and is **deleted**, not archived — `git log` is the
archive. Unfinished work never blocks a session forever: it is promoted to carried work
and the session closes.

## DDD, applied to a workflow repo

This system is built DDD-first, and a derivation is expected to be too. Not by analogy —
the structure is already there, and naming it stops it being re-invented:

| DDD | Here |
|-----|------|
| Bounded context | the workflow repo — one area of work, one language |
| Ubiquitous language | `GLOSSARY.md` (managed, this system's terms) + `GLOSSARY.local.md` (the derivation's own) |
| Context map | `binds.yaml` — `kind:` names the relationship, and `upstream`/`downstream`/`stewarded`/`reference`/`co-change` are those relationships, not labels resembling them |
| Anti-corruption layer | bind law: a bound repo's law wins inside its boundaries. You do not impose this repo's language on substrate |
| Aggregate | an application — it has identity, it is durable, and it owns its own particulars |

What this asks of a derivation:

- **Keep one language, and write it down.** `GLOSSARY.local.md` at the derivation's root
  is yours: unmanaged, never touched by `update`, the same overlay mechanism the `code-craft-*`
  skills use. Put your area's terms there. `GLOSSARY.md` stays the system's terms.
- **Name a term the first time it is ambiguous, not the third.** The cost of the wrong
  name is paid in every session afterward. This repo learned that by naming a directory
  after the wrong sense of "workflow".
- **Do not translate at the boundary.** When a bound repo names a thing, use its name
  inside its boundaries. Two names for one concept is the defect, wherever it appears.
- **`/code-craft-ubiquitous-language`** carries the full doctrine — from the `code-craft` pack, so
  a repo without that pack keeps the duty and loses only the guidance. It governs this
  repo as much as any application it stewards.

## Journal, session state, git

- **Journal** — one dated file per session/decision (`journal/YYYY-MM-DD-slug.md`),
  never one growing file. A day's session binds belong in that day's entry.
- **Session state** — **committed** (unlike `workspace/`) so it survives compaction or
  a machine change. Sessions predating this layout resolve for one more version at
  `.workflow/<slug>/`. See
  `/workflow-orchestrate`.
- **Git** — **always native git, `/usr/bin/git` explicitly**, never a bare `git` that
  may resolve to a Windows binary (a WSL `git=...git.exe` alias is the common trap).
  `/workflow-init --check` warns if detected.

## Composition

A workflow repo is **composed from packs**, not inherited from one parent. A **pack** is
a repo that declares, in `pack.yaml` at its root, the exact set of paths it owns:

```yaml
name: code-craft
version: 3
provides:
  - .agents/skills/code-craft-tdd/**
```

Two kinds, and the difference is only that one is required:

| | The core | A pack |
|---|---|---|
| What it is | this repo — the shapes, and every operation on them | capability layered on top |
| Manifest | `template-manifest.yaml` (`managed:`) | `pack.yaml` (`provides:`) |
| Declared in | `.template.lock` — exactly one, never removable | `packs.yaml` — any number, each removable |
| Optional | no | **yes.** A repo with no packs is complete, not degraded |

Install one with `/workflow-template-sync add <url>`; `update` pulls the core and every
pack forward; `remove` uninstalls a pack and deletes its paths. Three invariants make
composition safe, and all three are enforced, not advised:

- **One owner per path.** A path claimed by two packs is an **error**, refused before
  anything is written. Never a merge, never last-writer-wins.
- **A dropped path is removed.** A path a pack stops providing is deleted on the next
  update. Retiring a skill upstream retires it everywhere, instead of leaving orphans.
- **No inter-pack dependencies.** Packs are flat. There is no resolver, no ordering, no
  version solving — a pack that needs another pack's file is asking for the wrong shape.

**Why composition and not more inheritance.** The core cannot know your area of work, so
anything it ships beyond the shapes is a guess. Guesses belong in things you can decline.
`craft-*` was 40% of the core by size and none of it was mechanism; it is now the
`code-craft` pack, and a workflow repo that wants no engineering opinion installs it and nothing
breaks or warns.

**The categorical rule.** The core owns every operation on its shapes, as managed skills;
a derivation contributes data and doctrine only, never a parallel tool (`binds.yaml`: the
core owns the operations, a derivation owns only its entries and why). A pack owns the
operations on the shapes *it* introduces, by the same rule.

**The covenant.** The core facilitates, never constrains. Everything outside the managed
set is entirely the derivation's, ejectable any time (delete `.template.lock`);
`pinned: true` freezes updates without ejecting.

**Overlay slots** are how installed content stays configurable without forking it. The
convention, not a list: a pack that ships an opinion reads an unmanaged file the
derivation owns, under **`.agents/<pack-name>/`**, and lets it win. The core's own slots
follow the same convention:

| Slot | Overrides |
|---|---|
| `.agents/orchestrate/roster.local.yaml` | tier→lane preference, role→tier |
| `.agents/orchestrate/orchestrate.local.md` | orchestration doctrine |
| `.agents/init/tools.local.d/<tool>.sh` | adds a tool to init |
| `GLOSSARY.local.md` | the derivation's own terms |

**Each pack documents its own slots; the core does not enumerate them** — a list here
would go stale the moment a pack is added, and the core knowing a pack's paths is the
dependency backwards. Run `/workflow-template-sync list`, then read that pack.

The ladder everywhere: **a bound repo's own law → the derivation's overlay → the pack's
defaults**, which apply in full force only where the first two are silent. An overlay is
the derivation's answer to a pack, so **a pack may never claim its own overlay path** —
that would remove the only override the repo has — and `remove` never deletes one.

**What a pack may claim.** Exactly four shapes, enforced at install:

| Allowed | |
|---|---|
| `.agents/skills/<name>/**` | a skill body |
| `.claude/skills/<name>/SKILL.md` | its discovery stub |
| `workflows/<name>/SKILL.md` | a workflow's TIMELESS half |
| `workflows/<name>/references/**` | and its depth material |

**A pack may ship a workflow**, not only skills — the TTPs of a nature of work are as
generalizable as a test protocol. What it may never claim is `workflows/<name>/<app>/**`:
the applications, their carried work, and their sessions are the derivation's record of
its own work, and a pack able to overwrite them could erase a year of it on an update.
Root law, `.claude/settings*`, hooks, `.mcp.json`, and overlay slots are refused for the
same reason in reverse — they execute or apply without anyone invoking them.

**Packs are a supply-chain path, and the control is social.** `add` copies executable
scripts and always-loaded doctrine into a repo you then run agents inside.
`/workflow-template-sync scan` runs before every install and refuses on findings until
`--reviewed` is passed; it checks the claimed paths against the table above and greps the
files for credential reads, egress, pipe-to-shell, destructive writes, and obfuscation.
**It is a heuristic, not a boundary** — it catches carelessness and the obvious, and it
will not catch a competent attacker. Install packs you wrote, or packs whose maintainer
you would already trust with a commit bit on this repo. Nothing at this scale substitutes
for that.

## Tiers (RBAC)

`AGENTS.md` declares `tier:` — roles/credentials procedures presume. Write access via
CODEOWNERS; execution via the credentials required. Reads stay open — secret doctrine
goes in a separate restricted repo, never here.

## Voice

Agents adopt `VOICE.md`'s reduced voice for output, reports, commit bodies, PR
descriptions. Loaded every session: this file imports it, so it arrives wherever the
constitution does.

## Enforcement

Organizational constraints are **checked, not merely stated.** A rule nothing verifies is
a rule that decays, and every constraint here decayed at least once before it was
mechanized — the harvest law was broken by this repo, in its own directory, for ten
versions.

`/workflow-check` runs every constraint in one pass and returns one verdict. Each rule has
a stable ID (`LAYOUT-007`, `AGENTS-003`) that can be cited in a commit or a task list.

**Each skill owns the constraints for the shapes it defines** — the categorical rule
applied to enforcement. `/workflow-check` dispatches and aggregates; it implements
nothing. A constraint added to the aggregator instead of its owner is the fragmentation it
exists to end. The registry, with every rule and why it matters:
`.agents/skills/workflow-check/references/constraints.md`.

An unmet constraint is an ordinary result (exit 2). Only a checker that cannot run is a
failure (exit 1).

## Core skills

Index only — descriptions load via frontmatter. All mechanism; all present in every
workflow repo:

- `/workflow-init` — tooling, `init.lock`, tool tiers, MCP wrapper doctrine.
- `/workflow-agents-sync` — canonical-format enforcement.
- `/workflow-check` — every organizational constraint in one pass; the rule registry.
- `/workflow-template-sync` — composition: the core link, and `add`/`remove`/`update`
  for packs.
- `/workflow-manage` — bind registry, workspace assembly.
- `/workflow-bind` — attach standing binds to a session.
- `/workflow-gateway` — local opencodex gateway, opt-in per session.
- `/workflow-orchestrate` — directive → task list → tiered dispatch → loop; DoD is
  exhaustion **plus** harvest, decided by `orchestrate.sh status`.

Skills that arrive from a pack are not listed here — read `packs.yaml`, or run
`/workflow-template-sync list`. The one this system publishes:

- **`code-craft`** — engineering doctrine: `/code-craft-tdd`, `/code-craft-quality`,
  `/code-craft-event-naming`, `/code-craft-ubiquitous-language`. Optional. Install it in a workflow
  repo that wants opinions about how code is written; skip it in one that does not.

## Baked-in workflows

The template ships workflows too, not only skills:

- `/upstream-workflow-management` — promote a generalizable concept from a derivation to
  the template. Application: `self`.
