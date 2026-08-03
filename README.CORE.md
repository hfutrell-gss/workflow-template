# README.CORE.md — how a workflow repo works

**Managed by the core. Never hand-edit this file in a derivation** — an `update` overwrites
it. A correction belongs upstream, via `/upstream-workflow-management`.

This is the operator's manual for the mechanics every workflow repo shares: the layout, the
skills, packs, tooling, binds, and staying current. It exists so a derivation's own `README`
does not have to re-document any of it — a hand-written copy of this material drifts in the
copy, never in the original, and the reader who finds the copy first reads the version
nothing enforces.

**Three files, three jobs:**

| File | Holds | Read it when |
|------|-------|--------------|
| `AGENTS.CORE.md` | **Law.** The shapes, bind law, reaping law, composition, the categorical rule. Loaded every session | Deciding whether something is *allowed* or *correctly shaped* |
| `README.CORE.md` (this file) | **Orientation.** How the machinery is operated. Not loaded into sessions | Finding your way around, or running something |
| `GLOSSARY.md` | **Terms.** Every word this system uses, with what it is not | A term is ambiguous — look it up rather than re-deriving it |

Where this file and `AGENTS.CORE.md` appear to disagree, the law wins and this file is the
bug.

A derivation's own `README.md` and `AGENTS.md` are entirely its own: its area of work, its
doctrine, its workflows, its skills.

## What a workflow repo is

A workflow repo captures the techniques, tactics, procedures, and doctrine for one **area of
work** (stewardship, schema management, incident response, folding code into a monolith).
Code repos are **substrate** — operated *on*, not *in*. Substrate is attached to a session
as a **bind**; it is never nested inside the workflow repo.

Every workflow repo is **composed**: exactly one **core** (this managed set, tracked in
`.template.lock`) plus any number of optional **packs** (`packs.yaml`). A repo with no packs
is complete, not degraded.

## The four levels

Full rule, and why collapsing any two loses work: `AGENTS.CORE.md`, "The shapes".

| Level | Lifetime | Home |
|-------|----------|------|
| **Workflow** — the TTPs of one nature of work | timeless, never pruned | `workflows/<workflow>/SKILL.md` |
| **Application** — a thing the workflow acts on | durable | `workflows/<workflow>/<app>/profile.md` |
| **Carried work** — what crosses sessions, and the ledger of those closed | outlives any session | `workflows/<workflow>/<app>/tasks.md` |
| **Session** — one run | disposable *after* reaping | `workflows/<workflow>/<app>/<session>/tasks.md` |

A **workflow** is a nature of work, named for the change it makes (`extract-callwrappers`,
`decompose-to-api`). A generalized tactic every workflow reaches for is a **skill**, not a
workflow. Both tests are in `AGENTS.CORE.md` ("Naming a workflow", "A generalized tactic is
a skill"). An empty `workflows/` is not misconfiguration — a campaign earns a workflow when
it is about to run.

Scaffold one, never by hand:

```sh
.agents/skills/workflow-manage/new-workflow.sh <name>
```

## Layout

| Path | What it is | Managed |
|------|------------|---------|
| `AGENTS.CORE.md` | The constitution | **yes** |
| `README.CORE.md` | This file | **yes** |
| `VOICE.md` | The reduced-voice contract for agent output | **yes** |
| `GLOSSARY.md` | The system's terms | **yes** |
| `CLAUDE.md` | One pointer at `@AGENTS.md`, nothing else | **yes** |
| `template-manifest.yaml` | The core's manifest — the exact path list it owns | **yes** |
| `AGENTS.md` | This repo's own doctrine | no |
| `README.md` | This repo's own front door — its area of work | no |
| `GLOSSARY.local.md` | This repo's own terms | no |
| `binds.yaml` | Standing-bind registry (`kind` + `why`); `base` says where they live on disk | no |
| `workspace/` | Per-machine substrate clones. Gitignored, never committed, never a personal checkout | no |
| `workflows/` | Workflows and all their state (the four levels above). **Committed**, so a run resumes after a cold tick or on another machine | no |
| `journal/` | One dated file per **decision about this repo**. Never a run narrative — that is the application ledger's line | no |
| `playbooks/` | Procedures as they stabilize | no |
| `packs.yaml` / `packs.lock` | Which packs this repo composes, and what each installed | no |
| `.template.lock` | Which core version, and its upstream. Delete to eject | no |
| `init.lock` | Per-machine record that init ran. Gitignored | no |
| `.agents/skills/` | Canonical skill bodies and scripts | mixed |
| `.claude/skills/` | Discovery stubs only — frontmatter plus a pointer. Nothing executable | mixed |
| `.agents/<pack>/`, `.agents/orchestrate/`, `.agents/init/tools.local.d/` | Overlay slots — where this repo overrides installed defaults | no |
| `.mcp.json` | MCP server registrations. Point `command` at a `${HOME}/.local/bin/<name>` wrapper so the committed file holds no machine-specific path | no |

## Skills

**`.claude` is a proxy for `.agents`.** A skill's full body and scripts live at
`.agents/skills/<name>/SKILL.md`; `.claude/skills/<name>/SKILL.md` is a thin stub for
discovery. A workflow's canonical body is `workflows/<name>/SKILL.md` instead. Nothing
executable lives under `.claude`.

`.agents/skills/` holds **three kinds** of body: the core's `workflow-*` machinery, whatever
a pack installs, and **this repo's own generalized tactics**. That third kind is legitimate —
a tactic that is this area of work's standing expectation but no wider concern.

**Prefixes.** `workflow-*` is reserved by the core. A pack owns whatever prefix it ships
(`code-craft-*` for `code-craft`). Name a local skill outside every installed prefix or an
`update` may clobber it; `new-workflow.sh` reads `.agents/skills/` and refuses a collision
rather than trusting a list.

The core's own, present in every workflow repo — all mechanism:

| Skill | Purpose |
|-------|---------|
| `/workflow-init` | Install/verify required tooling, record per-machine decisions on opt-in tools, write `init.lock` |
| `/workflow-check` | Every organizational constraint in one pass, with stable rule IDs. Owns none of them — each skill owns the constraints for its own shapes |
| `/workflow-agents-sync` | Enforce the AGENTS-canonical format here and across standing binds on disk |
| `/workflow-template-sync` | Composition: `derive`, `add`/`remove` a pack, `update`, `list`, `--audit`, `--check` |
| `/workflow-manage` | Standing binds, and scaffolding a workflow |
| `/workflow-bind` | Attach standing binds to a session |
| `/workflow-plugins` | The plugin registry, and a per-user opt-out |
| `/workflow-orchestrate` | Directive → committed task list → dispatch per tier → loop until exhausted **and** reaped |
| `/upstream-workflow-management` | Promote a generalizable concept from here into the core or a pack |

## Orchestration

For anything beyond a single step, invoke `/workflow-orchestrate`. The directive becomes a
committed task list at `workflows/<workflow>/<app>/<session>/tasks.md`; work is dispatched
per model **tier** (`flagship` consultant · `workhorse` orchestrator · `fleet` workers),
resolved from a lane roster — **never a hardcoded model name**, or the list stops being
resumable on a machine where that model is unavailable.

**Definition of Done is exhaustion plus reaping**, decided by `orchestrate.sh status`, not
asserted. A run whose tasks are all `[x]` but whose notes and decisions are still stranded in
the session directory is not done. `orchestrate.sh close` is the one command that ends a
session: it re-checks the DoD, writes the ledger line into `<app>/tasks.md` `## History`, and
deletes the directory in the same step. Never delete a session by hand — the ledger line is
what remains of the run.

## Packs

The core defines the shapes; everything else is a **pack** — a repo with a `pack.yaml`
declaring the exact paths it owns.

```sh
.agents/skills/workflow-template-sync/template-sync.sh add <url-or-path>
.agents/skills/workflow-template-sync/template-sync.sh list
.agents/skills/workflow-template-sync/template-sync.sh remove <name>
```

**Composition, not more inheritance.** The core cannot know your area of work, so anything it
shipped beyond the shapes would be a guess — and guesses belong in things you can decline.

Three invariants, enforced rather than advised: **one owner per path** (a collision is an
error, refused before any write), **a dropped path is removed** (retiring a skill upstream
retires it everywhere instead of leaving orphans), and **no inter-pack dependencies** (no
resolver, no ordering, no version solving). A pack may state `requires_core:` — the core is
the platform, not a peer. `--audit` re-checks all of it offline as `PACK-001..004`.

**What a pack may claim:** a skill body, its stub, a workflow's timeless half, and that
workflow's `references/`. It may ship workflows as well as skills. It may **never** claim
`workflows/<name>/<app>/**` (this repo's record of its own work), root law,
`.claude/settings*`, hooks, `.mcp.json`, or an overlay slot — those apply or execute without
anyone invoking them.

**The trust model is social.** `add` runs `scan` first and refuses on findings until
`--reviewed` is passed, checking claimed paths against those shapes and grepping for
credential reads, egress, pipe-to-shell, destructive writes, and obfuscation. **It is a
heuristic, not a security boundary** — it catches carelessness and the obvious, never a
competent attacker. Installing a pack copies executable scripts and always-loaded doctrine
into a repo you then run agents inside. Install packs you wrote, or packs whose maintainer
you would already trust with a commit bit here.

### Overlay slots

A pack ships opinion into repos whose area of work it cannot know, so every one declares a
precedence ladder: **a bound repo's own law wins inside its boundaries → then this repo's
overlay → then the pack's defaults**, which apply in full force only where the first two are
silent.

To change a default, write the overlay: `.agents/<pack-name>/<skill-name>.local.md`, the
skill's full name including its prefix — so `/code-craft-quality` overlays at
`.agents/code-craft/code-craft-quality.local.md`. Unmanaged, so `update` never touches it and
`remove` never deletes it. No forking, no pinning, no drift.

The core's own slots use the same convention:

| Slot | Overrides |
|------|-----------|
| `.agents/orchestrate/roster.local.yaml` | tier→lane preference, role→tier |
| `.agents/orchestrate/orchestrate.local.md` | orchestration doctrine |
| `.agents/init/tools.local.d/<tool>.sh` | adds a tool to init |
| `GLOSSARY.local.md` | this repo's own terms |

Each pack documents its own slots; the core keeps no list, because that list goes stale the
moment a pack is added.

## Tooling

```sh
.agents/skills/workflow-init/init.sh --check   # verify only
.agents/skills/workflow-init/init.sh           # install what is missing
```

Two tiers. **Required** tools every procedure here assumes. **Recommended** tools that are
opt-in per machine — nothing recommended is installed until you decide so
(`init.sh decide <tool> install`). An undecided or skipped recommended tool is never a
failure, only a note pointing at how to opt in.

A repo adds **its own** tool by dropping `.agents/init/tools.local.d/<tool>.sh`
(`check_`/`install_`, optional `unsupported_reason_`, then `register_tool`), which `init.sh`
sources — so it inherits the whole decide/install/`--check` mechanism. Overlay tools are
always recommended-tier, and a platform-limited one declaring `unsupported_reason_<tool>()`
degrades to a note rather than permanent drift on a machine that cannot host it. **Never fork
`init.sh` or hand-roll a parallel installer**: the first is overwritten by `update`, the
second is the same violation with extra steps.

`init.lock` records the result per machine. `AGENTS.CORE.md`'s mandatory first check compares
it against `.agents/skills/workflow-init/VERSION`; a mismatch means run `/workflow-init`
before anything else.

## Binds

Full rule: `AGENTS.CORE.md`, "Bind law". You work by **binding** repos to a session, not by
being in a repo.

- **Standing binds** (`binds.yaml`) — repos related to this workflow, declared with the
  relationship (`kind` + `why`). A registry; it attaches nothing by itself. An empty registry
  is a complete repo, not a broken one.
- **Session binds** — repos attached to *this* session, via `claude --add-dir <path>`
  (repeatable) at launch or `/add-dir` once running. `/workflow-bind` attaches every
  `default: true` standing bind plus anything else asked for.

Standing binds live on disk in this repo's own `workspace/` — `binds.yaml`'s `base` (default
`./workspace`) resolves relative to the repo root unless given as an absolute or `~` path.
`/workflow-manage`'s `sync-binds.sh` populates it. A workflow manages its own clones there
and never resolves a standing bind into a checkout it does not own, including a user's
personal working copy.

Every bind: **read the target's `AGENTS.md` first** and honor its acknowledgement protocol.
**Repo law wins inside its own boundaries.** And **surface, don't suppress** — report drift,
conflicts, and anomalies rather than resolving them silently.

## Staying current with the core

```sh
.agents/skills/workflow-template-sync/template-sync.sh --check   # installed vs available
.agents/skills/workflow-template-sync/template-sync.sh update    # pull the managed set forward
```

Only the managed set moves; `template-manifest.yaml` is the exact list, and this repo's own
copy of it is the record of what the core previously owned. A path the core drops is deleted
on the next update.

**A fix that would be correct in every derivation does not belong in one derivation.**
Promote it with `/upstream-workflow-management` — into the core if it is a shape, into a pack
if it is opinion.

**The covenant: the core facilitates, never constrains.** Everything outside the managed set
is entirely this repo's. `pinned: true` in `.template.lock` freezes the core without
ejecting; deleting `.template.lock` ejects entirely. Either is supported for the life of the
project.

## Prerequisite

Linux x86_64, including WSL2 — `/workflow-init` supports no other platform yet.

## Git discipline

**Always invoke `/usr/bin/git` explicitly**, never a bare `git`, which can resolve to a
Windows binary under WSL when a shell alias shadows it. `/workflow-init --check` detects the
alias and warns. Rationale: `AGENTS.CORE.md`, "Journal, session state, git".
