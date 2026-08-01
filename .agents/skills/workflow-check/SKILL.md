---
name: workflow-check
description: Run every organizational constraint this repo declares in one pass — tooling, canonical file format, workflow/application/session layout, task grammar, template drift, and pack composition integrity — and return one verdict with rule IDs. Use when checking whether the repo is in a conforming state, before or after a large restructuring, when a session closes, when something feels out of place but you cannot name which rule it breaks, or when adding a new organizational constraint and needing to know where it belongs.
---

# workflow-check

One command for every structural constraint this system declares.

```sh
.agents/skills/workflow-check/check.sh          # report
.agents/skills/workflow-check/check.sh --fix    # report, and let agents-sync repair
```

`--fix` is passed to `/workflow-agents-sync` alone — the one owner with a safe repair
(create a missing bridge or skill stub from its canonical file). Every other owner runs
in report mode either way, so `--fix` never changes what the other families report.

Exit `0` all clear · `2` constraints unmet · `1` a checker could not run.

**Exit 2 is an ordinary result.** It means a rule is unmet and was reported. Only exit 1
is a defect, and it is a defect in the tooling, not in the repo.

## What it owns

Nothing. Each skill owns the constraints for the shapes it defines — the categorical rule
applied to enforcement. This dispatches to them and aggregates one verdict.

| Prefix | Owner | Domain |
|--------|-------|--------|
| `TOOL-*` | `/workflow-init` | per-machine tooling, `init.lock` |
| `AGENTS-*` | `/workflow-agents-sync` | canonical file format, bridges, stubs, glossary slot |
| `LAYOUT-*` | `/workflow-orchestrate` | workflow, application, and session directory shape |
| `TASK-*` | `/workflow-orchestrate` | task grammar and anti-cheat inside each session |
| `SUBSTRATE-*` | `/workflow-orchestrate` | session identifiers escaping into bound substrate |
| `TEMPLATE-*` | `/workflow-template-sync` | core and pack version drift against upstream |
| `PACK-*` | `/workflow-template-sync` | composition integrity: path ownership, installed state, overlay slots |

Every rule, with its statement and why it matters: `references/constraints.md`. Cite the
ID — `LAYOUT-007`, `AGENTS-003` — and a reader can look up exactly what was broken.

## When to run it

- **After any restructuring.** This is the pass that catches what the change forgot.
- **When a session closes.** `LAYOUT-007` is the harvest law made mechanical: a session
  that is exhausted and harvested must not still be on disk.
- **Before promoting anything upstream.** `/upstream-workflow-management` step 4.
- **On a cold start in an unfamiliar derivation**, to learn its state in one command.

## Adding a constraint

Implement it in the skill that owns the shape, register it in
`references/constraints.md`, and do not touch `check.sh`. The aggregator dispatches; it
never checks. Full procedure — including the test for whether a constraint is worth
adding at all — in that file.
