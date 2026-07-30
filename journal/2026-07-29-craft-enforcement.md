# Craft Enforcement — pushing the rules into the build

Added `references/enforcement.md` and `assets/arch-tests/` to `craft-code-quality`, plus a
matching machine-enforceability section in `craft-tdd`.

## The point

A rule an agent reads applies as often as someone remembers it. A rule in the analyzer applies
whether anyone remembers it or not. The ratchet doctrine already asserted this (invariant 1:
machine-enforced, never remembered) — this is where it gets cashed out, mandate by mandate.

## Three classes, and why labeling is the deliverable

Every mandate in both skills is now classified **ENFORCED** (a machine decides it) / **PARTIAL**
(a machine catches the mechanical case, a residue needs judgment) / **REVIEW** (no mechanism
exists).

The load-bearing rule: **an enforced rule and a review-only rule must never look alike in the
doctrine.** A repo where "domain must not depend on persistence" is a wired dependency rule and
"prefer descriptive names" is an aspiration is in good shape. A repo where both are prose and
the build is green has standards in name only — and nobody can tell which is which without
reading the CI config. Labeling is what prevents prose from being mistaken for enforcement.

## The headline finding

**Most of the architecture block is enforceable and almost never enforced.** Hexagonal layering,
the UI boundary, "domain tests must not touch the data layer", "logic must not live in the UI" —
all of these are dependency-direction questions, which is exactly what architecture-test tools
decide. If a repo claims hexagonal architecture with no dependency rule wired, the claim is
unverified; treat it as a finding. This is the largest available win in either skill.

## The canary rule

A rule that does not fire is worse than no rule — it manufactures confidence that something is
being checked. Banned-symbol lists with a typo'd symbol, layer rules pointed at a wrong package
name, and coverage gates reading an empty report all fail **open** and all look green.

So every wired rule gets proved once: smallest possible violation → confirm the check fails and
names the right rule → revert. Never trust a green gate nobody has seen go red. Where cheap,
promote the canary to a permanent negative fixture so a later config refactor cannot silently
disarm the rule.

## ArchUnit's FreezingArchRule — a ratchet implemented by the tool

The best find in the verification pass. `FreezingArchRule.freeze(rule)` maintains a persistent
violation store (`archunit_store/`, index `stored.rules`): the first run always passes, later
runs fail only on **new** violations, and fixed violations are auto-pruned by default
(`freeze.store.default.allowStoreUpdate=true`). The baseline self-shrinks — it never has to be
hand-edited down.

Consequence for sequencing: **on the JVM every architecture rule can go on in a single Pass 0
commit**, because freeze absorbs the existing violations. The hardest rules to adopt become the
easiest ones. Nothing else in the set comes close, and the disparity is invisible from the
tools' own documentation, so it is recorded explicitly in both `enforcement.md` and `ratchet.md`.

Baseline support, ranked — this decides adoption order more than any other factor:

| Tier | Tools |
| --- | --- |
| Purpose-built | ArchUnit `FreezingArchRule` |
| Genuinely automatic | dependency-cruiser `--ignore-known`; ESLint `eslint-suppressions.json` (`error`-level rules only) |
| Diff-scoped, not a store | golangci-lint `--new-from-rev` / `--new-from-merge-base` / `--whole-files` |
| Manual allowlist | import-linter `ignore_imports`; go-arch-lint legalize/todo markers |
| None | NetArchTest, ArchUnitNET, BannedApiAnalyzers, Ruff `TID251` (open upstream request, ruff#1149) |

.NET and Python therefore cannot do the JVM's one-shot Pass 0. There the rule gets scoped to
already-clean directories (nested `.editorconfig`, or a narrow `containers=`) and the scope grows
— recorded in config so it cannot quietly shrink.

## Corrections from verification

Researched against official docs rather than asserted. Four things I would have gotten wrong:

- **dependency-cruiser's baseline flag is `--ignore-known`**, not `--known-violations`; generate
  via `--output-type baseline -f .dependency-cruiser-known-violations.json` or the
  `depcruise-baseline` binary.
- **`eslint-plugin-boundaries` v6.0.0 renamed** the rule `boundaries/element-types` →
  `boundaries/dependencies` and the options key `rules` → `policies`.
- **BannedApiAnalyzers diagnostics are RS0030 / RS0031 / RS0035.** RS0034 is not in the package.
- **golangci-lint v2 forces `deny` as a list** of `{pkg, desc}`, even though standalone depguard
  accepts a map.

And two that would have broken the ArchUnit template on first compile, caught by reviewing the
generated asset rather than trusting it:

- **The package is `com.tngtech.archunit.junit`, not `...junit5`** — the artifact id contains
  `junit5`, the Java package never has.
- **Kotlin `companion object` rule fields need `@JvmField`.** `@ArchTest`'s contract is "a static
  field of type ArchRule"; a plain `val` in a companion object compiles to an instance field on
  the Companion singleton, which reflection over the outer class will not see. `@JvmStatic` does
  not fix it — it only adds forwarding accessors. Without `@JvmField` the rules are silently
  never evaluated, which is precisely the failure mode the canary rule exists to catch. Noted in
  the template as reasoned from Kotlin/JVM semantics plus ArchTest's javadoc, since the ArchUnit
  user guide has no Kotlin section to cite.

Also corrected in-template: `layeredArchitecture()` returns a `DependencySettings` builder in
1.4.x, so `.consideringAllDependencies()` is **required** before `.layer(...)` will compile. And
`@AnalyzeClasses` includes test classes by default — inclusion is decided by compiled-output
location, not package name — so the mock-boundary rule as written covers both production and
test domain classes. That is stronger than the rule as stated and deliberate; the comment was
corrected to say so rather than leaving the mismatch.

## Three gaps, recorded so nobody re-searches them

- **Nothing bans `InternalsVisibleTo`.** Checked Meziantou.Analyzer, StyleCop.Analyzers,
  Roslynator, SonarAnalyzer.CSharp — no first-party or well-known community analyzer. Options are
  a custom Roslyn analyzer or an assembly-attribute assertion. BannedApiAnalyzers' RS0035 covers
  *restricted* IVT, a different concern.
- **No tool detects magic-value assertions or non-randomized test data** in any of the five
  ecosystems. SonarQube's S109 is general-purpose, excludes -1/0/1, and per SonarSource cannot be
  configured differently for test versus main paths. Confirmed by search — these stay REVIEW.
- **"Tests must not mock domain types" has no semantic implementation anywhere.** No tool
  inspects what type reaches `mock()`. Every available mechanism is an import/dependency-boundary
  rule. Kept as PARTIAL: wire it, because it catches the accidental case, which is the common
  one — but do not describe it as enforced.

## Deliberately not chased

The REVIEW column is not a backlog. Several entries are permanently unenforceable and the
doctrine says so: "do not over-abstract" is the deliberate counterweight to "every EUD has a
seam", and a tool arbitrating it would be wrong in both directions. Test-first ordering is a
process property whose every static proxy is gameable, and gating on a gameable proxy trains
people to game it. Weak proxies for SRP and naming quality generate noise that erodes trust in
the whole rule set, costing more than the rule was worth.

## Scope

Five languages — TS/JS, .NET, Kotlin/JVM, Go, Python — matching a survey of the workbench repos.
Ruby and Swift appear in no repo, so the LOC budgets still apply to them but no mechanism is
documented; adding one now would be speculative and unexercised. Noted in the file as addable
when a repo needs it.

Related observation: `binds.yaml` still has `standing: []`, so none of the workbench repos are
registered as standing binds. The ratchet and enforcement doctrine currently have no live target
bound to this workflow. Registering them is a separate piece of work.

## Verification

- `agents-sync.sh`: all conforming.
- Every reference and asset link resolves; no reference file carries frontmatter.
- All ten asset files syntax-validated: both `.js` files pass `node --check` (including the
  dotfile, which the first glob missed), `.golangci.yml` parses as YAML, the Ruff snippet parses
  as TOML, `.importlinter` parses as INI with the three expected contract sections.
- Kotlin template: imports confirmed free of the `junit5` package error, all three rule fields
  carry `@JvmField`, no token concatenation left by the edit that added it.
- Manifest needs no change — `.agents/skills/craft-code-quality/**` already covers `assets/`.
  `VERSION` → 16; manifest `version` stays 14.

Two UNVERIFIED markers left in the templates rather than guessed: RS0035's exact configuration
shape for restricted-IVT, and go-arch-lint's precise field syntax. Both are flagged in-file as
needing a check against upstream before use.
