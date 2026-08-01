# The core names no model provider

2026-08-01. Core v37.

## Decision

The core ships the native lane and nothing else. `/workflow-gateway` is deleted, its two
scripts and its stub with it. `opencodex` leaves the init RECOMMENDED set. No
provider-specific agent name appears in law, in a skill body, in a reference, in an
example roster, or in the README.

The generic `lanes:` key in `roster.local.yaml` stays. A derivation that wants a routed
lane declares one there, in the overlay slot that exists for exactly this.

## Why

A tier is an abstraction over models. The moment the core names a provider, the
abstraction is decorative: every reader learns the concrete name, doctrine is written
against it, and the roster indirection carries no load. A derivation then inherits a
dependency on a service it never chose, in files it may not edit.

Naming no provider makes the tier the only handle there is. A derivation binds tiers to
whatever it runs, and the core stays true whatever that is.

## Consequence

- A routed lane is now expressed, never installed. Nothing about it is mandated.
- Presence in an available-agent-types list remains necessary, not sufficient — a routed
  agent whose backing service has no credential fails at dispatch, not at discovery.
  Check a lane with the provider's own health command before the first batch.
