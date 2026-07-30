# Flagship intake — craft covenants

Consultant: gpt-5.6-sol via generalPurpose (agent id 07d97d24-6003-4905-a8f1-dd595aa1ef7e).
Date: 2026-07-30.

## Adopted decisions

1. Thicken `craft-code-quality` + `craft-tdd`; on-demand modeling/CQRS reference — **no new skill**.
2. 90% line / 90% branch on authored **non-UI** production code (domain, application, meaningful backend adapters). Day-one **changed-code** gate + repo-wide **exit** criterion. Overall floors never drop.
3. Sharp UI/domain boundaries; repositories conditional (ports, not generic CRUD). Enforce dependency direction; semantic placement stays REVIEW/PARTIAL.
4. Lightweight CQRS at Model application boundary; ES opt-in when domain warrants. No mediator/microservices mandate.
5. Managed craft assets + VERSION only; **do not** rewrite template `AGENTS.md`.

## Excludes (binding for this run)

UI from 90/90 covenant; generated/migration/declarative glue; mandatory repos/ES/framework CQRS; rewriting AGENTS.md; broad skill reorganization.
