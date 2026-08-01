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

- [x] T001 · fleet · deps:- · Survey stewardship for v37 convergence blockers
      evidence: notes/T001-stewardship.md — v17, upstream v37, not pinned, tree clean on main.
                AGENTS.md has no `@AGENTS.CORE.md` import at all (only prose about it), so the
                v37 chain needs a hand-edit. craft-* references dangle at
                .agents/orchestrate/roster.local.yaml:21-25 and orchestrate.local.md:85 (both
                unmanaged). FOUR legacy .workflow/ sessions, all in flight: 10/7, 13/8, 30/20,
                17/9 open. No skill-name collisions. `.agents/craft/` overlay slot is empty.
                CORRECTED by the orchestrator: the worker's claim that update DELETES craft-*
                and workflow-gateway is wrong — see the Log entry on the update bootstrap.
      accept: notes/T001-stewardship.md states, with file:line or command output for each —
              current template_version and upstream URL; `template-sync.sh --check` output;
              every `craft-*` path present; whether AGENTS.md imports AGENTS.CORE.md and what
              CLAUDE.md imports; every legacy `.workflow/<slug>/` session and its open/closed
              state; working-tree cleanliness; whether the repo declares any local skill whose
              name a v37 prefix would collide with.
- [x] T002 · fleet · deps:- · Survey workflow-monolith for v37 convergence blockers
      evidence: notes/T002-monolith.md — v19, tree has one uncommitted README.md change (no
                path overlap with the managed set). AGENTS.md carries no `@` imports at all;
                needs the same hand-edit. Dangling craft-*/gateway references at AGENTS.md:76-81
                and README.md:64-88. `.workflow/` empty, `workflows/` absent. No collisions.
                Repo is still explicitly unfinished (AGENTS.md placeholders, `standing: []`) —
                an update does not change that. Same orchestrator correction as T001 applies.
      accept: notes/T002-monolith.md, same checklist as T001, plus the one uncommitted
              README.md change identified (what it is, whether it must be committed first).
- [x] T003 · fleet · deps:- · Survey sandbox for v37 convergence blockers
      evidence: notes/T003-sandbox.md — v13, `--check` exit 1 (behind), tree clean, NO REMOTE
                configured. No craft-* present anywhere. `workflow-gateway` present and dropped
                by v37. Same AGENTS-chain hand-edit needed. Derivation-owned content is small:
                ~44-line AGENTS.md, one binds.yaml entry, empty journal, boilerplate playbooks.
                Worker recommended re-derive over update; orchestrator overruled — see Log.
      accept: notes/T003-sandbox.md, same checklist as T001, plus an explicit read on whether
              13→37 update is viable or the repo is better re-derived — evidence either way.
- [x] T004 · fleet · deps:- · Verify pack-code-craft is reachable and audit what it claims
      evidence: notes/T004-pack.md — 4 clone forms tried with literal output; only
                `github-personal:henningfutrell/pack-code-craft.git` succeeds (exit 0).
                pack `code-craft` v2, requires_core 30 (core is 37). 8 claimed paths, all
                inside the allowed shapes. `template-sync.sh scan` = "no findings", exit 0;
                zero executable files in the tree. Ships code-craft-{tdd,quality,
                event-naming,ubiquitous-language}. Orchestrator re-verified `gh auth status`
                and ~/.ssh/config independently.
      accept: notes/T004-pack.md gives the exact clone URL that works from this machine (the
              `gh` account is `henningfutrell`, the `github-gss` SSH alias is `hfutrell-gss` —
              say which key reaches it), the pack's `pack.yaml` version and full `provides:`
              list, and `template-sync.sh scan` findings against it. No install here.
- [~] T005 · fleet · deps:T002,T004 · Converge workflow-monolith to v37
      agent: fleet/sonnet (dispatched 16:39)
      method: BOOTSTRAP FIRST — copy the v37 `.agents/skills/workflow-template-sync/` (both
              template-sync.sh and pack-scan.sh) into the derivation BEFORE running update,
              while its manifest is still the old one. Only then does `update` compute the
              dropped-path set correctly and remove `workflow-gateway` and `craft-*` instead
              of orphaning them. Verify no orphan survives.
      accept: `.template.lock` reads 37; `template-sync.sh --check` reports no drift;
              `check.sh` and `orchestrate.sh check` both clean; AGENTS chain is
              CLAUDE.md→AGENTS.md→AGENTS.CORE.md→VOICE.md; committed with /usr/bin/git.
- [~] T006 · workhorse · deps:T001,T004 · Converge stewardship to v37
      agent: workhorse/opus (dispatched 16:39)
      method: same BOOTSTRAP FIRST step as T005. Additionally: the craft-* references in the
              unmanaged overlays (.agents/orchestrate/roster.local.yaml:21-25,
              orchestrate.local.md:85) are renamed to the pack's `code-craft-*` names, not
              deleted — the doctrine is not being dropped, it is being re-sourced from the pack.
      accept: same as T005, plus all four legacy `.workflow/<slug>/` sessions still resolve
              through `orchestrate.sh list` (each with its legacy NOTE), no task marker in any
              of them altered, craft-* skill names inside those task lists re-pointed to the
              pack's names, and what a migration to the new layout would require reported.
      revised: the original accept demanded each legacy session be migrated or closed in this
              task. Wrong scope, corrected before dispatch: naming the workflow and app for four
              in-flight sessions holding 44 open tasks is per-session judgment and the user's
              call, not a side effect of a core bump. Migration is carried out to ../tasks.md at
              harvest rather than done here.
- [~] T007 · fleet · deps:T003,T004 · Converge sandbox to v37
      agent: fleet/sonnet (dispatched 16:39)
      method: same BOOTSTRAP FIRST step as T005, which is what makes 13 -> 37 viable and
              retires the worker's re-derive recommendation (Log). No craft-* to handle here;
              `workflow-gateway` is the path being dropped.
      accept: same as T005, except: no remote is configured, so the push clause does not apply
              and the commit is local by definition.
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
- [ ] T012 · workhorse · deps:T005,T006,T007 · Promote the update-bootstrap defect into the core
      accept: the core (this repo) states the ordering constraint where an operator will hit it
              — `.agents/skills/workflow-template-sync/SKILL.md` and, if the shape allows,
              handled in `template-sync.sh` itself rather than documented around. The defect:
              a derivation runs its OWN copy of template-sync.sh, so a pre-v37 derivation's
              first update uses a script that cannot compute dropped paths, silently orphaning
              every path the new manifest retired. Passes the four-part promotion test in
              `workflows/upstream-workflow-management/SKILL.md` before any edit; if it fails
              one, that is the finding and the task records which. VERSION and
              template-manifest.yaml bumped together per that skill's step 3.
- [x] T011 · fleet · deps:T004 · Correct the recorded pack-code-craft clone URL in the core
      evidence: journal/2026-08-01-code-craft-published.md now carries a dated
                "## Correction — 2026-08-01, under T004" section, original text intact above it.
                Orchestrator read the appended section directly: it states the working
                `ssh://github-personal/...` URL, that the repo is private, the identity that
                reaches it, the is_url_upstream scp-form caveat with the file:line, the
                corrected `gh` account, and the CI provisioning consequence.
      accept: `journal/2026-08-01-code-craft-published.md` states the URL that actually works
              (`github-personal:henningfutrell/pack-code-craft.git`), that the repo is
              PRIVATE, and which SSH identity reaches it — correcting the entry's claims that
              the URL is `git@github.com:henningfutrell/pack-code-craft` and that `gh` is
              authenticated as `henningfutrell` (it is `hfutrell-gss`). The correction is
              additive: the original entry is a dated record and is not rewritten to look
              like it was right.
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
- **The update bootstrap — two workers wrong the same way, corrected by direct reading.**
  T001 and T002 both reported that `update` DELETES the retired `craft-*` and
  `workflow-gateway` paths. It does not. A derivation runs its OWN copy of
  `template-sync.sh`, and the pre-v37 copy (`copy_managed_paths`, v17 script lines 135-151)
  only copies paths listed in the NEW manifest — it never computes the set the new manifest
  dropped. v37 added exactly that (`update_core` → `comm -23 old new` → `remove_paths`,
  lines 453-462). So a naive first update leaves the retired paths ORPHANED on disk and then
  writes `template_version: 37`, after which every later `update` reports "up to date" and
  the cleanup never runs. Both workers reasoned from the v37 manifest's own comment ("A path
  REMOVED from this list is deleted from every derivation on its next update"), which is true
  of the v37 script and false of the script that actually executes the v19→v37 hop.
  **Fix, applied to all three convergences:** copy the v37 `workflow-template-sync` skill dir
  into the derivation BEFORE running update, while the derivation's manifest is still the old
  one. `gone` then computes against the correct `old` and the retired paths are removed.
- **Sandbox: update, not re-derive — orchestrator overrode the worker.** T003 recommended
  re-deriving because (a) v13's script has no packs support and (b) it cannot delete dropped
  paths. The bootstrap fix above retires both: the script is replaced before it is used. What
  remained of the recommendation was that sandbox owns little — true, but not a reason to
  discard its git history when a working update path exists. The AGENTS-chain hand-edit is
  needed on either path, so it does not discriminate.
- **Stewardship converges with live work in it.** Four legacy `.workflow/` sessions are in
  flight (44 open tasks total). Not deferred: v37 keeps the `.workflow/<slug>/` fallback for
  exactly ONE version, so this is the migration window and waiting makes the hop worse. The
  open tasks that mandate `/craft-tdd` and `/craft-code-quality` keep their meaning — the
  overlays are renamed to the pack's `code-craft-*` names, and the doctrine arrives from the
  pack rather than the core.
- **The pack is private, and reachable by one identity only.** `code-craft` v2 lives at
  `github-personal:henningfutrell/pack-code-craft.git`. Neither `gh` (authenticated as
  `hfutrell-gss`, not `henningfutrell` as this repo's own journal claims) nor the `github-gss`
  alias can reach it. Any machine or CI that later runs `update` needs the `github-personal`
  key provisioned, or the pack silently stops updating. T011 corrects the record.
- **Init was stale.** `init.lock` v5 vs required v6 — `/workflow-init` run before any other
  work, per the constitution's mandatory first check. v6 dropped `opencodex` (v37 removed the
  gateway from the core). Standing warning, unchanged: `git` is aliased to a Windows binary at
  `/home/henning/.zshenv:39`; `/usr/bin/git` explicitly, always.
