---
name: workflow-gateway
description: >-
  Manage the local opencodex model gateway — start/stop/status, the opt-in
  ANTHROPIC_BASE_URL session override, and launching Claude Code as a routed/tracked
  sub-harness (claude-gw.sh) from an outer agent harness like OpenCode. Use when asked
  to route Claude through another model provider, manage opencodex, or launch Claude
  Code from another harness with gateway tracking.
---

# workflow-gateway

opencodex (https://github.com/lidge-jun/opencodex, npm `@bitkyc08/opencodex`, CLI `ocx`)
is a local proxy that can route Claude Code (and Codex, and Claude Desktop) traffic
through 40+ alternate LLM providers. This skill manages the local gateway *process* —
start/stop/status — and prints the session override that points Claude Code at it. It
does **not** install opencodex; that's `workflow-init`'s job (`init.sh decide opencodex
install && init.sh`) — this skill's `gateway.sh` fails with a clear pointer at that flow
if `ocx` isn't on PATH.

## The cardinal rule: strictly opt-in, per session, never global

**Never set `ANTHROPIC_BASE_URL` by default, globally, or in any shell rc file, `~/.claude`
config, or other place that would make it apply automatically.** Every session that
wants Claude Code routed through opencodex must opt in explicitly, every time. Nothing
in this skill ever exports the override into your shell or writes it anywhere
persistent.

Two recommended patterns, straight from the tool itself, cover almost every case:

```sh
# recommended: opencodex's own wired launcher — ensures the proxy is running, then
# execs claude with the base URL, auth token, and gateway model discovery all wired
# (routed models show up in Claude Code's native /model picker)
ocx claude [claude args...]

# recommended: run the gateway as a persistent background service instead of
# starting it per-session (see "Running the gateway as a persistent service" below)
ocx service
```

The manual override remains the minimal form — useful when you want to see exactly
what's being set, or `ocx` isn't installed yet:

```sh
# one-shot: applies to exactly this invocation
ANTHROPIC_BASE_URL=http://127.0.0.1:10100 claude

# or: applies to exactly this one shell, until you close it
export ANTHROPIC_BASE_URL=http://127.0.0.1:10100
claude
```

Why this matters: opencodex is a **third-party proxy sitting directly in the path of
every LLM request** a routed session makes. That's a deliberate, session-scoped choice
the user makes each time they want it — not a standing default this skill (or anything
else) should quietly install for them. See `workflow-init`'s SKILL.md for the same
provenance note at install time (individual maintainer, ~5.5k GitHub stars — legitimate
and actively maintained, but a materially different trust posture than a dependency like
`yq`).

## Claude Code as a sub-harness (from OpenCode or any outer agent)

When something other than a human shell launches Claude Code — most commonly an
**outer agent harness** like OpenCode spinning up Claude Code as an independent inner
harness for a sub-task — and gateway routing/tracking is wanted for that inner
process's traffic, the rule is:

**Invoke `.agents/skills/workflow-gateway/claude-gw.sh [claude args...]` — never a bare
`claude` with a hand-typed env override.**

```sh
.agents/skills/workflow-gateway/claude-gw.sh -p "..."
.agents/skills/workflow-gateway/claude-gw.sh --add-dir /some/repo
```

`claude-gw.sh` is the deterministic, scriptable equivalent of the two patterns above:
it prefers delegating straight to `ocx claude "$@"` (ensures the proxy, wires the full
env + model discovery), falling back to an `ocx ensure`-then-manual-override exec only
if `ocx claude` isn't available. Either way, the override/injection is scoped to
exactly the `claude` process it execs — the outer harness's own provider config is
untouched, and nothing here writes to a shell rc file or persists beyond that one
launch. This keeps the cardinal rule (strictly opt-in, never global) intact even when
the "session opting in" is a one-shot automated launch rather than an interactive
shell.

Note: OpenCode reads `AGENTS.md` natively, so an OpenCode session working inside a
workflow repo (or a repo bound to one) already sees this doctrine without any extra
wiring — it's the same file this skill's own doctrine lives beside.

## Running the gateway as a persistent service

Instead of starting the gateway per-session (`gateway.sh start`, or the ad hoc `ocx
ensure` inside `ocx claude`/`claude-gw.sh`), opencodex can run itself as a standing
background service:

```sh
ocx service           # install/update and start the background service (default)
ocx service status    # diagnostics + log path
ocx service stop
ocx service uninstall
```

This is a per-machine, standing decision (install the service once, it then just runs)
— distinct from the cardinal rule above, which is about the Claude Code-facing env
override staying opt-in *per session*. Running opencodex as a service doesn't change
that: routing Claude Code through it still requires `ocx claude`, `claude-gw.sh`, or the
manual override, every time. Check `ocx status` / `ocx health` to confirm the service
is up; see its own diagnostics for how it registers itself on your OS (systemd, launchd,
Windows service, or a WSL-appropriate fallback — `ocx service status` reports what it
actually did on the current machine).

## Tracking the inner harness's traffic

Once a session is routed through the gateway (via `ocx claude`, `claude-gw.sh`, or the
manual override), its traffic is observable through opencodex's own tooling:

```sh
ocx observe usage         # per-request usage log (provider/model, status, latency)
ocx observe claude-inbound # Claude-specific inbound debug capture (ocx debug claude on)
```

This is how you confirm a launched sub-harness's requests actually reached the gateway
— look for its entries in `ocx observe` rather than trusting the launch alone.

## Commands

```sh
.agents/skills/workflow-gateway/gateway.sh status   # is the server up? prints the port
.agents/skills/workflow-gateway/gateway.sh start    # start it in the background, idempotent
.agents/skills/workflow-gateway/gateway.sh stop     # stop it
.agents/skills/workflow-gateway/gateway.sh env      # print the exact opt-in export line
.agents/skills/workflow-gateway/claude-gw.sh [args] # launch claude as a routed/tracked
                                                     # sub-harness — see the section above
```

- **`status`** — resolves the configured port (from `~/.opencodex/config.json`'s `port`,
  falling back to opencodex's documented default `10100`) and checks whether something
  is answering there.
- **`start`** — idempotent: a no-op if already up. Otherwise launches `ocx start
  --port <port>` in the background (`nohup ... & disown`) and polls for up to 5 seconds
  for it to come up. Logs go to `~/.opencodex/logs/gateway.log` — check there first if
  start fails or the server behaves unexpectedly.
- **`stop`** — `ocx stop`.
- **`env`** — prints (never exports) the line to opt a session in:
  `export ANTHROPIC_BASE_URL=http://127.0.0.1:<port>`. This is the verified override:
  opencodex serves the Anthropic Messages API at `/v1/messages` off the same base URL
  Claude Code is pointed at — you set the bare `http://127.0.0.1:<port>` and the client
  (Claude Code / the Anthropic SDK) appends the path itself. No other env var is
  required for the default loopback setup; opencodex only requires
  `ANTHROPIC_AUTH_TOKEN` when the proxy itself is configured to demand a key (not the
  case for a fresh local install), and only requires `OPENCODEX_API_AUTH_TOKEN` if you
  bind the gateway beyond loopback (`hostname: "0.0.0.0"` in its config) — a
  configuration this skill's `start` never does for you.

## Configuring providers

Provider configuration (which upstream LLM providers opencodex routes to, and under
which model aliases) lives entirely in `~/.opencodex/config.json` and is opencodex's own
concern — see https://github.com/lidge-jun/opencodex and its docs
(https://opencodex.me/reference/configuration/) for the schema. This skill doesn't
duplicate that reference; it only manages the local process and the Claude Code-facing
override.

## Troubleshooting

- **`gateway.sh status` says DOWN** → `gateway.sh start`, then check
  `~/.opencodex/logs/gateway.log` if it still doesn't come up within 5 seconds.
- **`ocx` not found** → opencodex isn't installed on this machine. This skill won't
  install it — run `.agents/skills/workflow-init/init.sh decide opencodex install &&
  .agents/skills/workflow-init/init.sh`.
- **`start` fails immediately / exits before the port ever comes up** → almost always
  missing/invalid provider configuration in `~/.opencodex/config.json` (a fresh install
  has no providers configured yet). Check the log file `start` points you at — the
  first-run experience is opencodex refusing to serve traffic with no providers
  configured, not a silent hang.
- **Claude Code doesn't seem to route through the gateway after exporting the override**
  → confirm the export happened in the *same* shell/process that launched `claude` (it's
  intentionally not persistent — see the cardinal rule above), and that `gateway.sh
  status` shows UP.
- **`claude-gw.sh`/`ocx claude` with no providers configured in `~/.opencodex/config.json`
  yet (before `ocx setup`/`ocx login`)** → don't assume this always fails loudly:
  opencodex may still serve the request via an `anthropic-native` passthrough route
  (visible as `anthropic-native/<model>` in `ocx observe usage`) using Claude Code's own
  existing auth, rather than erroring. Either outcome — a clear provider error, or a
  working passthrough — is a correct result of the proxy having no *custom* provider
  configured; check `ocx observe usage` to see which one actually happened rather than
  assuming from the exit code alone.
