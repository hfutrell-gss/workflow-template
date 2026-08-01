# Session: upstream-workflow-management · derivations · 2026-08-01-v37-adoption

Opened 2026-08-01. Grammar, anti-cheat rules, and the harvest gate:
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

> I updated the prior upstream workflow-template and I want us to use that. It moves to
> using plugin packs and such. Look for the /workflow-orchestrate skill and use that

Answers given to the three scoping questions, verbatim options selected:

- Upstream: **"Push personal/main → org origin"**
- Scope: **"stewardship (v17), workflow-monolith (v19), sandbox (v13)"**
- Session home: **"workflow-template"**

## Goal

Every workflow repo on this machine runs the v37 core — composed, checked, and committed —
with `code-craft` installed where the derivation wants the engineering doctrine the core
dropped. Excludes: authoring new doctrine, any work on substrate the derivations steward,
and pushing derivations to their remotes (user's call, raised at close).

## Definition of Done

Task list exhaustion **and** harvest: no `[ ]`, `[~]`, or `[!]` remains,
`orchestrate.sh status` reports zero violations, and `## Harvest` below reads
`harvest: done <where it went>`. `[-]` requires `why:` and a user `signoff:`.

Closing is `orchestrate.sh close`. It re-checks this DoD, writes the ledger line into
`../tasks.md` `## History`, and deletes this directory in one step.

## Tasks

- [~] T001 · fleet · deps:- · Survey stewardship for v37 convergence blockers
      agent: fleet/sonnet (dispatched 16:33)
      accept: notes/T001-stewardship.md states, with file:line or command output for each —
              current template_version and upstream URL; `template-sync.sh --check` output;
              every `craft-*` path present; whether AGENTS.md imports AGENTS.CORE.md and what
              CLAUDE.md imports; every legacy `.workflow/<slug>/` session and its open/closed
              state; working-tree cleanliness; whether the repo declares any local skill whose
              name a v37 prefix would collide with.
- [~] T002 · fleet · deps:- · Survey workflow-monolith for v37 convergence blockers
      agent: fleet/sonnet (dispatched 16:33)
      accept: notes/T002-monolith.md, same checklist as T001, plus the one uncommitted
              README.md change identified (what it is, whether it must be committed first).
- [~] T003 · fleet · deps:- · Survey sandbox for v37 convergence blockers
      agent: fleet/sonnet (dispatched 16:33)
      accept: notes/T003-sandbox.md, same checklist as T001, plus an explicit read on whether
              13→37 update is viable or the repo is better re-derived — evidence either way.
- [~] T004 · fleet · deps:- · Verify pack-code-craft is reachable and audit what it claims
      agent: fleet/sonnet (dispatched 16:33)
      accept: notes/T004-pack.md gives the exact clone URL that works from this machine (the
              `gh` account is `henningfutrell`, the `github-gss` SSH alias is `hfutrell-gss` —
              say which key reaches it), the pack's `pack.yaml` version and full `provides:`
              list, and `template-sync.sh scan` findings against it. No install here.
- [ ] T005 · fleet · deps:T002,T004 · Converge workflow-monolith to v37
      accept: `.template.lock` reads 37; `template-sync.sh --check` reports no drift;
              `check.sh` and `orchestrate.sh check` both clean; AGENTS chain is
              CLAUDE.md→AGENTS.md→AGENTS.CORE.md→VOICE.md; committed with /usr/bin/git.
- [ ] T006 · workhorse · deps:T001,T004 · Converge stewardship to v37
      accept: same as T005, plus every legacy `.workflow/<slug>/` session either migrated to
              `workflows/<workflow>/<app>/<session>/` or closed through `orchestrate.sh close`
              — never deleted by hand — and `orchestrate.sh list` shows no stranded run.
- [ ] T007 · fleet · deps:T003,T004 · Converge sandbox to v37
      accept: same as T005. If T003 found update non-viable, this task blocks rather than
              re-deriving — re-derivation is a separate decision with a signoff.
- [ ] T008 · fleet · deps:T005,T006,T007 · Update ~/.claude/skills/wf/SKILL.md to the v37 model
      accept: the file names packs and `template-sync.sh add/remove/list`, the four-level
              `workflows/<workflow>/<app>/<session>/` layout, `/workflow-check`, and the
              `code-craft` pack; no surviving reference to `craft-*`, `.workflow/`,
              `playbooks/`, or the removed gateway; every repo URL and path in it verified
              against disk.
- [ ] T009 · fleet · deps:T005,T006,T007 · Verify all three derivations under the v37 checks
      accept: notes/T009-verify.md carries, per repo, the literal output of `check.sh`,
              `orchestrate.sh check`, `agents-sync.sh`, and `template-sync.sh --check --audit`;
              any non-clean result named as a finding rather than summarized as pass.
- [ ] T010 · workhorse · deps:T009 · Write the derivations application profile
      accept: `../profile.md` records each derivation — path, remote, template_version,
              packs installed, what it stewards — and every claim that can decay carries the
              trigger that invalidates it, per the profile template's own rule.

## Harvest

<!-- Required before this run can close. Sweep notes/ and decisions out to their
     destinations per AGENTS.CORE.md "Harvest law": a way of working that stabilized to
     workflows/upstream-workflow-management/, understanding of derivations to its own docs or ../profile.md,
     unfinished work still wanted to ../tasks.md ## Open, a refusal or de-scope to the
     stewarded repo's docs or ../profile.md with its signoff.
     Then record where each output landed on the harvest: line below, and run
     `orchestrate.sh close`. It re-checks the DoD, writes the ledger line into
     ../tasks.md ## History, and deletes this directory in one step. Never delete a
     session directory by hand. -->

harvest: pending

## Log

- **App modeling, decided by the orchestrator.** The managed `upstream-workflow-management`
  workflow declares its application as `self`. This run acts from the core's seat on three
  *downstream* repos, so it opens a second application, `derivations`, under the same
  workflow. Rejected alternative: a new workflow (`derivation-convergence`) — `derive` keeps
  `workflows/<workflow>/SKILL.md` as TIMELESS, so a new workflow in the core ships into every
  future derivation while sitting in no manifest, i.e. inherited and unmaintained. If the
  `self`-only wording in that skill is wrong, it is a promotion candidate at harvest.
- **Core moved twice mid-run.** Local `main` was fast-forwarded v19→v36 and pushed to
  `origin`; `personal/main` had already advanced to v37 (`c53f201`) by the time that push
  landed, so it was fast-forwarded again and re-pushed. `origin` and `personal` are both at
  `c53f201` = v37. Derivations therefore converge on 37, not 36.
- **Init was stale.** `init.lock` v5 vs required v6 — `/workflow-init` run before any other
  work, per the constitution's mandatory first check. v6 dropped `opencodex` (v37 removed the
  gateway from the core). Standing warning, unchanged: `git` is aliased to a Windows binary at
  `/home/henning/.zshenv:39`; `/usr/bin/git` explicitly, always.
