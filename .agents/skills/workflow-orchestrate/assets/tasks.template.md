# Session: __WORKFLOW__ · __APP__ · __SESSION__

Opened __DATE__. Grammar, anti-cheat rules, and the harvest gate:
`.agents/skills/workflow-orchestrate/references/tasklist.md`.

This directory is SESSION state — deleted after harvest, by definition. Anything here
that should outlive this session has somewhere else to go. `AGENTS.CORE.md` "Harvest
law" is the full list of destinations; read it there. Two apply while the run is live:

- **Work not finished, still wanted** → `../tasks.md` `## Open`. Mark the task `[^]`
  and give it a `carried:` line naming its entry there.
- **A decision to refuse or de-scope work** → the stewarded repo's own docs, or
  `../profile.md`. It travels with its `signoff:`, and `landed:` names where it went.

Work that cannot finish is **promoted, not stalled**. `[^]` is not open, so this
session can close with the work preserved.

## Directive

<!-- VERBATIM, as received. A paraphrase loses the DoD. -->

## Goal

<!-- One or two lines: what this run achieves, and what it deliberately excludes. -->

## Definition of Done

Task list exhaustion **and** harvest: no `[ ]`, `[~]`, or `[!]` remains,
`orchestrate.sh status` reports zero violations, and `## Harvest` below reads
`harvest: done <where it went>`. `[-]` requires `why:` and a user `signoff:`.

Closing is `orchestrate.sh close`. It re-checks this DoD, writes the ledger line into
`../tasks.md` `## History`, and deletes this directory in one step.

## Tasks

<!-- - [<marker>] <ID> · <tier> · deps:<deps> · <title>
           accept:   <the acceptance test — required on every task>
           evidence: <required for [x]>
           agent:    <required for [~]>
           blocked:  <required for [!]>
           why:      <required for [-]>
           signoff:  <required for [-]>
           carried:  <required for [^] — names its entry in ../tasks.md ## Open>
           landed:   <required for [-] and [^] once harvest reads done — where the
                      rationale went: a stewarded repo's own docs, ../profile.md, or
                      "disposable — <reason>">
     Markers: [ ] pending · [~] in flight · [x] done · [!] blocked · [^] carried · [-] dropped
     Tiers:   flagship · workhorse · fleet   (never a model name) -->

## Harvest

<!-- Required before this run can close. Sweep notes/ and decisions out to their
     destinations per AGENTS.CORE.md "Harvest law": a way of working that stabilized to
     workflows/__WORKFLOW__/, understanding of __APP__ to its own docs or ../profile.md,
     unfinished work still wanted to ../tasks.md ## Open, a refusal or de-scope to the
     stewarded repo's docs or ../profile.md with its signoff.
     Then record where each output landed on the harvest: line below, and run
     `orchestrate.sh close`. It re-checks the DoD, writes the ledger line into
     ../tasks.md ## History, and deletes this directory in one step. Never delete a
     session directory by hand. -->

harvest: pending

## Log

<!-- Decisions worth surviving a cold tick: forks resolved, consultations, lane
     substitutions, work deliberately deferred to another session. -->
