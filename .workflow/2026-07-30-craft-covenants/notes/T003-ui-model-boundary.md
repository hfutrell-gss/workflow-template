# T003 evidence — UI model boundary

## Delivered

- Added `.agents/skills/craft-code-quality/references/ui-model-boundary.md`.
- Kept `SKILL.md`, architecture-test assets, existing references, and VERSION unchanged.

## Acceptance evidence

- UI owns presentation-shaped view models; core/domain owns data/domain models.
- Boundary translation is explicit through mappers or DTO adapters.
- Domain models are forbidden as UI contracts, including props, UI state, presenter outputs,
  controller responses consumed by UI, route payloads, and boundary-bypassing shared packages.
- Business policy is forbidden in views, presenters, controllers, and UI-state containers;
  extracting it is integral work.
- The reference aligns the mandatory UI API boundary with ports/adapters and DDD.
- Dependency direction and UI imports of domain types are ENFORCED; semantic business-logic
  placement is REVIEW; UI-owned contract checking is PARTIAL. Every machine rule requires a
  failing canary before trust.
