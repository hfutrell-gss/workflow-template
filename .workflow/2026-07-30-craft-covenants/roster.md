# Resolved roster: 2026-07-30-craft-covenants

Resolved 2026-07-30. Authoritative for this session, including cold continuations — a resumed run
reuses these rather than re-deciding. Resolution order and the `prefer:` schema:
`.agents/skills/workflow-orchestrate/references/model-classes.md`.

| tier | lane | dispatch | handle |
|------|------|----------|--------|
| flagship | ocx-openai (via Cursor Task) | `model:` on generalPurpose | gpt-5.6-sol-medium |
| workhorse | anthropic (Cursor native) | `model:` | claude-opus-5-thinking-high |
| fleet | ocx-openai (via Cursor Task) | `model:` on generalPurpose | gpt-5.6-terra-medium (cheap: composer-2.5-fast) |

## Roles

| role | tier |
|------|------|
| consultant | flagship |
| orchestrator | workhorse |
| worker | fleet |

## Substitutions and unavailable lanes

- No `.agents/orchestrate/roster.local.yaml` present — used seed + discovery.
- Seed prefers `flagship: [anthropic, ocx-openai]`. Native Anthropic flagship handle
  `fable` is **not** in this Cursor harness's Task `model` enum. `subagent_type: ocx-*`
  rejected by Task enum in this session — dispatch routed models via
  `generalPurpose` + `model: gpt-5.6-*-medium` instead. Gateway up
  (`ocx models live` lists gpt-5.6-sol/terra/luna).
- Flagship consultation used `gpt-5.6-sol-medium` successfully.
- Fleet: `gpt-5.6-terra-medium` for doctrine drafting; `composer-2.5-fast` only for
  mechanical packaging.
- Workhorse: orchestrator role runs in this parent session.
