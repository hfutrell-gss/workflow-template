#!/usr/bin/env bash
# claude-gw.sh — the deterministic entrypoint an OUTER agent harness (OpenCode, or any
# other) calls instead of a bare `claude` when it wants the launched Claude Code process
# routed through the local opencodex gateway (and therefore tracked/observable via
# `ocx observe`). See SKILL.md, section "Claude Code as a sub-harness", for the doctrine
# this implements.
#
# Usage: claude-gw.sh [claude args...]  — every argument is passed straight through to
# claude, including --model, slash-command prompts, and streaming flags, e.g.:
#   claude-gw.sh -p "..."
#   claude-gw.sh -p --model claude-ocx-native--gpt-5.6-sol "..."
#   claude-gw.sh -p --verbose --output-format stream-json "/workflow-agents-sync"
#   claude-gw.sh --add-dir /some/repo
#
# Preferred path: delegate to `ocx claude` — opencodex's own wired launcher (see
# `ocx claude --help`). It ensures the proxy is running AND execs claude with
# ANTHROPIC_BASE_URL / ANTHROPIC_AUTH_TOKEN plus
# CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1 and model slots from
# config.claudeCode — routed models then show up in Claude Code's native /model
# picker. That's strictly more than the manual override this script falls back to,
# so it's used whenever available.
#
# Fallback path (ocx installed but its `claude` subcommand isn't available/behaving,
# e.g. an older opencodex): ensure the gateway ourselves (`ocx ensure`, falling back
# to this skill's gateway.sh start logic), then exec claude with a bare
# ANTHROPIC_BASE_URL override. Either way the override/injection applies ONLY to the
# `claude` process this script execs — never to the caller's shell, never persisted
# anywhere. This is the same opt-in-per-invocation rule as gateway.sh's `env`
# subcommand, just expressed as an exec instead of a printed line, because here the
# "session" opting in is the one-shot sub-harness launch itself.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="$HOME/.opencodex/config.json"
DEFAULT_PORT=10100

have() { command -v "$1" >/dev/null 2>&1; }

require_ocx() {
  have ocx && return 0
  cat >&2 <<'EOF'
error: opencodex ('ocx') is not installed on this machine. It's a RECOMMENDED-tier,
opt-in tool (see workflow-init's tool tiers) — install it with:
  .agents/skills/workflow-init/init.sh decide opencodex install
  .agents/skills/workflow-init/init.sh
EOF
  exit 1
}

# Resolves the proxy port: ~/.opencodex/config.json's "port" if present and readable,
# else opencodex's own documented default (10100). Only used by the fallback path —
# `ocx claude` resolves its own port internally.
resolve_port() {
  if have yq && [ -f "$CONFIG" ]; then
    local p
    p="$(yq -r '.port // empty' "$CONFIG" 2>/dev/null || true)"
    if [ -n "$p" ] && [ "$p" != "null" ]; then
      echo "$p"
      return
    fi
  fi
  echo "$DEFAULT_PORT"
}

# Fallback-path gateway ensure: prefer `ocx ensure` (starts the proxy synchronously
# and idempotently, also refreshes Codex config/cache; exits 0 whether the proxy was
# already up or just came up). Fall back to this skill's own gateway.sh start logic
# (background nohup + poll) if `ocx ensure` fails.
ensure_gateway() {
  if ocx ensure >&2; then
    return 0
  fi
  echo "ocx ensure failed — falling back to gateway.sh start" >&2
  "$SCRIPT_DIR/gateway.sh" start >&2
}

require_ocx

if ocx claude --help >/dev/null 2>&1; then
  # Preferred: opencodex's own launcher — ensures the proxy AND wires the fuller env
  # (base URL, auth token, gateway model discovery) than the fallback below.
  if [ "${ANTHROPIC_API_KEY:-}" = "oauth-placeholder" ]; then
    # OpenCode agent tool subprocesses may inject this sentinel. Claude Code treats any
    # ANTHROPIC_API_KEY as higher precedence than the user's claude.ai login, so remove
    # only the known non-secret placeholder before launching the inner Claude harness.
    exec env -u ANTHROPIC_API_KEY ocx claude "$@"
  fi
  exec ocx claude "$@"
fi

# Fallback: ocx is installed but its `claude` subcommand isn't available/behaving.
ensure_gateway
port="$(resolve_port)"
if [ "${ANTHROPIC_API_KEY:-}" = "oauth-placeholder" ]; then
  exec env -u ANTHROPIC_API_KEY ANTHROPIC_BASE_URL="http://127.0.0.1:${port}" claude "$@"
fi
exec env ANTHROPIC_BASE_URL="http://127.0.0.1:${port}" claude "$@"
