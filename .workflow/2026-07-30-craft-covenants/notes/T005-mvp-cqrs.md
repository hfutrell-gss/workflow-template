# T005 evidence — MVP Model CQRS[/ES]

Created `../../../../.agents/skills/craft-code-quality/references/mvp-cqrs.md` as an on-demand
`craft-code-quality` reference.

## Acceptance evidence

- Requires command and query paths to be explicitly separate at the Model's
  application/use-case boundary.
- Allows ordinary methods, handlers, or use-case types; explicitly rejects mandatory mediator
  frameworks, distinct read/write databases, microservices, event buses, and distributed
  topology.
- Makes CQRS without event sourcing the default.
- Limits event sourcing to explicit domain drivers: temporal history, auditability, replay, or
  event-native invariants; names its operational contract and rejects generic "flexibility" as
  justification.
