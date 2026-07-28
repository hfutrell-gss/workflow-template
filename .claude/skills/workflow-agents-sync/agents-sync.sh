#!/usr/bin/env bash
# workflow-agents-sync — enforce the canonical-format invariant:
#   AGENTS.md (and .agents/) are canonical; CLAUDE.md is at most a header bridge
#   importing @AGENTS.md (root also imports @AGENTS.CORE.md, ahead of @AGENTS.md).
# Applies to this workflow's own root and to every standing-bind repo from
# binds.yaml that is present on disk under `base`.
#
# Usage: agents-sync.sh [--check|--fix]
#   --check (default)  report drift, exit 1 if any
#   --fix              create missing bridges; non-conforming CLAUDE.md files are
#                      still only REPORTED (moving their content into AGENTS.md is a
#                      judgment call — do it, then re-run)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
BINDS="$ROOT/binds.yaml"
MODE="${1:---check}"
MAX_BRIDGE_LINES=8

# Root bridge: imports the managed core ahead of this repo's own doctrine.
ROOT_BRIDGE='# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.CORE.md + AGENTS.md are canonical -->

@AGENTS.CORE.md
@AGENTS.md
'
# Standing-bind repo bridge: the plain single-import form (these repos have no
# AGENTS.CORE.md of their own — that file only exists at this workflow's root).
BRIDGE='# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.md is canonical -->

@AGENTS.md
'

drift=0
note() { echo "$@"; drift=1; }

# root=1 additionally requires AGENTS.CORE.md to exist and @AGENTS.CORE.md to be
# imported ahead of @AGENTS.md in CLAUDE.md.
check_dir() {
  local dir="$1" label="$2" root="${3:-0}"
  local bridge="$BRIDGE"
  [ "$root" = "1" ] && bridge="$ROOT_BRIDGE"
  local agents="$dir/AGENTS.md" claude="$dir/CLAUDE.md"
  [ -f "$agents" ] || return 0        # no law here; nothing to bridge

  if [ "$root" = "1" ] && [ ! -f "$dir/AGENTS.CORE.md" ]; then
    note "MISSING $label: AGENTS.CORE.md not found at repo root (expected here — template link broken?)"
  fi

  if [ ! -f "$claude" ]; then
    if [ "$MODE" = "--fix" ]; then
      printf '%s' "$bridge" > "$claude"
      echo "FIXED   $label: created CLAUDE.md bridge"
    else
      note "MISSING $label: AGENTS.md has no CLAUDE.md bridge (--fix creates it)"
    fi
    return 0
  fi
  # conformance: must import AGENTS.md (and, at root, @AGENTS.CORE.md too) and be a
  # header at most
  if ! grep -q '@AGENTS.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @AGENTS.md — move its content into AGENTS.md, replace with the bridge"
  elif [ "$root" = "1" ] && ! grep -q '@AGENTS.CORE.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @AGENTS.CORE.md — the managed core won't load this session"
  elif [ "$(wc -l < "$claude")" -gt "$MAX_BRIDGE_LINES" ]; then
    note "DRIFT   $label: CLAUDE.md exceeds $MAX_BRIDGE_LINES lines — content belongs in AGENTS.md"
  fi
}

# ---- scope 1: this workflow's own root ---------------------------------------
check_dir "$ROOT" "root" 1

# ---- scope 2: standing-bind repos from binds.yaml ----------------------------
if [ -f "$BINDS" ] && command -v yq >/dev/null; then
  base_raw="$(yq -r '.base // "~/workbench"' "$BINDS")"; BASE="${base_raw/#\~/$HOME}"
  count="$(yq -r '(.standing // []) | length' "$BINDS" 2>/dev/null || echo 0)"
  if [ "${count:-0}" -gt 0 ] 2>/dev/null; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      repo="$BASE/$name"
      [ -e "$repo/.git" ] || continue   # not on disk; workflow-manage's sync-binds.sh handles presence
      check_dir "$repo" "$name"
    done < <(yq -r '.standing[].repo' "$BINDS")
  fi
else
  note "WARN    cannot scan standing binds: binds.yaml or yq unavailable"
fi

if [ "$drift" -eq 0 ]; then
  echo "agents-sync: all conforming"
else
  exit 1
fi
