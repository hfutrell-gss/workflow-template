# GLOSSARY.md — this system's ubiquitous language

<!-- TEMPLATE-MANAGED: this file is owned by workflow-template-sync. In a derivation it
     is updated by `workflow-template-sync update`, never hand-edited. Edit it here, in
     workflow-template itself, to change what every derivation inherits. -->

The terms this system is built from. Settled here so they are not re-argued.

We practise DDD, so this repo obeys its own rule: one language, and the code uses the
words below. `/code-craft-ubiquitous-language` is the doctrine for holding an application's
language together; this file is that doctrine applied to the workflow system itself.

The four load-bearing terms — workflow, application, carried work, session — are defined
in `AGENTS.CORE.md` "The shapes" as well, because they are always loaded. Everything else
is here.

**This file is managed. Your terms go in `GLOSSARY.local.md`.** This glossary holds the
system's vocabulary and `workflow-template-sync update` overwrites it. A derivation's own
area of work has its own language — its applications, its domain nouns, the distinctions
that matter to it — and that belongs in `GLOSSARY.local.md` at the derivation root:
unmanaged, committed, yours. Same shape as the entries below. See `AGENTS.CORE.md` "DDD,
applied to a workflow repo".

### Application

A thing a workflow acts on, with particulars of its own. Durable: it outlives every
session run against it. Its operational picture is `workflows/<workflow>/<app>/profile.md`.

**Is not:** a *session*. A session is disposable and an application is not: an application
made disposable leaves unfinished work nowhere to survive.

### Bind

Attaching a repo to a workflow. **Standing binds** are declared in `binds.yaml` with a
`kind` and a `why` — a registry, not a state. **Session binds** are repos actually
attached to the running session, by `/add-dir`.

**Is not:** a checkout. Declaring a standing bind attaches nothing; `/workflow-bind` does.

### Carried work

Epics, deferred tasks, and threads that cross sessions. Lives in
`workflows/<workflow>/<app>/tasks.md`, under `## Open`. Reached by promoting a task with
the `[^]` marker.

**Is not:** a *backlog* of everything wanted. It is what a closing session could not
finish and someone still wants. Also not the *ledger*, which shares the file and records
what already happened.

### Core

The one pack a workflow repo cannot decline: it defines the shapes every other pack plugs
into, and every operation on them. Declared in `.template.lock`. This repo is it.

**Is not:** everything that ships. Engineering opinion is a pack (`code-craft`), not the core.

### Derivation

A workflow repo created from the core, tracking it through `.template.lock`. Owns
everything outside the managed set. May pin, or eject entirely.

### Journal

`journal/YYYY-MM-DD-slug.md` — one dated file per **decision about this workflow repo**:
why the system is shaped as it is, when the reason would not survive in a diff.

**Is not:** a record of a run. That is the *ledger*. A journal entry answers "why is the
system built this way?"; a ledger line answers "what has been done to this application?".

### Lane

A route to a model — an API, a gateway, a local proxy. A **tier** resolves to a lane
through the roster. A lane that answers 401 is not available, however many times it is
retried.

### Ledger

The `## History` section of `workflows/<workflow>/<app>/tasks.md`. One permanent line per
session closed against that application — directive, counts by disposition, where the
reaping landed. Written only by `orchestrate.sh close`, derived from the session's own
task list.

**Is not:** hand-written, and not a narrative. A line nobody earned by passing the DoD
gate is a claim, not a record.

### Managed set

The exact list of paths a pack owns in a workflow repo — `template-manifest.yaml`
(`managed:`) for the core, `pack.yaml` (`provides:`) for a pack. `update` copies these
forward and touches nothing else. Everything outside every manifest belongs to the
derivation.

**Is not:** everything a pack ships. A path absent from the manifest reaches no
derivation, however correct it is.

### Overlay slot

A path the core or a pack reads but never writes, so a derivation can change a default
without forking the thing that holds it — `.agents/code-craft/<skill-name>.local.md`,
`.agents/orchestrate/roster.local.yaml`, `.agents/init/tools.local.d/<tool>.sh`,
`GLOSSARY.local.md`. The ladder: a bound repo's law → the overlay → the defaults.

**Is not:** a fork, or a reason to pin. Where the overlay conflicts with the default, the
overlay wins, and `update` never touches it.

### Pack

A repo declaring in `pack.yaml` the exact paths it owns in a workflow repo, installed
with `/workflow-template-sync add`. Flat: no pack depends on another. One owner per path
— a collision is an error, never a merge. A path a pack stops providing is deleted on the
next update.

**Is not:** required. A workflow repo with no packs is complete, not degraded.

### Promotion

Two senses, both real, distinguished by what moves:

1. **Task promotion** — moving unfinished work from a session up into carried work
   (`[^]`).
2. **Upstream promotion** — moving a generalizable concept from a derivation up into the
   core, or into a pack. The workflow for it is `/upstream-workflow-management`.

### Proxy rule

`.claude` holds no content. Every `.claude/skills/<name>/SKILL.md` is a discovery stub
pointing at a canonical body: `.agents/skills/<name>/` for machinery,
`workflows/<name>/` for a workflow. Nothing executable under `.claude`.

### Reaping

The gate that closes a session: its durable output must leave the session directory
before the session may be deleted. See `AGENTS.CORE.md` "Reaping law".

**Is not:** archiving. Nothing is kept. `git log` is the archive.

### Session

One discrete instantiation of a workflow against an application. Temporal, and disposable
once reaped. Lives at `workflows/<workflow>/<app>/<session>/`. Ends with
`orchestrate.sh close`, which leaves one *ledger* line behind and deletes the directory.

**Is not:** a *workflow*. A workflow is timeless and knows nothing about when it runs. Do
not name a session directory after the workflow concept; name it for what the session is
for.

### Substrate

A repo a workflow operates *on*, rather than *in*. Cloned into `workspace/`. Its own law
wins inside its boundaries.

### Tier

The abstraction a task is dispatched to: `flagship` (consultant), `workhorse`
(orchestrator), `fleet` (workers). Resolved to a lane by the roster.

**Is not:** a model name. Naming a model in a task list makes the list unresumable on a
machine where that model is unavailable.

### Workflow

The techniques, tactics, and procedures of one nature of work — `web-app-development`,
`refactor`, `upstream-workflow-management`. Timeless. A skill with state: its body is
`workflows/<workflow>/SKILL.md`, its directory holds the applications it acts on.

**Is not:** a session, a run log, or a journal. **Also not** the `workflow-*` skill
prefix, which is an ownership marker on template machinery and describes nothing about
the skill's subject.

### Workflow repo

The container: one repo capturing a whole area of work, composed from a core plus any
number of packs.

### Workspace

`workspace/` at a workflow repo's root. Per-machine, gitignored, where standing binds are
cloned. A workflow manages its own clones here and never reaches into a personal checkout
elsewhere on disk.
