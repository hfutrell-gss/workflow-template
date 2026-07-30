# Orchestration session: 2026-07-30-craft-covenants

Opened 2026-07-30. Grammar and anti-cheat rules:
`.agents/skills/workflow-orchestrate/references/tasklist.md`.

## Directive

Anyway, now we want to start baking in some covenants and expectations. Things like 90/90
coverage, static analysis setup, stuff like that. The core expectation of the workflow is to
get to that. Ie, part of the ratchet is to always work towards this. Non-ui code of course.
Finding the distinction, and carving all pieces of business logic out of the UI is integral.
The UI should maintain its own view models, the business logic should carry its own data
models, and the backend should use repositories where it makes sense. The goal is MVP. M
should be implemented via CQRS and potentially CQRS/ES where the business model makes sense.

This can be captured through skills and whatever makes sense

## Goal

Bake durable craft covenants into managed template assets so every derivation inherits:
90/90 line/branch as non-UI destination + day-one changed-code gate; sharp UI view-model /
domain-model / repository boundaries; MVP Model via lightweight CQRS with ES opt-in; every
covenant classified ENFORCED/PARTIAL/REVIEW. Leave derivation-owned `AGENTS.md` untouched.

## Definition of Done

Task list exhaustion: no `[ ]`, `[~]`, or `[!]` remains, and `orchestrate.sh status` reports
zero violations. `[-]` requires `why:` and a user `signoff:`.

## Tasks

- [~] T001 · fleet · deps:- · Define the 90/90 coverage destination scope
      accept: reference states line+branch 90/90 for authored non-UI production code; lists included layers, exclusions (UI, generated, migrations, declarative glue), and denominator rules
      agent: fleet-T001 (dispatched 2026-07-30)
- [ ] T002 · fleet · deps:T001 · Strengthen coverage ratchet to match destination
      accept: ratchet.md + related body text require changed-code 90/90 day one, non-decreasing overall floors, and 90/90 as repo-wide exit for non-UI — consistent with T001
- [~] T003 · fleet · deps:- · Codify UI view-model vs domain-model boundaries
      accept: on-demand reference states view-model ownership in UI, domain models in core, explicit translation, forbid domain leakage into UI contracts; business rules out of views/presenters/controllers
      agent: fleet-T003 (dispatched 2026-07-30)
- [~] T004 · fleet · deps:- · Codify repository covenants
      accept: reference defines repositories as persistence ports when aggregate storage/query warrants them; forbids mandatory generic CRUD wrappers; places adapters correctly
      agent: fleet-T004 (dispatched 2026-07-30)
- [~] T005 · fleet · deps:- · Define MVP Model CQRS[/ES] doctrine
      accept: on-demand reference requires command/query separation at application/use-case boundary without mandating a mediator framework; ES is opt-in with explicit domain criteria
      agent: fleet-T005 (dispatched 2026-07-30)
- [ ] T006 · fleet · deps:T001,T003,T004,T005 · Update enforcement classifications for new covenants
      accept: every new covenant in enforcement.md is ENFORCED, PARTIAL, or REVIEW with honest tool mapping; no overstated automation
- [ ] T007 · fleet · deps:T003,T004 · Strengthen architecture-test examples for UI/domain/persistence
      accept: at least one supported-stack arch-test asset demonstrably encodes forbidden UI↔domain or domain↔persistence dependency; README notes how to prove it fails
- [ ] T008 · fleet · deps:T001,T003 · Synchronize craft-tdd with coverage and UI flags
      accept: craft-tdd SKILL.md agrees with 90/90 scope/gates and sharpens logic-in-UI CODE FLAG to match T003
- [ ] T009 · fleet · deps:T001,T002,T003,T004,T005,T006 · Wire new refs into craft-code-quality SKILL body
      accept: SKILL.md links the new/updated refs; standing expectation that every production-code turn holds the ratchet and reports the gap; no new skill invented
- [ ] T010 · fleet · deps:T007,T008,T009 · Package managed release (VERSION + manifest)
      accept: VERSION bumped; template-manifest.yaml version mirrors it; managed paths cover all new files; derivation-owned AGENTS.md unchanged; orchestrate.sh status clean after task markers updated

## Log

- 2026-07-30: session opened. Anthropic flagship (`fable`) unavailable; flagship filled by
  `gpt-5.6-sol` via `generalPurpose` (ocx agentType enum rejected by this harness — recorded
  in roster.md).
- 2026-07-30: flagship intake ([consultant](07d97d24-6003-4905-a8f1-dd595aa1ef7e)). Decisions
  adopted: thicken craft-code-quality + craft-tdd; no new skill; 90/90 line+branch non-UI
  destination + day-one changed-code gate; CQRS lightweight at Model boundary, ES opt-in;
  ship managed assets only; leave AGENTS.md alone. Notes: notes/intake-consultation.md.
- 2026-07-30: decomposed T001–T010; reorganize = write refs in parallel (T001,T003,T004,T005),
  then integrate (T002,T006–T009), then package (T010). No second consult — ordering obvious.
