#!/usr/bin/env bash
# workflow-gateway — manage the local opencodex model gateway (start/stop/status), and
# print the exact opt-in session override for routing Claude Code through it.
#
# opencodex (https://github.com/lidge-jun/opencodex, npm @bitkyc08/opencodex, CLI `ocx`)
# is installed via workflow-init's RECOMMENDED tier (`init.sh decide opencodex install`
# then `init.sh`) — see that skill for the install/vetting doctrine. This script assumes
# it's already installed; it never installs anything itself.
#
# CARDINAL RULE — strictly opt-in, per session, never global: this script's `env`
# subcommand only PRINTS the export line. Nothing here ever writes ANTHROPIC_BASE_URL
# into a shell rc file, ~/.claude config, or any other place that would make it apply by
# default. See SKILL.md for the full doctrine.
#
# Usage: gateway.sh status | start | stop | env | models
set -euo pipefail

CONFIG="$HOME/.opencodex/config.json"
DEFAULT_PORT=10100
LOG_DIR="$HOME/.opencodex/logs"
LOG_FILE="$LOG_DIR/gateway.log"

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
# else opencodex's own documented default (10100).
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

# port_up <port> -> 0 if something is listening and answering on loopback:port
port_up() {
  local port="$1"
  if have curl; then
    curl -fsS -o /dev/null --max-time 1 "http://127.0.0.1:$port/healthz" 2>/dev/null && return 0
    curl -fsS -o /dev/null --max-time 1 "http://127.0.0.1:$port/" 2>/dev/null && return 0
    return 1
  fi
  # curl-less fallback: a bare TCP connect test via bash's /dev/tcp.
  (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null || return 1
  exec 3<&- 3>&-
  return 0
}

cmd_status() {
  require_ocx
  local port
  port="$(resolve_port)"
  if port_up "$port"; then
    echo "opencodex gateway: UP on 127.0.0.1:$port"
  else
    echo "opencodex gateway: DOWN (nothing answering on 127.0.0.1:$port)"
    echo "start it with: .agents/skills/workflow-gateway/gateway.sh start"
  fi
}

cmd_start() {
  require_ocx
  local port
  port="$(resolve_port)"
  if port_up "$port"; then
    echo "opencodex gateway already up on 127.0.0.1:$port — nothing to do"
    return 0
  fi
  mkdir -p "$LOG_DIR"
  echo "starting opencodex gateway (port $port) in the background — logs: $LOG_FILE"
  nohup ocx start --port "$port" >>"$LOG_FILE" 2>&1 &
  disown
  local i
  for i in 1 2 3 4 5; do
    sleep 1
    if port_up "$port"; then
      echo "started — 127.0.0.1:$port (logs: $LOG_FILE)"
      return 0
    fi
  done
  echo "error: opencodex did not come up on 127.0.0.1:$port within 5s — check $LOG_FILE" >&2
  exit 1
}

cmd_stop() {
  require_ocx
  ocx stop
}

# Prints the exact, verified opt-in override — never exports it into this shell or any
# rc file. Copy/paste (or eval) it yourself, in the ONE shell/command you mean it for.
cmd_env() {
  require_ocx
  local port
  port="$(resolve_port)"
  echo "# opt-in ONLY — export in a single shell, or prefix a single command. Never put"
  echo "# this in a shell rc file or any global config."
  echo "export ANTHROPIC_BASE_URL=http://127.0.0.1:$port"
}

# Print the model identifiers to pass to Claude Code's --model when using
# claude-gw.sh/ocx claude. Prefer Claude Code's gateway discovery cache because it
# contains the exact routed IDs Claude accepts (including context-window variants such
# as [1m]); fall back to the live gateway /v1/models endpoint if the cache is absent.
cmd_models() {
  require_ocx
  local cache="$HOME/.claude/cache/gateway-models.json"
  if [ -f "$cache" ] && have yq; then
    echo "Claude Code gateway models from $cache:"
    yq -r '.models[] | "  " + .id + "\t" + .display_name' "$cache"
    return 0
  fi

  have curl || {
    echo "error: curl is required to query the live gateway when $cache is unavailable" >&2
    exit 1
  }
  have yq || {
    echo "error: yq is required to parse gateway model output" >&2
    exit 1
  }

  ocx ensure >&2 || true
  local port
  port="$(resolve_port)"
  echo "Claude Code model IDs inferred from live gateway http://127.0.0.1:$port/v1/models:"
  curl -fsS --max-time 3 "http://127.0.0.1:$port/v1/models" \
    | yq -r '.data[] | "  claude-ocx-native--" + .id + "\t" + .owned_by'
}

case "${1:-}" in
  status) cmd_status ;;
  start)  cmd_start ;;
  stop)   cmd_stop ;;
  env)    cmd_env ;;
  models) cmd_models ;;
  *) echo "usage: gateway.sh status|start|stop|env|models" >&2; exit 1 ;;
esac
