---
name: workflow-plugins
description: >-
  The registry for optional capability a workflow repo consumes as a Claude Code PLUGIN
  rather than as a pack: which plugins this repo wants, why, what a review of each one
  found, and which ones a given user has declined. Declares the shared default set in
  plugins.yaml, renders it into .claude/settings.json, and records a per-user opt-out with
  its reason. Use when adding or removing a plugin, when deciding whether something should
  be a plugin or a pack, when a user wants to decline a plugin the repo enables, or when a
  skill that should exist does not resolve.
---

@../../../.agents/skills/workflow-plugins/SKILL.md
