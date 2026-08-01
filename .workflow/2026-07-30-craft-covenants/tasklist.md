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

- [x] T001 · fleet · deps:- · Define the 90/90 coverage destination scope
      accept: reference states line+branch 90/90 for authored non-UI production code; lists included layers, exclusions (UI, generated, migrations, declarative glue), and denominator rules
      evidence: references/coverage-destination.md — 90/90 line+branch; domain/app/adapters included; UI/generated/migrations/schemas/glue excluded; day-one + exit + monotone floors; notes/T001-coverage-destination.md
- [x] T002 · fleet · deps:T001 · Strengthen coverage ratchet to match destination
      accept: ratchet.md + related body text require changed-code 90/90 day one, non-decreasing overall floors, and 90/90 as repo-wide exit for non-UI — consistent with T001
      evidence: ratchet.md Coverage section cites coverage-destination.md; day-one 90/90; monotone floors; non-UI exit; notes/T002-ratchet.md
- [x] T003 · fleet · deps:- · Codify UI view-model vs domain-model boundaries
      accept: on-demand reference states view-model ownership in UI, domain models in core, explicit translation, forbid domain leakage into UI contracts; business rules out of views/presenters/controllers
      evidence: references/ui-model-boundary.md — VM vs domain ownership, explicit mappers, ENFORCED/PARTIAL/REVIEW table; notes/T003-ui-model-boundary.md
- [x] T004 · fleet · deps:- · Codify repository covenants
      accept: reference defines repositories as persistence ports when aggregate storage/query warrants them; forbids mandatory generic CRUD wrappers; places adapters correctly
      evidence: references/repositories.md — ports when warranted, no IRepository<T> ceremony, adapters + banned symbols; notes/T004-repositories.md
- [x] T005 · fleet · deps:- · Define MVP Model CQRS[/ES] doctrine
      accept: on-demand reference requires command/query separation at application/use-case boundary without mandating a mediator framework; ES is opt-in with explicit domain criteria
      evidence: references/mvp-cqrs.md — lightweight CQRS at use-case boundary; ES opt-in criteria; no mediator mandate; notes/T005-mvp-cqrs.md
- [x] T006 · fleet · deps:T001,T003,T004,T005 · Update enforcement classifications for new covenants
      accept: every new covenant in enforcement.md is ENFORCED, PARTIAL, or REVIEW with honest tool mapping; no overstated automation
      evidence: enforcement.md rows for coverage, UI, repos, CQRS/ES; notes/T006-enforcement.md
- [x] T007 · fleet · deps:T003,T004 · Strengthen architecture-test examples for UI/domain/persistence
      accept: at least one supported-stack arch-test asset demonstrably encodes forbidden UI↔domain or domain↔persistence dependency; README notes how to prove it fails
      evidence: ui-must-not-depend-on-domain in dependency-cruiser + README canary; notes/T007-arch-tests.md
- [x] T008 · fleet · deps:T001,T003 · Synchronize craft-tdd with coverage and UI flags
      accept: craft-tdd SKILL.md agrees with 90/90 scope/gates and sharpens logic-in-UI CODE FLAG to match T003
      evidence: craft-tdd Coverage covenant + sharpened UI CODE FLAG; notes/T008-craft-tdd.md
- [x] T009 · fleet · deps:T001,T002,T003,T004,T005,T006 · Wire new refs into craft-code-quality SKILL body
      accept: SKILL.md links the new/updated refs; standing expectation that every production-code turn holds the ratchet and reports the gap; no new skill invented
      evidence: SKILL.md refs table + standing 90/90 expectation + architecture pointers; notes/T009-skill-body.md
- [x] T010 · fleet · deps:T007,T008,T009 · Package managed release (VERSION + manifest)
      accept: VERSION bumped; template-manifest.yaml version mirrors it; managed paths cover all new files; derivation-owned AGENTS.md unchanged; orchestrate.sh status clean after task markers updated
      evidence: VERSION=18; template-manifest version:18; craft-code-quality/** covers new refs; AGENTS.md untouched; notes/T010-release.md

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
- 2026-07-30: verified T001 ([coverage](dfa21372-88eb-43f5-9d38-a3c92e5eda6c)); also verified
  T003–T005 deliverables already on disk from concurrent fleet; marked [x]. Dispatched
  T002,T006,T007,T008.
- 2026-07-30: verified T002 ([ratchet](b91d62ce-c875-4c21-b591-5ef2f5acc25e)),
  T006 ([enforcement](7475181f-ed24-480a-b3b3-8d2fd3ee7cfa)),
  T007 ([arch-tests](fbceb2b0-c27c-4eb7-a7e5-95f1a07ab50b)),
  T008 ([craft-tdd](5fb212c8-90e7-4f73-885b-5d20b97d0aa4)). Late T003/T004/T005
  completion notices acknowledged (already [x]). Dispatched T009.
- 2026-07-30: verified T009 ([skill-body](64bf59b4-685e-4f88-bcc0-03568af4dee1)). Dispatched T010.
- 2026-07-30: verified T010 ([release](435721ff-3f5e-4149-ac43-8c89caa02f93)) — VERSION 18.
  Session exhausted.
- 2026-07-31: retroactive harvest record (T005, the run-layout task). This session
  predates the harvest gate; its output already shipped at session-close time — the
  craft-tdd/craft-code-quality thickening and the CQRS refs landed as VERSION 18's
  managed set, and `journal/2026-07-30-craft-covenants.md` carries the narrative. No
  further sweep needed.

## Harvest

<!-- Required before this run can close. Sweep notes/ and decisions into (a) the
     procedure workflows/<workflow>/ if a way-of-working stabilized, (b) the target
     repo's own docs if the knowledge is the target's, (c) the journal if it is
     narrative. Then record where, and the instance directory may be deleted — it is
     committed, so git log is the archive; no graveyard directory is kept. -->

harvest: done shipped as VERSION 18 managed craft-tdd/craft-code-quality assets; narrative in journal/2026-07-30-craft-covenants.md
