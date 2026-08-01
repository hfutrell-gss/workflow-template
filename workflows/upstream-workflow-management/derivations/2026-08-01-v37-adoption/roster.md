# Resolved roster: upstream-workflow-management · derivations

Resolved 2026-08-01. Authoritative for this run, including cold continuations — a resumed run
reuses these rather than re-deciding. Resolution order and the `prefer:` schema:
`.agents/skills/workflow-orchestrate/references/model-classes.md`.

No `.agents/orchestrate/roster.local.yaml` in this repo (only the `.example`), so resolution
fell through to the seed roster, filtered by runtime discovery: the `Agent` tool's `model`
enum in this session is `sonnet | opus | haiku | fable`. Native lane only — the core ships no
routed lane, and v37 removed the gateway from the core.

| tier | lane | dispatch | handle |
|------|------|----------|--------|
| flagship | anthropic | `model:` | `fable` |
| workhorse | anthropic | `model:` | `opus` |
| fleet | anthropic | `model:` | `sonnet` (`haiku` for mechanical slices) |

## Roles

| role | tier |
|------|------|
| consultant | flagship |
| orchestrator | workhorse |
| worker | fleet |

## Substitutions and unavailable lanes

None. Every tier filled from the first (and only) preferred lane.

Routed `ocx-*` agent types are present in this session's agent list, but no overlay declares
them as a lane, so they are not dispatchable under this roster.
