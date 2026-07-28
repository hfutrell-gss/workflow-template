#!/usr/bin/env bash
# workflow-template-sync — the upstream link between workflow-template and a derivation.
#
# Usage:
#   template-sync.sh derive [--upstream PATH]   # run inside a fresh copy/clone of the
#                                                # template: turn it into a derivation
#   template-sync.sh update                     # run inside a derivation: pull forward
#                                                # any managed-set changes from upstream
#   template-sync.sh --check                    # report current vs upstream version;
#                                                # exit 1 if behind
#
# `derive` asks nothing interactively. The upstream location defaults to
# $WORKFLOW_TEMPLATE_UPSTREAM if set, else $HOME/workbench/workflow-template, else
# --upstream PATH. Only a local path upstream is supported for now — no remote exists.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LOCK="$ROOT/.template.lock"

command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflow-init first" >&2; exit 1; }

default_upstream() { printf '%s\n' "${WORKFLOW_TEMPLATE_UPSTREAM:-$HOME/workbench/workflow-template}"; }

lock_get() { # lock_get <key> [file]
  local key="$1" file="${2:-$LOCK}"
  [ -f "$file" ] && yq -r ".$key" "$file" 2>/dev/null | grep -v '^null$' || true
}

# Copies every path in a template-manifest.yaml's `managed:` list from $1 (source repo
# root) to $2 (destination repo root). Directory entries end in "/**": the destination
# directory is replaced wholesale (so upstream deletions propagate too), never merged.
copy_managed_paths() {
  local src="$1" dst="$2" manifest_src="$3"
  local path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [[ "$path" == */** ]]; then
      local dirpath="${path%/**}"
      mkdir -p "$(dirname "$dst/$dirpath")"
      rm -rf "$dst/$dirpath"
      cp -r "$src/$dirpath" "$dst/$dirpath"
    else
      mkdir -p "$(dirname "$dst/$path")"
      cp "$src/$path" "$dst/$path"
    fi
    echo "  synced $path"
  done < <(yq -r '.managed[]' "$manifest_src")
}

cmd_derive() {
  local upstream=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --upstream) upstream="$2"; shift 2 ;;
      *) echo "error: unknown derive argument '$1'" >&2; exit 1 ;;
    esac
  done
  [ -n "$upstream" ] || upstream="$(default_upstream)"

  [ -f "$LOCK" ] && { echo "error: $LOCK already exists — this is already a derivation (delete it first to re-derive)" >&2; exit 1; }
  [ -f "$ROOT/VERSION" ] || { echo "error: no VERSION file at $ROOT — this doesn't look like a template checkout" >&2; exit 1; }

  local template_version
  template_version="$(tr -d '[:space:]' < "$ROOT/VERSION")"

  # Strip template-only identity: this workflow's own journal/playbooks start empty —
  # any content here at derive time is the template's own example/test material, not
  # this derivation's.
  find "$ROOT/journal" -type f ! -name '.gitkeep' -delete 2>/dev/null || true
  find "$ROOT/playbooks" -type f -name '*example*' -delete 2>/dev/null || true

  # VERSION describes the TEMPLATE's own version, not a derivation's — the
  # derivation's relationship to it is tracked entirely in .template.lock instead.
  rm -f "$ROOT/VERSION"

  {
    echo "template_version: $template_version"
    echo "upstream: $upstream"
    echo "derived: $(date -I)"
    echo "pinned: false"
  } > "$LOCK"

  echo "derived: template_version=$template_version upstream=$upstream (see .template.lock)"
  echo "next: write this workflow's doctrine into AGENTS.md (the skeleton is untouched)"
}

cmd_update() {
  [ -f "$LOCK" ] || { echo "error: no $LOCK — this doesn't look like a derivation (run 'derive' first, in a template copy)" >&2; exit 1; }
  local pinned upstream template_version upstream_version derived
  pinned="$(lock_get pinned)"
  upstream="$(lock_get upstream)"
  template_version="$(lock_get template_version)"
  derived="$(lock_get derived)"   # read BEFORE the lock file is rewritten below
  [ -d "$upstream" ] || { echo "error: upstream '$upstream' (from .template.lock) not found — only a local path upstream is supported" >&2; exit 1; }
  [ -f "$upstream/VERSION" ] || { echo "error: no VERSION file at upstream '$upstream'" >&2; exit 1; }
  upstream_version="$(tr -d '[:space:]' < "$upstream/VERSION")"

  if [ "$pinned" = "true" ]; then
    echo "pinned: true — not updating. template_version=$template_version, upstream available=$upstream_version"
    [ "$upstream_version" != "$template_version" ] && echo "(set pinned: false in .template.lock to allow update)"
    exit 0
  fi

  if [ "$upstream_version" = "$template_version" ]; then
    echo "up to date (template_version=$template_version)"
    exit 0
  fi

  if [ "$(printf '%s\n%s\n' "$template_version" "$upstream_version" | sort -n | tail -1)" != "$upstream_version" ]; then
    echo "warning: derivation's template_version ($template_version) is ahead of upstream ($upstream_version) — nothing to do"
    exit 0
  fi

  echo "updating managed set: template_version $template_version -> $upstream_version"
  copy_managed_paths "$upstream" "$ROOT" "$upstream/template-manifest.yaml"

  # Rewrite the lock preserving upstream/derived/pinned, only template_version changes.
  {
    echo "template_version: $upstream_version"
    echo "upstream: $upstream"
    echo "derived: $derived"
    echo "pinned: $pinned"
  } > "$LOCK"
  echo "update complete (template_version=$upstream_version)"
}

cmd_check() {
  [ -f "$LOCK" ] || { echo "error: no $LOCK — this doesn't look like a derivation" >&2; exit 1; }
  local pinned upstream template_version upstream_version
  pinned="$(lock_get pinned)"
  upstream="$(lock_get upstream)"
  template_version="$(lock_get template_version)"
  [ -d "$upstream" ] || { echo "error: upstream '$upstream' (from .template.lock) not found" >&2; exit 1; }
  [ -f "$upstream/VERSION" ] || { echo "error: no VERSION file at upstream '$upstream'" >&2; exit 1; }
  upstream_version="$(tr -d '[:space:]' < "$upstream/VERSION")"

  echo "template_version: $template_version"
  echo "upstream:         $upstream"
  echo "upstream version: $upstream_version"
  echo "pinned:           $pinned"

  if [ "$template_version" = "$upstream_version" ]; then
    echo "status: up to date"
    exit 0
  else
    echo "status: behind (run 'update' to pull the managed set forward$( [ "$pinned" = "true" ] && echo " — currently pinned, so update will only report" ))"
    exit 1
  fi
}

MODE="${1:---check}"; [ "$#" -gt 0 ] && shift || true
case "$MODE" in
  derive)   cmd_derive "$@" ;;
  update)   cmd_update "$@" ;;
  --check)  cmd_check "$@" ;;
  *) echo "usage: template-sync.sh derive [--upstream PATH] | update | --check" >&2; exit 1 ;;
esac
