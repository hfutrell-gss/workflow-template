---
name: workflow-plugins
description: >-
  The registry for optional capability a workflow repo consumes as a Claude Code PLUGIN
  rather than as a pack: which plugins this repo wants, why, what a review of each one
  found, and which ones a given user has declined. Declares the shared default set in
  plugins.yaml, renders it into .claude/settings.json, and records a per-user opt-out with
  its reason. Use when adding or removing a plugin, when deciding whether something should
  be a plugin or a pack, when a user wants to decline a plugin the repo enables, or when a
  skill that should exist does not resolve.
---

# workflow-plugins

Packs are how this system installs capability it owns. **Plugins are how it consumes
capability it does not.**

## Which one

> **Would we send a pull request to change it?**
>
> Yes → **pack**. No → **plugin**.

A pack is an opinion this system holds and would correct at the source. A plugin is
somebody else's product, on its own release cadence, that we use and do not steer.

## What a plugin does not get

A pack is bound by composition law (`AGENTS.CORE.md` "Composition"). A plugin is bound by
none of it, and this is the whole cost:

| Missing | Consequence |
|---|---|
| no `pack.yaml` | `PACK-001` cannot see its paths. A collision with anything is silent |
| no `scan` gate | whatever it ships — hooks, agents, scripts — arrives unexamined unless a person examines it |
| no `packs.lock` | nothing records that it is installed, or at what version |
| no overlay slot | its opinions are accepted or uninstalled. There is no `.agents/<plugin>/` the ladder consults |

Two duties by hand replace all four:

1. **Declare it** in `plugins.yaml`, with a `reviewed:` block. An undeclared dependency
   cannot be audited or reproduced.
2. **Read what it executes before installing.** **Hooks first** — a hook runs without
   anyone invoking it, on every matching tool call, in every project where the plugin is
   active. Then network calls, then credentials and environment reads. Write what you
   found into `reviewed:`, so the next person inherits the review instead of repeating it
   or skipping it.

A plugin executes arbitrary code with your privileges. Nothing here is a boundary — the
review is a person, and at this scale a person is the only control there is.

## The files

Four, and each answers one question:

| File | Question | Committed |
|---|---|---|
| `plugins.yaml` | what does this repo want, and what did the review find | yes |
| `.claude/settings.json` | what is on by default, for everyone | yes, **generated** |
| `.agents/plugins/plugins.local.yaml` | what has *this user* declined, and why | **no** — per-machine |
| `.claude/settings.local.json` | the decline, in the form the harness reads | no — generated |

**`.claude/settings.json` is generated. Never hand-edit it.** Two sources of truth for
the default set is exactly the drift `PLUGIN-001` exists to catch, and the hand-edit is
the one that wins silently.

### `plugins.yaml` — the registry

Derivation-owned and committed, like `packs.yaml` and `binds.yaml`. Not managed: `update`
never touches it.

```yaml
marketplaces:
  impeccable:
    source: { source: github, repo: pbakaus/impeccable }

plugins:
  - name: impeccable          # the marketplace entry's name
    marketplace: impeccable   # a key under marketplaces:
    default: true             # false = declared and reviewed, but nobody gets it
                              # until they enable it themselves
    why: >-
      One or two sentences. Not what it does — what this repo needed that it answers.
    reviewed:
      version: "4.0.4"
      date: 2026-08-01
      hooks: PostToolUse(Edit|Write|MultiEdit, 5s) and Stop(30s) run hook.mjs; needs Node >= 22
      egress: impeccable.style/api/chosen, anonymous, DO_NOT_TRACK opts out
      credentials: OPENAI_API_KEY, generate-image.mjs only, optional
      verdict: accepted
```

`reviewed:` is why this file exists rather than only `.claude/settings.json`. The
harness records *that* a plugin is enabled. Only this records that somebody looked at
what it executes, when, and at which version — the fact that decays fastest and costs
most to re-establish. `hooks:`, `egress:`, and `credentials:` are free-form: write
`none` when there are none, never leave the key out.

### Declining — the opt-out

A user declines for reasons the repo cannot anticipate and should not argue with: a
missing runtime, no appetite for a hook on every edit, no use for the capability, or
plain distrust of a third party. The repo declares a default; it does not compel.

Write `.agents/plugins/plugins.local.yaml` — per-machine, gitignored, the usual
`.agents/<name>/` overlay convention:

```yaml
decline:
  - name: impeccable
    why: no Node 22 on this machine, so the hook would no-op anyway
```

Then `plugins.sh render`. The decline lands in `.claude/settings.local.json` as
`"impeccable@impeccable": false`, and `/reload-plugins` applies it to the running session.

`/plugin disable` does the same thing to the harness in one step and is entirely
legitimate. What it does not do is record **why** — so `plugins.sh list` can only say
*missing*, and a session that finds the skill absent cannot tell whether to work around
the gap or report a broken machine. Use the overlay when the reason matters, which is
most of the time.

**Never commit the overlay.** It is one person's answer; committing it imposes that
answer on everyone and inverts the feature. `PLUGIN-004` checks this.

## Script

```sh
.agents/skills/workflow-plugins/plugins.sh list     # declared · enabled · declined · missing
.agents/skills/workflow-plugins/plugins.sh render   # registry + declines -> the settings files
.agents/skills/workflow-plugins/plugins.sh check    # PLUGIN-001..004; exit 0 clear, 2 unmet
```

`render` **merges**; it never overwrites. Both settings files hold unrelated keys
(`permissions`, `model`) that are not this skill's to touch. It is idempotent — running
it twice changes nothing — which is what `PLUGIN-001` compares the committed file
against.

Installing is the harness's job and cannot be scripted from here:

```
/plugin marketplace add <owner>/<repo>
/plugin                                  # then install from the list
/reload-plugins                          # apply without restarting
```

## Adding a plugin

1. Read what it executes. Hooks, then egress, then credentials.
2. Add it to `plugins.yaml` with `why:` and the full `reviewed:` block.
3. `plugins.sh render`, then commit `plugins.yaml` and `.claude/settings.json` together —
   the registry and its rendering are one change.
4. Install it through the harness, and `/reload-plugins`.
5. Make it reachable: a plugin nothing points at is a plugin nobody uses. Name it in the
   workflow's TTPs at the step where it applies, and say what a session should do when it
   does not resolve.

## Constraints

Owned here, registered in `workflow-check/references/constraints.md`, reported by
`plugins.sh check`:

| ID | Constraint |
|----|------------|
| `PLUGIN-001` | `.claude/settings.json` matches what `render` would write |
| `PLUGIN-002` | Every declared plugin has `why:` and a `reviewed:` block with a `verdict:` |
| `PLUGIN-003` | Every declined plugin names a reason |
| `PLUGIN-004` | `.agents/plugins/plugins.local.yaml` is not tracked by git |

A repo with no `plugins.yaml` is skipped silently. No plugins is a complete state, not a
degraded one.
