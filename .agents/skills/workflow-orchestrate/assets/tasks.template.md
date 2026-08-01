# Session: __WORKFLOW__ · __APP__ · __SESSION__

Opened __DATE__. Grammar, anti-cheat rules, and the harvest gate:
`.agents/skills/workflow-orchestrate/references/tasklist.md`.

This directory is SESSION state — deleted after harvest, by definition. Anything here
that should outlive this session has somewhere else to go:

| Output | Goes to |
|--------|---------|
| a stabilized way of working | `workflows/__WORKFLOW__/SKILL.md` or its `references/` |
| understanding of __APP__ | __APP__'s own docs, or `../profile.md` |
| work not finished, still wanted | `../tasks.md` — mark the task `[^]` with a `carried:` line |
| what merely happened | `journal/` |

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

## Tasks

<!-- - [<marker>] <ID> · <tier> · deps:<deps> · <title>
           accept:   <the acceptance test — required on every task>
           evidence: <required for [x]>
           agent:    <required for [~]>
           blocked:  <required for [!]>
           why:      <required for [-]>
           signoff:  <required for [-]>
     Markers: [ ] pending · [~] in flight · [x] done · [!] blocked · [-] dropped
     Tiers:   flagship · workhorse · fleet   (never a model name) -->

## Harvest

<!-- Required before this run can close. Sweep notes/ and decisions into (a) the
     procedure workflows/__WORKFLOW__/ if a way-of-working stabilized, (b) __APP__'s
     own docs if the knowledge is the target's, (c) the journal if it is narrative.
     Then record where, and this directory may be deleted outright — it is committed,
     so git log is the archive; no graveyard directory is kept. -->

harvest: pending

## Log

<!-- Decisions worth surviving a cold tick: forks resolved, consultations, lane
     substitutions, work deliberately deferred to another session. -->
