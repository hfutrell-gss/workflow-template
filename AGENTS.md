---
tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
---

## Core check

This session must ALSO have loaded `AGENTS.CORE.md` (the managed constitution — it
opens with "MANDATORY FIRST — verify initialization"). If you did not see that content
this session, run `/workflow-agents-sync` to check the root `CLAUDE.md` bridge (it must
import both `@AGENTS.CORE.md` and `@AGENTS.md`) and fix drift. `AGENTS.CORE.md` is
picked up the same way house `AGENTS*.md` discovery already covers this file — no
separate mechanism needed.

# <Area> — doctrine

Area of work: **<one sentence: what whole area this workflow owns>.**

## Responsibilities
- <what this workflow is accountable for, as durable duties — not tasks>

## Conditions
- <the invariants and constraints under which all work in this area happens>

## Procedures
- [playbooks/<name>.md](playbooks/) — <when to use it>
<!-- executable procedures go in .agents/skills/<name>/SKILL.md (scoped: "<area>:<name>"),
     with a .claude/skills/<name>/SKILL.md proxy stub for Claude Code discovery -->

## Typical checkouts
```sh
claude --add-dir <standing-bind-repo> [--add-dir <standing-bind-repo> ...]
```
Or, once in-session: run `/workflow-bind` to attach this workflow's default standing
binds (see `binds.yaml`), plus anything else asked for.
