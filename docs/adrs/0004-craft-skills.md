# ADR-0004: Craft skills: code quality and TDD doctrine

**Status:** Accepted
**Date:** 2026-07-29
**Authors:** henning
**Deciders:** henning

**Scope (repos affected):**

- `workflow-template` — the core itself
- every derivation — receives this through the managed set

---

Ported the two strongest doctrine files from the `workbench` corpus into template-managed
skills: `/craft-tdd` and `/craft-code-quality`. Sources were
`workbench/.agents/AGENTS.RULES.TDD.md` (byte-identical across all 11 copies in the
corpus) and `workbench/global-shop-solutions/.agents/AGENTS.RULES.CODING.md` (the richest
CODING variant — the workbench-root copy plus a "No Implicit Fallbacks" section).

## Why skills, not more AGENTS.*.md

The workbench corpus had already evolved through two generations. Gen 1 (March 2026,
`workbench/agents/`, hackathon repos) directed the agent to read every `AGENTS.*.md` in
the glob every turn — always-loaded, no triage. Gen 2 (July 2026,
`global-shop-solutions` family, `gitops`, `platform`) added a METADATA HEADER CONTRACT: an
`AGENT_TITLE:`/`AGENT_DESCRIPTION:`/`AGENT_USAGE:` triple per file plus a mandatory
per-turn applicability-scan acknowledgement, so the agent read only headers before
deciding to load a body.

Skills are the third generation and make both mechanisms redundant. Frontmatter
`name` + `description` does the header triple's job — declaring load-worthiness — and the
harness performs the applicability scan structurally, so the acknowledgement ritual is
pure overhead. **The header triple and the scan protocol are deliberately retired, not
ported.** The only always-loaded cost is now a frontmatter description per skill; every
body and reference loads on demand. That was the point of the exercise: the static context
the old corpus took for granted.

Corollary: `references/*.md` files get **no** header triple either. A header inside a
reference is read only after the file is already open, which is too late to inform the load
decision. Routing lives in one place — the reference index table in the parent `SKILL.md`.

## Decomposition

Two skills, not one umbrella and not six granular ones. They fire at genuinely different
moments: `craft-tdd` must fire the instant a bug report or feature request arrives, before
any implementation, because its whole value is sequencing. Burying it as
`craft-code-quality/references/tdd.md` would make it a two-hop retrieval, which is where
behavioral protocols die.

Concrete numbers went to `references/loc-budgets.md` rather than the body. The body carries
the principle and the *duty to check*; seven languages' tables are only needed when
checking one language. Teeth live in the duty, not in residency.

## Keeping the teeth without claiming authority

The sources are written as unconditional law ("IMPORTANT! TDD is not optional", "Builds
must fail on lint violations", "C#: methods soft max 50"). A template consumed by unknown
derivations operating on unknown substrate cannot assert that — and `AGENTS.CORE.md` bind
law already says repo law wins inside the repo's own boundaries. Rewriting rules applied:

- **Process law survives verbatim.** Rules governing the agent's own behavior — failing
  test first, run the suite once and grep the stored output, never mock business logic,
  test at the endpoint — have no authority conflict. Absolutes kept intact.
- **World law converts to detect → apply-or-surface duties.** "X must be true of the repo"
  became "check whether X holds; if the repo defines its own X, that is the law — read it;
  if absent, surface it as a finding and propose the fix; never silently proceed." This is
  just "surface, don't suppress" applied to standards.
- **Hedge once, structurally, never again.** One precedence preamble per skill; the body
  stays imperative. Sprinkling "consider" through 160 lines is how good doctrine becomes
  mush.
- **Numbers kept exact, re-scoped.** No fuzzing "soft max 50" into "keep methods short".
  The tables are labeled as defaults where the substrate declares no limits, with an
  explicit inheritance rule: a linter config in the repo overrides the table.
- **Enforcement verbs became flag semantics.** "Blocked" → do not produce it; if forced,
  flag it as a violation with a decomposition plan. TDD's existing CODE FLAGS section was
  already the right native mechanism.
- **New distinction the sources lacked: owned vs bound.** Missing lint config is a blocker
  in a repo the workflow owns, but only a finding in bound substrate — and tooling is never
  installed into someone else's repo uninvited.

## Craft overlays — the constitutional question

Shipping opinionated defaults (LOC budgets, hexagonal-by-default) into every derivation
brushes against the covenant ("the template facilitates, never constrains") and against
the categorical rule, which assigns *doctrine* to derivations. On-demand loading does not
by itself resolve this — the description is always resident, the skill will be invoked in
every coding session, and at that point the opinions are law-shaped text in context.

What resolves it is precedence plus an overlay, now written into `AGENTS.CORE.md`:

1. A precedence ladder declared at the top of every `craft-*` skill — bound-repo law >
   derivation overlay > skill defaults, the last applying in full force only where the
   first two are silent.
2. A derivation-owned overlay slot, `.agents/craft/<skill-name>.local.md` — unmanaged,
   never touched by `update`, and it wins on conflict. The template owns the shape (skill +
   slot); the derivation owns the doctrine-data that fills it. "Managed" therefore stops
   meaning "unmodifiable": changing a default no longer requires pinning, ejecting, or
   eating drift.

Chose managed over unmanaged deliberately. `derive` copies the whole repo, so unmanaged
skills would still land in every derivation — just orphaned at birth, never receiving
upstream improvements. That guarantees N divergent rotting copies, defeating the reason to
centralize. `VOICE.md` is the precedent: pure opinion, managed, uncontroversial.

## Namespace

`workflow-*` was reserved for clobber-safety on `update`, not for branding — so it did not
have to be the prefix for everything the template ships, and `/workflow-tdd` actively
misdescribes its subject. `AGENTS.CORE.md` now reserves **two** prefixes: `workflow-*`
(machinery operating on template shapes) and `craft-*` (engineering doctrine for work done
on substrate). Bare `/tdd` was rejected — those are exactly the names a derivation would
create locally, and the reservation exists to protect future template additions.

Shipped in the same version bump as the manifest change: a derivation must never receive a
`craft-*` skill from an `update` whose constitution does not yet reserve the prefix.

## Deliberately left out

- **GSS-specific material**, which belongs in a derivation or its substrate, never here:
  Axon Framework rules, `AGENTS.RULES.DATA.md` (Pervasive/Zen DB, AWS Secrets Manager),
  gitops (ArgoCD/Keycloak), `architecture/AGENTS.md`, the ADR-0032 branching gate.
- **UI rules.** Both `AGENTS.RULES.UI.md` and `AGENTS.CONVENTIONS.UI.md` hardcode a
  concrete palette (emerald accent, amber warning, rose destructive, slate surfaces) and
  concrete paths (`src/uiTheme.ts`). The semantic-token discipline ports; the palette is
  exactly what the overlay slot is for. Deferred.
- **`AGENTS.RULES.I10N.md`** — its entire body is "# Do best effort". Folds into i18n
  whenever that lands; not worth a file.
- **Git conventions.** Highest collision rate with substrate repos' own conventions and
  with `AGENTS.CORE.md`'s existing Git discipline section. Deferred, possibly permanently.
- CQRS event naming, API, i18n, dependencies, Node — all generic and portable, queued for a
  follow-up pass.

## Open follow-up

Substrate double-load: GSS repos still carry the old `AGENTS.RULES.*.md` and the Gen-2
acknowledgement protocol in their own `AGENTS.md`, and bind law says honor them. A session
will hold both the rewritten skill doctrine and the Gen-2 originals, possibly divergent,
with repo law winning. Not the template's problem to fix, but the substrate-side migration
(repos shrink their `AGENTS.md` and drop the rules files as the skills land) needs planning
or the rigor will exist in two competing dialects.

## Verification

Mechanical:

- `agents-sync.sh`: all conforming.
- All 20 `template-manifest.yaml` managed paths resolve; `VERSION` (14) matches manifest
  `version` (14).
- Frontmatter `name` correct on all four `SKILL.md` files; both proxy imports resolve to
  their canonical bodies; `references/loc-budgets.md` carries no frontmatter.
- Both skills confirmed discoverable in-session.

Adversarial concept-coverage audit, each port graded against its source independently and
instructed to report a gap when uncertain:

| Port | First pass | After fixes |
|---|---|---|
| `craft-tdd` (37 concepts) | 34 present, 3 weakened, 0 missing — 92% | 37/37 |
| `craft-code-quality` (140 concept-units) | 135 present, 4 weakened, 1 missing — 96.4% | 140/140 |

Number fidelity on `craft-code-quality`: **zero mismatches.** All 28 LOC data points (7
languages × function soft/hard + file soft/hard), all 5 industry baselines, the 220
logical-LOC markup threshold, the 4k-LOC-smell figure, and all 24 tool/rule identifiers
transferred exactly, in the same tool→rule pairings.

Leakage: zero hits for Global Shop Solutions, Axon, Pervasive/Zen, AWS Secrets Manager, ADR
numbers, the emerald/amber/rose/slate palette, `src/uiTheme.ts`, `EmitAsync`,
`build/test-results/`, or "this repository"/"our codebase" deixis. Notable: the source
itself carries single-repo framing at CODING L8 and L60; the port generalized both away via
the Precedence and Owned-vs-bound framing rather than carrying them forward.

Nine findings raised, all nine fixed rather than accepted:

- `craft-tdd` — restored "flesh out the test concepts first" as its own design step
  (distinct from writing one failing test); restored the explicit "non-negotiable" severity
  marker on run-tests-before-push; restored a concrete illustration of *why* the emitter's
  interface is public (change-data-capture feed, third-party queue, vendor API); reframed
  the visibility flag so the generic concept leads and `InternalsVisibleTo` is the .NET
  example — unlike WireMock/Testcontainers it is not a cross-language tool, so naming it
  first was genuine leakage.
- `craft-code-quality` — restored "linting and analysis are aggressive by intent" (the one
  outright MISSING concept); restored "the build fails on lint violations" as a properly
  converted owned-vs-bound duty rather than a silent drop; restored version-pinning to the
  Done criteria checklist, not just to general practice; restored the "mocks, stubs, or
  spies" test-double vocabulary the Architecture section had narrowed to "mocks"; restored
  the budgets' rationale — force decomposition early, while splitting is still cheap — in
  both the skill body and the reference tables.

Note on the coverage bar: this repo has no application code and no test suite, so
line/branch coverage is undefined here. Concept coverage against the source doctrine is the
measurable analogue and is what the numbers above report.
