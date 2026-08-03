# Session: upstream-workflow-management · derivations · 2026-08-01-v37-adoption

Opened 2026-08-01. Grammar, anti-cheat rules, and the reaping gate:
`.agents/skills/workflow-orchestrate/references/tasklist.md`.

This directory is SESSION state — deleted after reaping, by definition. Anything here
that should outlive this session has somewhere else to go. `AGENTS.CORE.md` "Reaping
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

Task list exhaustion **and** reaping: no `[ ]`, `[~]`, or `[!]` remains,
`orchestrate.sh status` reports zero violations, and `## Reaping` below reads
`reaping: done <where it went>`. `[-]` requires `why:` and a user `signoff:`.

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
- [x] T005 · fleet · deps:T002,T004 · Converge workflow-monolith to v37
      evidence: notes/T005-monolith-converge.md; commits 241706c (README alone) and 6719782
                "core: converge v19 -> v37, install code-craft pack". Orchestrator re-verified:
                `.template.lock` = 37; `--check` "up to date" for core AND code-craft;
                `list` shows workflow-core 37 + code-craft 2; `packs.lock` records all 8 pack
                paths; `--audit` silent (exit 0); `check.sh` all five groups ok;
                CLAUDE.md:4 `@AGENTS.md`, AGENTS.md:4 `@AGENTS.CORE.md`; no gateway or
                bare-craft path on disk; tree clean. Worker also closed PACK-005 (missing
                `.agents/code-craft/` overlay dir), a stale init.lock, a missing
                GLOSSARY.local.md, and LAYOUT-001 (empty `.workflow/`).
                Discovered work split out as T013 rather than absorbed here.
      method: BOOTSTRAP FIRST — copy the v37 `.agents/skills/workflow-template-sync/` (both
              template-sync.sh and pack-scan.sh) into the derivation BEFORE running update,
              while its manifest is still the old one. Only then does `update` compute the
              dropped-path set correctly and remove `workflow-gateway` and `craft-*` instead
              of orphaning them. Verify no orphan survives.
      accept: `.template.lock` reads 37; `template-sync.sh --check` reports no drift;
              `check.sh` and `orchestrate.sh check` both clean; AGENTS chain is
              CLAUDE.md→AGENTS.md→AGENTS.CORE.md→VOICE.md; committed with /usr/bin/git.
- [x] T006 · workhorse · deps:T001,T004 · Converge stewardship to v37
      evidence: notes/T006-stewardship-converge.md; commit 3ffe847 "core: converge to template
                v37 and install the code-craft pack". Orchestrator re-verified in the repo:
                `.template.lock` = 37; `list` shows workflow-core 37 + code-craft 2;
                `--check` "up to date", `--audit` silent; CLAUDE.md:4 `@AGENTS.md`,
                AGENTS.md:5 `@AGENTS.CORE.md`; `find` returns no gateway or bare-craft path;
                tree clean. Bootstrap printed `removed` for all six retired paths.
                Worker went beyond instruction once and said so: it also replaced the stale
                "Core check" prose in AGENTS.md that told readers CLAUDE.md must import both
                files — false under v37 and an active trap. Correct call, kept.
                All four legacy sessions still resolve via `orchestrate.sh list` with legacy
                NOTEs; `git diff -U0 -- .workflow | grep -E '^[+-]- \['` returns nothing, so
                no task marker moved. `check.sh` now reads TOOL ok / PACK ok / TEMPLATE ok
                after the orchestrator ran `/workflow-init` (init.lock 4 -> 6, per-machine).
      residual: `check.sh` still exits non-clean on findings that are NOT this task's and are
                not about this repo's own tracked files, each carried below:
                - AGENTS: 8 substrate repos under `workspace/` lack CLAUDE.md bridges. Other
                  repos, under their own law. Not fixed here — `agents-sync --fix` would write
                  into eight repos this task never bound.
                - LAYOUT-001: `.workflow/` still exists. Deliberate; clears only on migration.
                - SUBSTRATE-001 x5: citation counts dominated by build artifacts (`.trx`,
                  `obj/`, `bin/`, `TestResults/`) — 23296 "citing lines" in
                  global-shop-solutions is scan noise, not 23296 real citations.
      accept: same as T005, plus all four legacy `.workflow/<slug>/` sessions still resolve
              through `orchestrate.sh list` (each with its legacy NOTE), no task marker in any
              of them altered, craft-* skill names inside those task lists re-pointed to the
              pack's names, and what a migration to the new layout would require reported.
      revised2: the "check.sh clean" clause inherited from T005 is unmeetable in this repo and
              was wrong to write. LAYOUT-001 cannot clear while the legacy sessions live, and
              this task was explicitly forbidden from migrating them. Judged against the
              corrected standard: the repo's OWN core state is clean, and every residual is
              named above rather than absorbed.
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
              reaping rather than done here.
- [x] T007 · fleet · deps:T003,T004 · Converge sandbox to v37
      evidence: notes/T007-sandbox-converge.md; commit 235ce48 "chore: converge template core
                from v13 to v37". Orchestrator re-ran the checks rather than accepting the
                report: `.template.lock` = 37; `--check` "up to date (37)" / "status: up to
                date"; `check.sh` TOOL/AGENTS/LAYOUT/PACK/TEMPLATE all ok, "all constraints
                met"; `agents-sync: all conforming`; `find` for workflow-gateway returns
                nothing; AGENTS.md:5 `@AGENTS.CORE.md`, CLAUDE.md:4 `@AGENTS.md`; tree clean.
                Bootstrap worked as designed — update printed `removed
                .agents/skills/workflow-gateway/**` rather than orphaning it.
                No pack installed, deliberately: no craft content here to re-source.
      method: same BOOTSTRAP FIRST step as T005, which is what makes 13 -> 37 viable and
              retires the worker's re-derive recommendation (Log). No craft-* to handle here;
              `workflow-gateway` is the path being dropped.
      accept: same as T005, except: no remote is configured, so the push clause does not apply
              and the commit is local by definition.
- [ ] T008 · fleet · deps:T015,T016,T017 · Update ~/.claude/skills/wf/SKILL.md to the current model
      accept: the file names packs and `template-sync.sh add/remove/list`, the four-level
              `workflows/<workflow>/<app>/<session>/` layout, `/workflow-check`,
              `/workflow-plugins` and the pack-vs-plugin test ("would we send a pull request
              to change it?"), and the `code-craft` pack; no surviving reference to `craft-*`,
              `.workflow/`, `playbooks/`, or the removed gateway; every repo URL and path in it
              verified against disk. Runs LAST so it describes the state that actually exists.
- [ ] T009 · fleet · deps:T015,T016,T017 · Verify all three derivations under the v37 checks
      accept: notes/T009-verify.md carries, per repo, the literal output of `check.sh`,
              `orchestrate.sh check`, `agents-sync.sh`, and `template-sync.sh --check --audit`;
              any non-clean result named as a finding rather than summarized as pass.
- [x] T013 · fleet · deps:T005 · Re-point workflow-monolith's static-analysis skill at the pack
      evidence: notes/T013-static-analysis.md; commit d563ce6 in workflow-monolith, one file,
                12 insertions / 12 deletions. Orchestrator re-verified: grep for
                `craft-code-quality|craft-tdd|\.agents/craft/` in that SKILL.md returns nothing;
                the file's only relative link is now
                `](../code-craft-quality/references/loc-budgets.md)` and it resolves from the
                file's own directory (`ls -l` shows the 6883-byte file);
                `git show --stat d563ce6` confirms one file changed and the journal untouched.
                11 refs renamed, not the 8 the survey predicted, plus the overlay path.
      accept: `.agents/skills/static-analysis/SKILL.md` names `code-craft-quality` everywhere it
              now says `craft-code-quality` (lines 32, 36, 43, 45, 51, 67, 112, 122), and the
              relative link at line 45 resolves — it currently points at
              `../craft-code-quality/references/loc-budgets.md`, which does not exist; the real
              file is `.agents/skills/code-craft-quality/references/loc-budgets.md`, confirmed
              present. Verify by resolving the link from the file's own directory, not by
              eyeballing it. `journal/2026-07-30-derived-and-ndepend.md` is a dated record and
              is NOT rewritten. Committed in that repo, not pushed.
      found:  raised by T005's worker as outside its assigned scope. Correct call — a dangling
              relative link in a derivation-owned skill is real work, and widening T005 to
              absorb it would have hidden the growth.
- [x] T012 · workhorse · deps:T005,T006,T007 · Promote the update-bootstrap defect into the core
      evidence: notes/T012-promotion.md; commits 190ff4b (core v41) + 4166639 (notes), pushed
                to origin as a1b23d8. Four-part promotion test applied in writing, PASS on all
                four. Orchestrator re-verified: VERSION=41 and template-manifest.yaml
                `version: 41` bumped together; `bash -n` parses; `check.sh` all constraints met.
                Fix is in code, not documentation: `update_core` stages the upstream's
                workflow-template-sync dir over the local one and re-execs, guarded by
                WORKFLOW_TEMPLATE_SYNC_RESTAGED (no loop), gated behind pinned/up-to-date/behind,
                skipped when the dirs are identical, and refused unless the upstream script
                `bash -n`-parses in a temp dir first. Staging never touches
                template-manifest.yaml, so `old` is still the derivation's manifest when the
                new script diffs it — verified by reading update_core lines 512-529.
      corrected: the worker corrected the orchestrator's premise. Dropped-path removal arrived
                in core v30 (c0707e7), NOT v37 — confirmed by `git log -S remove_paths`. The
                finding is unaffected: the three derivations were on 13, 17 and 19, all below
                30. v30 is the threshold now written into the skill.
      limitation: the fix is one release late by construction, and the worker said so rather
                than hiding it. A derivation whose installed script predates the staging step
                stages nothing. Demonstrated live, not argued: sandbox at v40 updating to v41
                ran the OLD logic and printed no `staged` line. Its script is now v41, so the
                staging path exercises on the next hop — which T014's bump to 42 provides, and
                that is where this gets its real end-to-end test.
      note:     orchestrator ran that sandbox update as verification and left the repo at 41
                (commit 7fff825, init.lock 7, all constraints met). An earlier attempt piped
                the script into `head -8`, which SIGPIPE'd it under `pipefail` and left the
                tree half-synced with the lock unwritten; re-run without the pipe, exit 0.
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
- [ ] T014 · workhorse · deps:T012 · Promote: SUBSTRATE-001 counts build artifacts as citations
      accept: the checker that raises SUBSTRATE-001 stops counting generated and ignored files,
              or states in its own output that it does not filter them. Evidence that the rule
              currently misfires: in stewardship it reports 23296 citing lines across 157 files
              for global-shop-solutions, and the three worst offenders are
              `TestResults/full_suite_final.trx` (3868), `TestResults/full_suite.trx` (3769),
              and `obj/Debug/net8.0/...FileListAbsolute.txt` (2861) — build output, not source
              citing a session path. A rule that reports five digits of noise trains its reader
              to skip it, which is worse than not having it. Passes the four-part promotion test
              first; if it fails one, that is the finding. VERSION + manifest bumped together.
      deps-why: serialized behind T012 on purpose — both edit this core's VERSION and
              template-manifest.yaml, and two concurrent bumps collide.
- [ ] T015 · fleet · deps:T014 · Re-converge stewardship onto the core's released version
      accept: `.template.lock` matches this core's VERSION at the time the task runs (>= 40);
              `--check` no drift for core AND code-craft; `/workflow-init` run (init VERSION
              went 6 -> 7, jq is now a required tool); `## Closed` present in every application
              `tasks.md` per the tightened LAYOUT-008; the four legacy sessions still resolve
              and no task marker moved. NO bootstrap step needed this time — the repo's own
              script is already v37, which computes dropped paths correctly.
- [ ] T016 · fleet · deps:T014 · Re-converge workflow-monolith onto the core's released version
      accept: same as T015, minus the legacy-session clause (that repo has none).
- [ ] T017 · fleet · deps:T014 · Re-converge sandbox onto the core's released version
      accept: same as T016. No pack, no remote.
- [x] T018 · fleet · deps:- · Survey the plugin marketplace and recommend a registry
      evidence: notes/T018-plugins.md. Orchestrator re-derived the counts from
                `.claude-plugin/marketplace.json` and the filesystem: 276 entries, 53 with a
                local string source (38 first-party listed + 15 under `external_plugins/`),
                223 pointing at unfetched third-party repos. 39 dirs exist under `plugins/`;
                the 39th is `example-plugin`, which the marketplace does not list — so the
                worker's 38+15=53 is correct. Hook-registering plugins verified by
                `grep -rl '"hooks"'`: exactly the six named — security-guidance, hookify,
                claude-security, explanatory-output-style, learning-output-style, ralph-loop.
                Two strongest claims checked against source: security-guidance/hooks/hooks.json
                registers SessionStart (timeout 180), UserPromptSubmit, and PostToolUse on
                `Edit|Write|MultiEdit|NotebookEdit` plus `if: Bash(git commit:*)`;
                security_reminder_hook.py reads ANTHROPIC_API_KEY / ANTHROPIC_AUTH_TOKEN
                (lines 50-51, 123) and reaches api.anthropic.com (1113, 1916);
                external_plugins/github/.mcp.json:6 reads GITHUB_PERSONAL_ACCESS_TOKEN.
                No plugins.yaml written, as instructed.
      recommend: workflow-template none · stewardship none certain (github/gitlab plausible,
                needs a substrate-specific follow-up) · workflow-monolith csharp-lsp is a clean
                fit for a large .NET codebase, code-modernization worth a design look ·
                sandbox none. Every one of these stays the user's call.
      accept: notes/T018-plugins.md lists every plugin available in `claude-plugins-official`
              (registered on this machine today at 16:29 local; nothing enabled anywhere), and
              for each: what it executes — HOOKS FIRST, then egress, then credential reads —
              at what version, per `/workflow-plugins`'s review duty. Ends with a
              recommendation per workflow repo and an explicit statement that declaring a
              plugin is the user's call, not this task's. Writes NO plugins.yaml: a repo with
              none is complete, not degraded, and an empty registry is worse than no registry.
- [ ] T010 · workhorse · deps:T009 · Write the derivations application profile
      accept: `../profile.md` records each derivation — path, remote, template_version,
              packs installed, what it stewards — and every claim that can decay carries the
              trigger that invalidates it, per the profile template's own rule.

## Reaping

<!-- Required before this run can close. Sweep notes/ and decisions out to their
     destinations per AGENTS.CORE.md "Reaping law": a way of working that stabilized to
     workflows/upstream-workflow-management/, understanding of derivations to its own docs or ../profile.md,
     unfinished work still wanted to ../tasks.md ## Open, a refusal or de-scope to the
     stewarded repo's docs or ../profile.md with its signoff.
     Then record where each output landed on the reaping: line below, and run
     `orchestrate.sh close`. It re-checks the DoD, writes the ledger line into
     ../tasks.md ## History, and deletes this directory in one step. Never delete a
     session directory by hand. -->

reaping: pending

## Log

- **App modeling, decided by the orchestrator.** The managed `upstream-workflow-management`
  workflow declares its application as `self`. This run acts from the core's seat on three
  *downstream* repos, so it opens a second application, `derivations`, under the same
  workflow. Rejected alternative: a new workflow (`derivation-convergence`) — `derive` keeps
  `workflows/<workflow>/SKILL.md` as TIMELESS, so a new workflow in the core ships into every
  future derivation while sitting in no manifest, i.e. inherited and unmaintained. If the
  `self`-only wording in that skill is wrong, it is a promotion candidate at reaping.
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
- **Upstream moved a third time, to v40 — chased on the user's instruction.** `personal/main`
  reached v40 while T005–T007 were converging the derivations onto v37, and `main` had
  DIVERGED (7 session commits vs 4 upstream). Rebased the session commits onto v40 — clean, no
  conflicts, because the session only touches `workflows/.../derivations/**` and one journal
  file while upstream touched skills and core law. Pushed to origin. Three of the four new
  commits bear on this run: v38 fixes `close` stripping the blockquote marker from the ledger
  directive (this session's Directive IS a blockquote), v40 restores `## Closed` to the carried
  template (the `derivations/tasks.md` scaffolded here lacked it — LAYOUT-008 caught it, fixed
  by hand), and `workflow-init` VERSION went 6 -> 7 with `jq` now required, so every repo's
  `init.lock` is stale again.
- **Re-plan: promote first, converge once.** T015–T017 re-converge the three derivations, but
  they are sequenced BEHIND the two promotions (T012, T014) rather than run now against v40.
  Converging to 40 and then again to 41 would be two hops for one outcome. The promotions
  bump the core; the derivations then take a single hop to whatever that release is.
  T012 and T014 are serialized against each other for the same reason two writers cannot both
  bump VERSION.
- **Neither promotion was pre-empted upstream.** v38–v40 touched `check.sh` and
  `constraints.md`, so both T012 (update bootstrap) and T014 (SUBSTRATE-001 counting build
  artifacts) were re-checked against the new code and both still stand.
- **Plugins: mechanism arrives, registry does not.** `/workflow-plugins` (v39) is now present
  in all four repos as part of the core. Nothing is declared and nothing is enabled: no repo
  has a `plugins.yaml`, `plugins.sh list` says so, and `enabledPlugins` is empty in the
  harness. One marketplace is registered — `claude-plugins-official`, added 2026-08-01 16:29
  local. T018 surveys it and recommends; it deliberately writes no `plugins.yaml`, because an
  empty registry is worse than none and which plugins a repo declares is the user's call.
