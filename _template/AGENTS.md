---
tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
---

# <Area> — doctrine

Area of work: **<one sentence: what whole area this workflow owns>.**

## Responsibilities
- <what this workflow is accountable for, as durable duties — not tasks>

## Conditions
- <the invariants and constraints under which all work in this area happens>

## Procedures
- [playbooks/<name>.md](playbooks/) — <when to use it>
<!-- executable procedures go in .claude/skills/<name>/SKILL.md (scoped: "<area>:<name>") -->

## Typical checkouts
```sh
wf <area>                     # doctrine-only session
wf <area> <repo> [<repo>...]  # bound to substrate targets
```
