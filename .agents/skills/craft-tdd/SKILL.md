---
name: craft-tdd
description: >-
  Test-first delivery discipline: write the failing test before the production code, prove
  hypotheses with reproducible tests, prefer integration tests against real infrastructure,
  never mock business logic, mock only external unmanaged dependencies at their seams. Use
  when a bug is reported, a feature is requested, before writing or changing production
  code, when writing or fixing tests, when debugging behavior, or when validating
  acceptance criteria.
---

# craft-tdd

## Precedence

Defaults, not supremacy:

1. **A bound repo's own law wins inside its boundaries** (`AGENTS.CORE.md`, bind law) — read
   its `AGENTS.md` and its test conventions first.
2. **This workflow's overlay wins over these defaults** — if
   `.agents/craft/tdd.local.md` exists, read it; where it conflicts with this file, it wins.
3. **Where both are silent, everything below applies in full force.**

Hedged once, here. The rest of this file is imperative on purpose.

## The rule

Test first. Not optional. It is the mechanism by which assumptions get validated.

**Sequence, always: rules → failing test → implementation → pass → triangulate.**

- A bug is reported, or a feature is requested → the **first** step is a failing test that
  proves the problem exists or defines the expected behavior.
- For a new addition, **flesh out the test concepts first** — enumerate what needs proving
  before writing any single test. This is a design step, distinct from writing one failing
  test, and it is where the shape of the work gets decided.
- Do not write production code until a test fails. Acknowledging this rule and then going
  straight to implementation is a violation of it, not a shortcut through it.
- Without a test you are speculating. Speculation is not engineering.

Apply it to everything that admits a test. Bug report → failing test. Feature → failing
test. Refactor → cover the existing behavior *before* touching it. Performance concern →
benchmark test.

## Why it earns its cost

Tests are the shared language and the institutional memory between human and agent.

- **They capture understanding.** Something figured out together gets locked in; the test
  remembers so neither party has to.
- **They enable fearless iteration.** With real coverage, refactor and extend without fear —
  the suite reports breakage immediately.
- **They are documentation that runs.** Comments lie and docs drift; a passing test proves
  the system behaves as claimed.
- **They show the work.** A test written first makes expectations inspectable before code
  exists — alignment before building, not after.
- **They compound.** Each test makes the next change safer and faster.

## Principles

1. **PoC or GTFO.** If you cannot construct a failing test around a hypothesis, the
   hypothesis is false. A claim without a reproducible test is not actualized — applies to
   every assumption, bug report, and feature request.
2. **Target.** Given a failing test, make it pass **only** through a narrow, focused
   implementation. Until the test passes, the fix does not exist.
3. **Triangulate.** Add tests that modify the scenario, proving the implementation is not
   overfit to the first case.
4. **Boundaries.** Two is many; nulls are expected. Test zero, one, many, null, empty, max.
5. **Corner cases.** Null is expected, comms will be lost, nothing is guaranteed. What
   happens on enormous unexpected input? Under concurrent access? Consider all
   considerations.

## Run the suite once; analyze the stored output many times

- Redirect test output to a file. Analyze the file.
- To find failures, `grep`/`rg` the output file. Do not re-run the suite.
- For counts, error messages, or stack traces: grep the output, or read the structured
  reports the stack emits (JUnit XML, HTML reports, coverage output) under whatever
  directory the build writes them to.
- Re-running a full suite to extract different information from the same run is waste. Run
  once, analyze many times.

## Composition

- **Never mock business logic.**
- **Never mock handlers.**
- **Never mock routing.**
- **Never mock the database.** Test against a real database — in integration tests only.
- A mock is used only where required, never by default.
- **Always resolve test objects through dependency injection.** Do not construct them
  inline; register them in the container or produce them from a helper factory. Hand-built
  test objects drift from what the application actually composes.

## Prefer integration tests, and prioritize the fixture

- Integration tests exercise a **running application**.
- The application is hosted **in the fixture**.
- Override services in the fixture — not in individual tests.
- Use context and configuration that let the application itself serve as the fixture.

**Test at the real boundary:**

| Subject | Driven by |
| --- | --- |
| Event-driven service | emitting events through the stack's own emission mechanism |
| Endpoint | calling the endpoint |

## Real infrastructure

- Integration tests use production technology (e.g. the actual database engine) via
  container-based test infrastructure — Testcontainers or the stack's equivalent.
- Prefer containers whenever available. Do **not** silently skip container-backed tests
  because a container runtime is missing — a container runtime is an expected part of the
  test environment. A missing one is a finding to surface, not a test to skip.
- For production infrastructure that cannot run in a container, stand up a protocol-level
  fake (WireMock or equivalent).

## Mocking, precisely

- The only legitimate mock target is an **external unmanaged dependency (EUD)**.
- Every EUD has an interface. That interface **is** the seam. Mock the interface, never the
  logic behind it.
- Mock shapes: **stub** (supplies input), **spy** (records output), **bomb** (fails on
  demand).
- Register mocks in the container so they are transparent to both the test suite and the
  application.
- Testing **output to** an EUD → use a spy.
- Testing **input from** an EUD → use a stub with randomized data and validation.

## Assertions

- Never assert against magic values.
- A stub that introduced data owns a store; assert against that store.
- Randomize all data where possible. Randomization is what proves the assertion tests
  behavior rather than a hardcoded coincidence.

## Hard-to-test shapes: polling

Polling services are hard to test. The better design is usually an endpoint driven by a
scheduler, which is testable at the endpoint.

Where a polling service is used anyway, separate the concerns:

**Thin poller + testable emitter.**

1. **Poller** — a timer that calls the emitter on an interval. ~10-15 logical LOC in its
   execute body. No business logic. Not registered in tests (exclude hosted services in the
   fixture).
2. **Emitter** — holds all the logic for reading data and emitting events. Internal class
   behind a public interface, because it adapts an external system (a change-data-capture
   feed, a third-party queue, a vendor API). That external adapter role is *why* the
   interface is public, not a style preference. Registered in the container so tests
   resolve it and call it directly.

Rules: pollers emit events; pollers are not tested directly; the **handling** of emitted
events is what gets tested; a poller manages polling and nothing else.

## Before committing

Run the tests locally first. Never commit and push untested. If CI fails on something that
passed locally, investigate the environment difference — do not retry blindly. Pushing
untested code burns CI and blocks deployments. **This is non-negotiable.**

## CODE FLAGS

Any of these is an **architecture** flag, not a testing inconvenience. Surface it; do not
work around it silently:

- Requiring a module- or assembly-level visibility escape so tests can reach internals
  (`InternalsVisibleTo` in .NET; whatever the stack's equivalent is, where one exists at
  all).
- Widening an individual type's visibility in order to test it.
- Probing internal state instead of using a spy.
- Domain or unit tests that require the data layer.
- Logic living in the UI.

Each means the seam is in the wrong place. Report it with the test that exposed it.

## Related

- `craft-code-quality` — the architecture rules that make code testable in the first place
  (ports and adapters, seams at every EUD, LOC budgets). Testability problems usually
  surface there first.
