---
tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
---

@AGENTS.CORE.md

## Core check

This session must ALSO have loaded `AGENTS.CORE.md` (the managed constitution — it
opens with "MANDATORY FIRST — verify initialization") and, through it, `VOICE.md`. If
you did not see that content, run `/workflow-agents-sync`. The chain is `CLAUDE.md` →
`@AGENTS.md` (this file) → `@AGENTS.CORE.md` → `@VOICE.md`: composition lives on the
AGENTS side, and `CLAUDE.md` holds one pointer and nothing else.

# <Area> — doctrine

Area of work: **<one sentence: what whole area this workflow owns>.**

## Responsibilities
- <what this workflow is accountable for, as durable duties — not tasks>

## Conditions
- <the invariants and constraints under which all work in this area happens>

## Packs
<!-- What this repo composes in beyond the core. Managed by /workflow-template-sync;
     `template-sync.sh list` prints the live answer. -->
- `craft` — engineering doctrine (`/code-craft-tdd`, `/code-craft-quality`,
  `/code-craft-event-naming`, `/code-craft-ubiquitous-language`). Optional; drop this line and the
  pack together if this area of work does not want it.

## Workflows
- `/upstream-workflow-management` — managed by the core; promote a generalizable concept
  from this repo upstream — into the core if it is a shape, into a pack if it is opinion.
- `/<workflow-name>` — <the nature of work it covers>. A workflow is
  `workflows/<name>/SKILL.md` plus its `.claude/skills/<name>/` discovery stub. Scaffold one
  with `/workflow-manage new-workflow <name>`; name it outside the core's reserved
  `workflow-*` prefix and outside any prefix an installed pack ships.
<!-- executable procedures go in .agents/skills/<name>/SKILL.md (scoped: "<area>:<name>"),
     with a .claude/skills/<name>/SKILL.md proxy stub for Claude Code discovery -->

## Craft defaults
<!-- Scaffold — this section is yours: keep, edit, or delete it. It exists because a skill
     that never fires is worth nothing, and nothing else nudges the code-craft-* skills into
     play. Deliberately a suggestion here rather than a rule in AGENTS.CORE.md: a
     mandatory always-loaded trigger would re-create the static-context cost these skills
     exist to avoid. Delete the section outright if this repo does not install the code-craft
     pack. -->
Requires the **code-craft pack** (`/workflow-template-sync add <pack-code-craft>`). Before writing
or changing production code in bound substrate, invoke `/code-craft-tdd` and
`/code-craft-quality`. Override their defaults for this workflow in
`.agents/code-craft/code-craft-tdd.local.md` and `.agents/code-craft/code-craft-quality.local.md` — a bound repo's
own law still wins inside its boundaries.

## Orchestration
For anything beyond a single step, invoke `/workflow-orchestrate`: the directive becomes a
committed task list under `workflows/<workflow>/<app>/<session>/`, work is dispatched per model tier
(`flagship` · `workhorse` · `fleet`), and the run is done only when the list is exhausted AND
its durable output harvested out of the run directory.
Set this workflow's tier→lane preference in `.agents/orchestrate/roster.local.yaml`.

## Typical checkouts
```sh
claude --add-dir <standing-bind-repo> [--add-dir <standing-bind-repo> ...]
```
Or, once in-session: run `/workflow-bind` to attach this workflow's default standing
binds (see `binds.yaml`), plus anything else asked for.
