# GLOSSARY.md — this system's ubiquitous language

<!-- TEMPLATE-MANAGED: this file is owned by workflow-template-sync. In a derivation it
     is updated by `workflow-template-sync update`, never hand-edited. Edit it here, in
     workflow-template itself, to change what every derivation inherits. -->

The terms this system is built from. Settled here so they are not re-argued.

We practise DDD, so this repo obeys its own rule: one language, and the code uses the
words below. `/craft-ubiquitous-language` is the doctrine for holding an application's
language together; this file is that doctrine applied to the workflow system itself.

The four load-bearing terms — workflow, application, carried work, session — are defined
in `AGENTS.CORE.md` "The shapes" as well, because they are always loaded. Everything else
is here.

### Application

A thing a workflow acts on, with particulars of its own. Durable: it outlives every
session run against it. Its operational picture is `workflows/<workflow>/<app>/profile.md`.

**Is not:** a *session*. Conflating the two was a real defect — the two-level layout made
the application disposable, so unfinished work had nowhere to survive.

### Bind

Attaching a repo to a workflow. **Standing binds** are declared in `binds.yaml` with a
`kind` and a `why` — a registry, not a state. **Session binds** are repos actually
attached to the running session, by `/add-dir`.

**Is not:** a checkout. Declaring a standing bind attaches nothing; `/workflow-bind` does.

### Carried work

Epics, deferred tasks, and threads that cross sessions. Lives in
`workflows/<workflow>/<app>/tasks.md`. Reached by promoting a task with the `[^]` marker.

**Is not:** a *backlog* of everything wanted. It is what a closing session could not
finish and someone still wants.

### Craft overlay

A derivation-owned file at `.agents/craft/<skill-name>.local.md` that overrides a
`craft-*` skill's defaults. The template owns the slot; the derivation owns what fills
it. Where they conflict, the overlay wins.

### Derivation

A workflow repo created from the template, tracking it through `.template.lock`. Owns
everything outside the managed set. May pin, or eject entirely.

### Harvest

The gate that closes a session: its durable output must leave the session directory
before the session may be deleted. See `AGENTS.CORE.md` "Harvest law".

**Is not:** archiving. Nothing is kept. `git log` is the archive.

### Lane

A route to a model — an API, a gateway, a local proxy. A **tier** resolves to a lane
through the roster. A lane that answers 401 is not available, however many times it is
retried.

### Managed set

The exact list of paths in `template-manifest.yaml` that the template owns and
`workflow-template-sync update` copies forward. Everything else belongs to the
derivation.

**Is not:** everything the template ships. A path absent from the manifest reaches no
derivation, however correct it is.

### Promotion

Two senses, both real, distinguished by what moves:

1. **Task promotion** — moving unfinished work from a session up into carried work
   (`[^]`).
2. **Upstream promotion** — moving a generalizable concept from a derivation up into the
   template. The workflow for it is `/upstream-workflow-management`.

### Proxy rule

`.claude` holds no content. Every `.claude/skills/<name>/SKILL.md` is a discovery stub
pointing at a canonical body: `.agents/skills/<name>/` for machinery,
`workflows/<name>/` for a workflow. Nothing executable under `.claude`.

### Session

One discrete instantiation of a workflow against an application. Temporal, and disposable
once harvested. Lives at `workflows/<workflow>/<app>/<session>/`.

**Is not:** a *workflow*. A workflow is timeless and knows nothing about when it runs.
Naming session directories after the workflow concept is the mistake that produced this
glossary.

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

The container: one repo capturing a whole area of work. This template is the core every
derivation shares.

### Workspace

`workspace/` at a workflow repo's root. Per-machine, gitignored, where standing binds are
cloned. A workflow manages its own clones here and never reaches into a personal checkout
elsewhere on disk.
