#!/usr/bin/env bash
# workflows-agents-sync — enforce the canonical-format invariant:
#   AGENTS.md (and .agents/) are canonical; CLAUDE.md is at most a header bridge
#   containing "@AGENTS.md". Applies to this monorepo and to every substrate repo
#   from manifest.yaml that is present on disk.
#
# Usage: agents-sync.sh [--check|--fix]
#   --check (default)  report drift, exit 1 if any
#   --fix              create missing bridges; non-conforming CLAUDE.md files are
#                      still only REPORTED (moving their content into AGENTS.md is a
#                      judgment call — do it, then re-run)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
MANIFEST="$ROOT/manifest.yaml"
MODE="${1:---check}"
MAX_BRIDGE_LINES=8

# Standard bridge (root + substrate repos). Workflow dirs inside this monorepo get the
# two-import variant: an ancestor-relative CLAUDE.md import (@../AGENTS.md) does NOT
# expand at session load (verified: headless sessions never pull in an import that
# resolves above cwd, even when the dir is --add-dir'd and pre-trusted). The fix is a
# same-directory symlink `.constitution.md` -> `../AGENTS.md`: importing @.constitution.md
# (a cwd-relative path) expands correctly, and it happens to resolve to the root doctrine.
BRIDGE='# CLAUDE.md
<!-- managed by /workflows-agents-sync — no content here; AGENTS.md is canonical -->

@AGENTS.md
'
BRIDGE_WORKFLOW='# CLAUDE.md
<!-- managed by /workflows-agents-sync — no content here; AGENTS.md is canonical -->

@.constitution.md
@AGENTS.md
'
CONSTITUTION_TARGET="../AGENTS.md"

drift=0
note() { echo "$@"; drift=1; }

# Workflow dirs need the same-directory symlink so @.constitution.md resolves to the
# root constitution. constitution=1 enables this check/fix; scope-2 (substrate repos)
# and the root itself never need it.
check_dir() {
  local dir="$1" label="$2" bridge="${3:-$BRIDGE}" constitution="${4:-0}"
  local agents="$dir/AGENTS.md" claude="$dir/CLAUDE.md" link="$dir/.constitution.md"
  [ -f "$agents" ] || return 0        # no law here; nothing to bridge

  if [ "$constitution" = "1" ]; then
    if [ -L "$link" ] && [ "$(readlink "$link")" = "$CONSTITUTION_TARGET" ]; then
      : # conforming
    elif [ "$MODE" = "--fix" ]; then
      ln -sf "$CONSTITUTION_TARGET" "$link"
      echo "FIXED   $label: created .constitution.md -> $CONSTITUTION_TARGET symlink"
    elif [ -e "$link" ] || [ -L "$link" ]; then
      note "DRIFT   $label: .constitution.md exists but is not a symlink to $CONSTITUTION_TARGET"
    else
      note "MISSING $label: .constitution.md symlink to $CONSTITUTION_TARGET missing (--fix creates it)"
    fi
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
  # conformance: must import AGENTS.md (and, for workflow dirs, .constitution.md too)
  # and be a header at most
  if ! grep -q '@AGENTS.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @AGENTS.md — move its content into AGENTS.md, replace with the bridge"
  elif [ "$constitution" = "1" ] && ! grep -q '@.constitution.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @.constitution.md — the root constitution won't load in headless sessions"
  elif [ "$(wc -l < "$claude")" -gt "$MAX_BRIDGE_LINES" ]; then
    note "DRIFT   $label: CLAUDE.md exceeds $MAX_BRIDGE_LINES lines — content belongs in AGENTS.md"
  fi
}

# ---- scope 1: this monorepo (root + every workflow dir) ---------------------
check_dir "$ROOT" "workflows"
while IFS= read -r d; do
  check_dir "$d" "workflows/$(basename "$d")" "$BRIDGE_WORKFLOW" 1
done < <(find "$ROOT" -mindepth 1 -maxdepth 1 -type d ! -name '.*' ! -name 'bin')

# ---- scope 2: substrate repos from the manifest -----------------------------
if [ -f "$MANIFEST" ] && command -v yq >/dev/null; then
  base_raw="$(yq -r '.base' "$MANIFEST")"; BASE="${base_raw/#\~/$HOME}"
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    repo="$BASE/$name"
    [ -e "$repo/.git" ] || continue   # not on disk; stewardship's sync handles presence
    check_dir "$repo" "$name"
  done < <(yq -r '.repos[].name' "$MANIFEST")
else
  note "WARN    cannot scan substrate: manifest or yq unavailable"
fi

if [ "$drift" -eq 0 ]; then
  echo "agents-sync: all conforming"
else
  exit 1
fi
