---
name: workflow-template-sync
description: >-
  Composition for a workflow repo. A repo is assembled from PACKS: one core (this
  template — the shapes, tracked in .template.lock) plus any number of optional packs
  (declared in packs.yaml, each with its own pack.yaml). `derive` turns a fresh
  copy/clone of the core into a workflow repo. `add`/`remove` install and uninstall a
  pack. `update` pulls the core and every pack forward. `list` shows what is installed.
  `--check` reports versions. `--audit` checks composition integrity offline. Use when
  asked to derive a new workflow repo, to add or drop a pack, to sync a repo's managed
  paths, to check whether anything is behind, or to pin/unpin.
---

@../../../.agents/skills/workflow-template-sync/SKILL.md
