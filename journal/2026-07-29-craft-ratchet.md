# Craft Ratchet — a path from non-compliant substrate to the mandates

Added a ratcheting strategy to `craft-code-quality` (body section + `references/ratchet.md`)
and a matching "Legacy substrate" section to `craft-tdd`.

## Why this was missing

The mandates ported in `12c5cc4` are strict on purpose. Applied to the substrate they will
actually meet first — zero static analysis, thin tests, a 5k LOC file doing six jobs — they
produce one of two failures: the skill declares the repo non-compliant and stops, which is
worth nothing; or it attempts compliance in one pass, producing an unreviewable diff that
gets rubber-stamped or reverted. Either outcome discredits the standards.

The strictness is right. What was missing is that **the mandates are a destination, not an
entry fee.** This is the normal case, not the exception, so the ratchet is doctrine rather
than an appendix.

## The four invariants

1. **Machine-enforced, never remembered.** Every turn lands in committed config — a baseline
   file, a frozen count, a threshold value — so CI holds the line. A ratchet living in an
   agent's memory, a TODO, or a journal entry has already slipped. This is the invariant the
   whole technique rests on.
2. **Monotone.** Baselines and thresholds move toward the mandate, never away.
3. **New code meets the mandate now; old code only improves.** Diff-scoped enforcement makes
   full strictness safe on day one, in a repo at 4% coverage.
4. **The ratchet must actually turn.** A baseline that never shrinks is technical debt with
   better branding.

## Pass ladder

- **0 — Instrument and freeze.** No code changes. Tooling in, baseline generated, CI failing
  on regression only. Buys the ratchet before any quality; without the freeze every later
  gain leaks back out unnoticed.
- **1 — Diff-scope the mandate.** Full strictness on changed code. Most of the long-term
  value: the repo stops getting worse without touching legacy.
- **2 — Promote rule classes**, one per pass: formatting → correctness → complexity → size.
  Formatting first (auto-fixable, makes later diffs readable), size last (needs design work).
  Auto-fixes land as a pure mechanical commit touching nothing else.
- **3 — Walk the numbers**, step-sized to a reviewable diff.
- **4 — Decompose the monoliths.** LOC recorded as a ceiling that only decreases; extract one
  coherent slice per visit behind characterization tests; new behavior into new modules
  (strangler). No wholesale rewrite — unreviewable, and it discards embedded bug fixes whose
  reasons were never written down. Rank by churn × size, not size.
- **5 — Retire the scaffolding.** Baseline empty → delete it, mandate value, repo-wide.

Exit criterion: no baseline files, thresholds equal budgets, enforcement repo-wide. Then the
ratchet section stops applying and the rest of the skill applies plainly.

## Two additions beyond the ask

**In bound substrate the ratchet is a proposal, not a unilateral act.** Wiring CI, adding
config, committing a baseline — these change how everyone else on that repo works. Present
Pass 0 with the measured gap, get agreement, then execute. Only owned repos get the ladder
executed directly. This follows from the parent skill's "never install tooling uninvited",
but the stakes are higher here because the change is process-wide rather than local.

**Where ratchet state lives.** Machine-checkable state belongs in the substrate repo (that
is invariant 1). The workflow overlay records only the target and cadence where they differ
from default — never the current position, which would put the ratchet back into memory.

## Tool verification — one belief corrected

Researched the per-language mechanisms against official docs rather than asserting flags
from memory. The important correction: **ESLint does now have a native bulk-suppression
baseline** — `eslint --suppress-all` → `eslint-suppressions.json`, added in v9.24.0 (April
2025), with `--prune-suppressions` to drop stale entries. My assumption that ESLint had no
native baseline was true historically and is now wrong.

That correction also invalidated the first draft of Pass 0, which said "configure at whatever
severity leaves the build green" — i.e. `warn`. **ESLint only suppresses rules configured as
`error`**; a rule parked at `warn` is silently not suppressed. Pass 0 was rewritten to branch
on whether the tool has a baseline at all, since the two recipes are not interchangeable.

Other findings worth recording:

- **RuboCop**: regenerate with `--regenerate-todo`, not a bare `--auto-gen-config` — the
  latter re-runs with whatever flags are passed and can silently change scope or mutate
  `.rubocop.yml`. `--exclude-limit` defaults to 15: above that many offending files the cop is
  **disabled entirely** rather than excluded file-by-file — a silent total loss of coverage.
- **Detekt**: `maxIssues` exists in stable 1.23.x but is **removed in 2.0.0** (alpha) in favor
  of per-rule severities. Do not build a long-lived ratchet on it.
- **Go**: `--whole-files` changes the ratchet's character — without it, violations in a
  changed file are dropped unless on a changed line.
- **SwiftLint**: baseline is line-anchored, so moving a violating line re-surfaces it.
  Effectively a tool-enforced boy-scout rule.
- **Ruff**: no external baseline — `--add-noqa` writes the debt into source, which is an
  advantage for a ratchet: greppable, visible in review, and deleting a `# noqa` is a legible
  unit of progress.
- **No baseline mechanism at all**: .NET analyzers, mypy (first-party), PMD for Java,
  SpotBugs, Checkstyle. For .NET the substitute is per-directory `.editorconfig` severity
  escalation — nested files override parents, which is the closest thing .NET has to
  diff-scoping. Recorded as a genuine gap rather than papered over.
- **Coverage**: diff gate and total floor are complementary, not alternatives, in every
  ecosystem surveyed. JaCoCo has no native changed-class scoping — pair with `diff-cover`.

Unverified items were omitted rather than guessed: any first-party .NET baseline command,
PMD baseline (appears not to exist for Java at all — not to be confused with PHPMD),
`golangci-lint` v2 config-file schema equivalents for the CLI flags, and exact precedence
among `TreatWarningsAsErrors`/`WarningsNotAsErrors`/`NoWarn`.

## Naming

"Ratchet" is the term in current use (Notion's `eslint-seatbelt`; LeadDev's quality-ratchets
piece). SonarQube implements the same idea as **"Clean as You Code"**, gated on a configurable
*New Code* definition — which is exactly Pass 1's diff-scope, so substrate already running
Sonar should use that gate rather than a parallel mechanism. The legacy-test technique is
Feathers' **characterization test** from *Working Effectively with Legacy Code*.

## Consistency resolved

The skill says "the build fails on lint violations"; Pass 0 says CI fails on regression only.
Reconciled explicitly in the lint section: with too much existing debt the build still fails,
on regressions — existing debt is a reason to ratchet, never a reason to leave the gate open.
The Done criteria likewise now measure against the current ratchet position rather than full
compliance, with full compliance as the ratchet's exit criterion.

Similarly in `craft-tdd`: for a bug the test still fails first; for a refactor of untested
legacy the characterization tests **pass** first — which is what "cover the behavior before
touching it" already meant, now stated outright so it does not read as a contradiction of
test-first.

## Verification

- `agents-sync.sh`: all conforming.
- Frontmatter valid on all four `SKILL.md` files; canonical and proxy descriptions byte-equal
  after both were updated for retrieval on "repo has no tooling".
- Both `references/` links resolve from `SKILL.md`; `loc-budgets.md` → `ratchet.md` resolves;
  neither reference file carries frontmatter.
- Manifest needs no edit — `.agents/skills/craft-code-quality/**` already covers
  `references/ratchet.md`. `VERSION` → 15; manifest `version` stays 14, since it tracks when
  the manifest itself last changed.
