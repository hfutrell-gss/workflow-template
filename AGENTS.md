---
tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
---

## Core check

This session must ALSO have loaded `AGENTS.CORE.md` (the managed constitution — it
opens with "MANDATORY FIRST — verify initialization"). If you did not see that content
this session, run `/workflow-agents-sync` to check the root `CLAUDE.md` bridge (it must
import `@AGENTS.CORE.md`, `@VOICE.md`, and `@AGENTS.md`) and fix drift. `AGENTS.CORE.md`
is picked up the same way house `AGENTS*.md` discovery already covers this file — no
separate mechanism needed.

# <Area> — doctrine

Area of work: **<one sentence: what whole area this workflow owns>.**

## Responsibilities
- <what this workflow is accountable for, as durable duties — not tasks>

## Conditions
- <the invariants and constraints under which all work in this area happens>

## Procedures
- `/<procedure-name>` — <when to use it>. Procedures are derivation-local skills:
  `.agents/skills/<name>/` plus its `.claude/skills/<name>/` proxy stub. Scaffold one with
  `/workflow-manage`; name it outside the reserved `workflow-*` and `craft-*` prefixes.
<!-- executable procedures go in .agents/skills/<name>/SKILL.md (scoped: "<area>:<name>"),
     with a .claude/skills/<name>/SKILL.md proxy stub for Claude Code discovery -->

## Craft defaults
<!-- Scaffold — this section is yours: keep, edit, or delete it. It exists because a skill
     that never fires is worth nothing, and nothing else nudges the craft-* skills into
     play. Deliberately a suggestion here rather than a rule in AGENTS.CORE.md: a
     mandatory always-loaded trigger would re-create the static-context cost these skills
     exist to avoid. -->
Before writing or changing production code in bound substrate, invoke `/craft-tdd` and
`/craft-code-quality`. Override their defaults for this workflow in
`.agents/craft/tdd.local.md` and `.agents/craft/code-quality.local.md` — a bound repo's
own law still wins inside its boundaries.

## Orchestration
For anything beyond a single step, invoke `/workflow-orchestrate`: the directive becomes a
committed task list under `workflows/<workflow>/<target>/`, work is dispatched per model tier
(`flagship` · `workhorse` · `fleet`), and the run is done only when the list is exhausted AND
its durable output harvested out of the run directory.
Set this workflow's tier→lane preference in `.agents/orchestrate/roster.local.yaml`.

## Typical checkouts
```sh
claude --add-dir <standing-bind-repo> [--add-dir <standing-bind-repo> ...]
```
Or, once in-session: run `/workflow-bind` to attach this workflow's default standing
binds (see `binds.yaml`), plus anything else asked for.
