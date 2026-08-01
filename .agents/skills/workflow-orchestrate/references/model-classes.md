# Model classes — lanes, tiers, roles

Vendors ship models faster than doctrine can be rewritten. So doctrine names **tiers**, a
roster names **models**, and only the roster changes. A tier name in a briefing or a task line
is correct forever; a model name in either is a maintenance debt.

## The three concepts

| Concept | What it is | Examples |
|---------|-----------|----------|
| **lane** | a provider family plus **how it is dispatched** | `anthropic` (native, via the Agent tool's `model:`), `ocx-openai` (routed, via `agentType: ocx-*`) |
| **tier** | a capability class *within* a lane — what the model is | `flagship` · `workhorse` · `fleet` |
| **role** | the job it does in an orchestration | `consultant` · `orchestrator` · `worker` |

### Tiers

- **`flagship`** — top of a lane. Hardest reasoning, widest solution space, adjudication of
  forks, review of a plan you are too close to. Expensive; used for judgment, not volume.
- **`workhorse`** — the balanced agentic default. Long-horizon coordination, multi-file
  reasoning, synthesis across worker results. This is where the orchestrator sits.
- **`fleet`** — fast and cheap enough to run many at once. Well-scoped execution, research
  sweeps, mechanical bulk. The tier that does most of the actual work.

Tiers are ordered by capability and cost, and they are **not interchangeable downward**: a
task that needs `flagship` judgment is escalated or blocked, never quietly handed to `fleet`.

### Roles

Default `consultant→flagship`, `orchestrator→workhorse`, `worker→fleet`. Re-point in the
overlay:

```yaml
roles:
  orchestrator: flagship   # this workflow's work is design-heavy
```

## Resolution order

Per tier, first hit wins:

1. **`workflows/<workflow>/<target>/roster.md`** (or, for a legacy run, `.workflow/<slug>/
   roster.md`) — what *this run* resolved. Authoritative for the life of the run, including
   cold continuations: a resumed run does not silently change fleets mid-flight.
2. **`.agents/orchestrate/roster.local.yaml`** — the workflow's standing preference and local
   roster additions. Derivation-owned, unmanaged, committed; `workflow-template-sync update`
   never touches it.
3. **The seed roster below**, filtered by what runtime discovery actually finds available.

## Per-tier lane preference

The overlay's main job. Each tier gets an **ordered** lane list; the first available lane fills
it:

```yaml
# .agents/orchestrate/roster.local.yaml
prefer:
  flagship:  [anthropic, ocx-openai]   # keep judgment native, fall back if unavailable
  workhorse: [anthropic]               # single lane: no fallback, fail loudly instead
  fleet:     [ocx-openai, anthropic]   # run the fleet on the cheaper routed lane

roles:
  orchestrator: workhorse              # optional role→tier override

lanes:                                 # optional: teach a lane this file has never heard of
  vendor-x:
    dispatch: agentType                # 'model' | 'agentType'
    tiers:
      flagship: some-agent-name
      fleet:    [another-agent, cheaper-agent]
```

A copy-ready version of this file ships at `.agents/orchestrate/roster.local.yaml.example` —
copy it to `roster.local.yaml` to activate it.

Rules:
- A tier with **one** lane and that lane unavailable is a **hard stop for that tier** — report
  it, do not substitute a different tier.
- Falling back to a later lane in the list is allowed, and is **recorded in the session roster
  and stated to the user**. Silent substitution is suppression.
- Preference is about *lanes*, never about skipping tiers.

## Runtime discovery

Discover; do not assume. The roster below is a seed, and this file's copy of it is already
aging.

**Native lane.** Read the `Agent` tool's own `model` enum in the current session — that is the
authoritative list of natively dispatchable classes for this harness version. As of writing it
is `opus | sonnet | haiku | fable`. If a name in the seed table is absent from the enum, the
harness cannot dispatch it; treat it as unavailable, not as a bug in the harness.

**Routed lanes.** Two things must both hold:
- The routed agent types exist in this session's available-agent-types list (they are generated
  by `ocx claude` into `~/.claude/agents/ocx-*.md`).
- The gateway is actually up. Check with `/workflow-gateway`; `ocx models live` lists the models
  the proxy will serve.

If a routed lane is preferred but its gateway is down, fall back per `prefer:` and say so.

## Classifying a model this file has never heard of

The common case, by design. Rules:

1. **Classify by the vendor's own published tier statement**, in their release material.
   Vendors that ship tiers say which is which.
2. **Never infer a tier from a name, a version number, or ordering.** A higher number is not a
   higher tier; a pretty codename carries no capability information. Two models in one release
   may sit in different tiers, and a later release may add a tier that did not exist before.
3. **Never infer a tier from a benchmark table alone** — a model can top one index and trail
   two tiers down on another. Vendor tier statement first; benchmarks only break ties within a
   tier.
4. **Unresolvable → ask the user once** (`AskUserQuestion`), then write the answer into
   `.agents/orchestrate/roster.local.yaml` so it is never asked twice.
5. **An unclassified model is not dispatched.** Guessing a tier is how frontier judgment work
   ends up on a bulk model without anyone noticing.

## Seed roster

**Data, not doctrine. Verified 2026-07-30 — assume it is stale and re-check discovery.**

| tier | `anthropic` (via `model:`) | `ocx-openai` (via `agentType:`) |
|------|---------------------------|---------------------------------|
| `flagship` | `fable` | `ocx-gpt-5-6-sol` |
| `workhorse` | `opus` | `ocx-gpt-5-6-terra` |
| `fleet` | `sonnet`, `haiku` (cheap end) | `ocx-gpt-5-6-luna`, `ocx-gpt-5-4-mini` (cheap end) |

Provenance for the routed lane: GPT-5.6 ships Sol (flagship) / Terra (balanced) / Luna
(fast-cheap) as *durable capability tiers advancing on their own cadence* — exactly the shape
this file models — GA 2026-07-09, <https://openai.com/index/gpt-5-6/>.

## Dispatch mechanics

Tier chooses *who*. These choose *how*.

**Native lane** — `Agent` tool with an explicit `model:`.

**Routed lane** — `Agent` tool with `agentType: ocx-<model>`. The routed agent's real model is
**pinned in its own definition; the `model:` argument is ignored.** Pass `agentType:` and treat
`model:` as a placeholder. Relying on `model:` for a routed lane sends the work to a model you
did not choose, and nothing in the transcript will say so.

**Effort is the second dial.** Tier alone under-specifies a dispatch: set `effort` `low` for
mechanical slices, `high`/`xhigh` only for genuinely hard ones. A `fleet` worker at `high`
effort beats a `workhorse` at default on many well-scoped tasks, at lower cost.

**Other mechanics**
- **Parallelism follows independence, not tier.** Every ready task goes out in one message
  regardless of which lanes they land in.
- **Worktree isolation** only when multiple workers mutate the same repo concurrently — skip it
  for read-only fan-out, it costs setup and disk. The Agent tool's `isolation: 'worktree'` flag
  isolates the *session's own* repo, which is correct only when that is also the repo being
  mutated; in a workflow-over-substrate layout it isolates the wrong repo and fails as a silent
  no-op. Full procedure and the hand-cut alternative: `references/worktrees.md`.
- **Agent types over raw tiers** where a specialist fits better than a capability class —
  `Explore` for broad read-only search, `Plan` for design.
- **Routed lanes have skills blocked** (their generated definitions name which — e.g.
  `claude-api`). Do not brief a routed worker to invoke a blocked skill; give it the facts
  inline or dispatch that slice to the native lane.
- **Every worker starts cold.** A briefing carries: the task's acceptance test, the paths it
  may touch, the bound repo's law that applies, and what to return as evidence. Tier is not a
  substitute for a briefing.
