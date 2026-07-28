---
name: workflow-gateway
description: >-
  Manage the local opencodex model gateway — start/stop/status and the opt-in
  ANTHROPIC_BASE_URL session override. Use when asked to route Claude through another
  model provider or manage opencodex.
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
wants Claude Code routed through opencodex must opt in explicitly, every time. This
skill's `gateway.sh env` only *prints* the override — it never exports it into your
shell or writes it anywhere persistent. The launch pattern is always one of:

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

## Commands

```sh
.agents/skills/workflow-gateway/gateway.sh status   # is the server up? prints the port
.agents/skills/workflow-gateway/gateway.sh start    # start it in the background, idempotent
.agents/skills/workflow-gateway/gateway.sh stop     # stop it
.agents/skills/workflow-gateway/gateway.sh env      # print the exact opt-in export line
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
