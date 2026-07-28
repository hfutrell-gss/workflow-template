---
name: workflow-template-sync
description: >-
  The upstream link between workflow-template and a derived workflow repo. `derive`
  turns a fresh copy/clone of the template into a derivation (writes .template.lock).
  `update` pulls forward changes to the managed set (AGENTS.CORE.md, CLAUDE.md,
  template-manifest.yaml, the workflow-* skills) from upstream, unless pinned.
  `--check` reports current vs upstream template version. Use when asked to derive a
  new workflow from the template, to sync/update a derivation's managed core, to check
  whether a derivation is behind upstream, or to pin/unpin a derivation.
---

@../../../.agents/skills/workflow-template-sync/SKILL.md
