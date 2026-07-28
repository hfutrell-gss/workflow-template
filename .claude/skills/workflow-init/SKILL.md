---
name: workflow-init
description: >-
  Initialize (or verify) this machine for this workflow repo: ensure required tools
  (git, yq) and record per-machine decisions about recommended tools (Obsidian,
  codegraph, opencodex), then write init.lock at the repo root. Use when the root
  AGENTS.CORE.md init check fails (init.lock missing or stale), when asked to run
  /workflow-init, when opting a recommended tool in or out, or when setting up a
  fresh machine.
---

@../../../.agents/skills/workflow-init/SKILL.md
