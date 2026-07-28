---
tier: dev            # dev | ops | admin — the roles/credentials these procedures presume
---

## Constitution check

This session must ALSO have loaded the root constitution (imported via
`@.constitution.md` — it opens with "MANDATORY FIRST — verify initialization"). If you
did not see that section, this clone's symlinks are broken (Windows git /
`core.symlinks=false`) — fail closed: stop, run
`.claude/skills/workflows-agents-sync/agents-sync.sh --check` and `/workflows-init`, and
fix the clone before any work.

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
