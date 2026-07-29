---
name: craft-code-quality
description: >-
  Production code-quality doctrine: small cohesive modules with per-language LOC budgets,
  mandatory lint and static analysis, ports-and-adapters architecture with seams at every
  external dependency, pragmatic SOLID and DDD, no implicit fallbacks, and required
  observability (structured logs, telemetry, domain events, audit trails). Use when writing
  or refactoring production code, reviewing a diff or PR, deciding where a module boundary
  goes, judging whether a file or function is too large, or checking whether a change is
  done.
---

# craft-code-quality

## Precedence

Defaults, not supremacy:

1. **A bound repo's own law wins inside its boundaries** (`AGENTS.CORE.md`, bind law) — read
   its `AGENTS.md`, its linter configs, and its existing patterns before applying anything
   here.
2. **This workflow's overlay wins over these defaults** — if
   `.agents/craft/code-quality.local.md` exists, read it; where it conflicts with this file,
   it wins. That file is where a derivation records its own budgets, palette, stack
   conventions, and exemptions.
3. **Where both are silent, everything below applies in full force.**

Hedged once, here. The rest of this file is imperative on purpose.

## Owned vs bound

The distinction the source doctrine lacked, and the one that matters most:

| | Repos this workflow owns | Substrate bound into the session |
| --- | --- | --- |
| Missing lint config | a blocker — wire it before feature work | a finding — surface it, propose wiring it, do not install uninvited |
| Conflicting standard | change it deliberately | the repo's standard is the standard |
| Over-budget file | decompose | flag, and do not make it worse |

Never silently proceed as though a missing standard did not matter. **Surface, don't
suppress** — the universal principle, applied to code quality.

## References

Loaded on demand — read the one the task needs, not all of them:

| File | Read when |
| --- | --- |
| [references/loc-budgets.md](references/loc-budgets.md) | checking concrete size limits for a specific language, or wiring lint/static-analysis tooling — per-language soft/hard maxima, required tooling, rule mappings |

## Core standard

- Prefer many small, cohesive modules over large multi-purpose files.
- A 4k LOC file is an architecture smell, not a neutral implementation detail.
- Optimize for readability, testability, and safe change over short-term speed.
- Aim toward SOLID, DDD, TDD, and Clean Code **without dogma**. Use judgment — but do not
  let convenience become long-term entropy.

## Modularity and size

- One module, one reason to change.
- Use **per-language** budgets, never a one-size-fits-all limit — the numbers are in
  `references/loc-budgets.md`. Before calling work done, check the file and function sizes
  you touched against the budgets for that language.
- Those budgets are deliberately stricter than common linter defaults. The point is to
  **force decomposition early**, while splitting is still cheap — not to describe what
  existing code happens to measure.
- Soft max crossed → explicit written rationale plus a decomposition plan.
- Hard max crossed → do not produce it. If circumstances force it, flag it as a violation
  with the plan to split, never as an accepted state.
- New work must not grow an already-over-limit file without extracting at least one coherent
  slice.
- Organize by behavior and domain boundary, not by arbitrary technical bucket.
- Rare, explicit exceptions: generated code, migration snapshots, protocol schemas,
  framework-mandated glue.

## Lint and static analysis

Part of done, not a follow-up. **Linting and analysis are aggressive by intent** — a rule
set tuned to pass everything already written buys nothing. Where the workflow chooses the
configuration, choose the strict end.

- Locate the repo's lint setup before writing code — configs, CI invocation, editor
  settings. If it has one: **run it, and its rules are the rules**, not this file's.
- If it has none: surface the gap and propose wiring it (tooling and rule mappings in
  `references/loc-budgets.md`). In owned repos, wire it before feature work.
- Local and CI must run the same checks. Keep configuration in version control and pin tool
  versions.
- Warnings that encode a policy violation are treated as errors.
- **The build fails on lint violations.** In owned repos, wire it that way. In bound
  substrate, check whether the repo's build already enforces it — if it does not, that is a
  finding to surface, not a licence to ship violations past a green build.
- Run linters pre-commit or pre-push for fast feedback; run the full suite in CI on every PR.
- Where a tool cannot express a policy directly, enforce it with a custom rule or script.
- Never silently write unlinted code. Never install tooling into a repo uninvited — that is
  the repo owner's decision, made once and deliberately, not smuggled in per-change.

## Architecture

Default to **hexagonal architecture (ports and adapters)**.

- The domain core does not depend on frameworks, UI, transport, or persistence.
- Ports (interfaces) are defined at the application/domain boundary.
- Adapters live at the edge: database, HTTP, queues, files, third-party APIs.
- Wire dependencies in composition roots. Dependency direction points inward.
- New features arrive as vertical slices that preserve the boundary.
- **Every external unmanaged dependency (EUD) has a seam — a port — at the boundary.** Seams
  are the only place tests inject mocks, stubs, or spies (see `craft-tdd`).
- Do not over-abstract. Seams exist for real external boundaries, not for speculative
  indirection and not for internal objects.

**Deployment shape:** the default target is a modular monolith — one deployable core with
explicit internal module boundaries. One module or many, still one coherent monolith.

**UI boundary is mandatory** regardless of deployment model. Always segregate UI from a core
API boundary. That boundary may be HTTP, gRPC, or in-process public methods in a local
assembly — transport changes must not require a domain rewrite.

## SOLID, pragmatic

| Principle | In practice |
| --- | --- |
| Single Responsibility | one clear purpose per class/module |
| Open/Closed | extend by composition and new modules, not risky edits everywhere |
| Liskov Substitution | abstractions are genuinely swappable |
| Interface Segregation | small, task-specific interfaces |
| Dependency Inversion | depend on domain abstractions, not concrete infrastructure |

## DDD and boundaries

- Model business concepts explicitly in ubiquitous language.
- Domain logic lives in domain modules — not controllers, not UI, not adapters.
- I/O, HTTP, database, and messaging concerns stay in adapter layers.
- Cross-boundary translation is explicit (DTOs, mappers). Never implicit leakage.

## No implicit fallbacks

- Do not use fallback chains in service implementations. Fallbacks silently mask failures and
  create invisible coupling between components that should be independent.
- When a value is missing: return the caller's explicit default, or fail loudly. Never
  silently consult a secondary source.
- A service has **one** source of truth. If that source is unavailable, the correct response
  is to fail or to use the caller-supplied default — never to secretly delegate to a
  different provider.
- The only acceptable fallback is a deliberate, domain-specific algorithm — retry with
  exponential backoff, circuit breaker — where the fallback behavior is the **documented
  contract**, not a hidden implementation detail.
- Dependency registration must never rely on implicit ordering (e.g. "last singleton wins").
  If registration order matters, the design is wrong.

## Clean code

- Descriptive names over comments that explain unclear code.
- Short, intention-revealing functions.
- Avoid deep nesting — guard clauses and small composable helpers.
- Eliminate dead code and duplication when touching related areas.
- Fail fast with clear error messages at boundaries.

## Observability

Every feature carries explicit operational-visibility expectations.

- **Logs** — structured, with stable event names and key-value fields.
- **Correlation** — correlation and causation IDs in logs and traces, for end-to-end flow
  tracking.
- **Telemetry** — latency, throughput, error rate, saturation on critical paths.
- **Domain events** — required for meaningful business state changes. Explicit, in ubiquitous
  language, versioned when contracts evolve. Keep operational telemetry separate from
  business domain events.
- **Audit trails** — mandatory for security-sensitive or compliance-relevant actions. Capture
  actor, action, target, timestamp, outcome. Append-only and tamper-evident by design.
- **Never log** secrets, credentials, tokens, or regulated sensitive payloads.
- Changes to logging, telemetry, domain events, or auditing come with test coverage updates.

## Refactoring triggers

Any one of these is sufficient reason to stop adding and start extracting:

- Duplicate logic in 2+ places.
- A function exceeds clear mental scope.
- A module mixes responsibilities (domain + transport + persistence).
- A new feature requires touching too many unrelated files.

## Done criteria

- Sizes of touched files and functions respected against `references/loc-budgets.md`, or
  explicitly justified.
- Lint and static analysis located, run, and passing — or the gap surfaced as a finding.
- Required tooling installed and **version-pinned**, with config in version control.
- No policy-violation warnings remaining.
- Architecture boundaries intact: domain free of framework/transport/persistence, seams at
  every EUD, UI behind the API boundary.
- Observability expectations met for the change.
- Tests written first and passing (see `craft-tdd`).

## Related

- `craft-tdd` — the test-first protocol. Architecture and testability are the same problem
  seen from two directions; a CODE FLAG raised there is usually a boundary defect described
  here.
