---
name: workflow-agents-sync
description: >-
  Enforce the canonical file-format invariant: AGENTS.md (and .agents/ rules) are the
  canonical sources; every CLAUDE.md is at most a header bridge importing @AGENTS.md
  (root also imports @AGENTS.CORE.md). Scans this workflow's root and every standing
  bind from binds.yaml. Use when asked to run /workflow-agents-sync, after adding a
  standing bind, when a CLAUDE.md has accumulated content, or as part of routine
  drift-watch.
---

@../../../.agents/skills/workflow-agents-sync/SKILL.md
