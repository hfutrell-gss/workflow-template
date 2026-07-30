# T010 — managed release

- `VERSION`: `17` → `18` (plain integer with one trailing newline).
- `template-manifest.yaml`: `version: 18`, matching `VERSION`.
- The manifest already manages `.agents/skills/craft-code-quality/**`; its glob covers the
  new reference assets without additional entries:
  - `.agents/skills/craft-code-quality/references/coverage-destination.md`
  - `.agents/skills/craft-code-quality/references/ui-model-boundary.md`
  - `.agents/skills/craft-code-quality/references/repositories.md`
  - `.agents/skills/craft-code-quality/references/mvp-cqrs.md`
- `git diff -- AGENTS.md` produced no output; derivation-owned `AGENTS.md` remains untouched.
- `orchestrate.sh status 2026-07-30-craft-covenants` reports nine done tasks and one
  in-flight task (T010), so `DoD: NOT EXHAUSTED (1 open)` is expected until the
  orchestrator updates its marker.
