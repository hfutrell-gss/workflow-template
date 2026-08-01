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
# `derive` asks nothing interactively. The upstream location is resolved by
# precedence: --upstream PATH > $WORKFLOW_TEMPLATE_UPSTREAM env var > this checkout's
# own 'origin' remote URL (git -C <dir> remote get-url origin), if one exists > else
# hardcoded fallback $HOME/workbench/workflow-template. The origin-remote step means
# deriving inside a `git clone` of the published template correctly links back to that
# remote instead of silently falling through to the local hardcoded path; a plain `cp
# -r` copy has no .git/origin and falls through as before. `upstream` (in
# .template.lock, or --upstream here) may be a local path or a git URL (https://,
# git@..., ssh://, file://) — a URL upstream is fetched into a cached shallow clone
# under ${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync/.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LOCK="$ROOT/.template.lock"
GIT=/usr/bin/git

command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflow-init first" >&2; exit 1; }

default_upstream() { # default_upstream <root-dir> -> resolves upstream when --upstream
  # wasn't given, by precedence: WORKFLOW_TEMPLATE_UPSTREAM env > this checkout's own
  # 'origin' remote (if any — tolerates a plain `cp` copy with no .git) > hardcoded
  # fallback.
  local root="$1" origin
  if [ -n "${WORKFLOW_TEMPLATE_UPSTREAM:-}" ]; then
    printf '%s\n' "$WORKFLOW_TEMPLATE_UPSTREAM"
    return
  fi
  origin="$("$GIT" -C "$root" remote get-url origin 2>/dev/null || true)"
  if [ -n "$origin" ]; then
    echo "derive: no --upstream given and WORKFLOW_TEMPLATE_UPSTREAM unset — inferring upstream from this checkout's 'origin' remote: $origin" >&2
    printf '%s\n' "$origin"
    return
  fi
  printf '%s\n' "$HOME/workbench/workflow-template"
}

lock_get() { # lock_get <key> [file]
  local key="$1" file="${2:-$LOCK}"
  [ -f "$file" ] && yq -r ".$key" "$file" 2>/dev/null | grep -v '^null$' || true
}

# --- remote upstream support -------------------------------------------------
# An `upstream` value is either a local path (existing behavior) or a git URL. These
# helpers resolve either kind to a local directory that VERSION/template-manifest.yaml/
# the managed set can be read from exactly the same way — callers never branch on kind
# beyond this point.

is_url_upstream() { # is_url_upstream <upstream>
  case "$1" in
    https://*|http://*|git@*|ssh://*|file://*) return 0 ;;
    *) return 1 ;;
  esac
}

cache_dir_for() { # cache_dir_for <url> -> prints the cache checkout path for that url
  local url="$1" base sha
  base="${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync"
  if command -v sha1sum >/dev/null; then
    sha="$(printf '%s' "$url" | sha1sum | cut -d' ' -f1)"
  else
    sha="$(printf '%s' "$url" | shasum -a 1 | cut -d' ' -f1)"
  fi
  printf '%s/%s\n' "$base" "$sha"
}

resolve_default_branch() { # resolve_default_branch <cache-dir> -> prints branch name (no "origin/")
  local cache="$1" ref
  ref="$("$GIT" -C "$cache" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  if [ -z "$ref" ]; then
    "$GIT" -C "$cache" remote set-head origin -a >/dev/null 2>&1 || true
    ref="$("$GIT" -C "$cache" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  fi
  printf '%s\n' "${ref#origin/}"
}

# Refreshes (cloning if absent, else fetch+hard-reset) the cache checkout for a remote
# upstream. Never half-updates: on failure with no cache present it's a hard error; on
# failure with a cache present it's a loud warning and the stale cache is kept as-is.
refresh_remote_cache() { # refresh_remote_cache <url> <cache-dir>
  local url="$1" cache="$2"
  mkdir -p "$(dirname "$cache")"

  if [ ! -d "$cache" ]; then
    echo "workflow-template-sync: cloning remote upstream '$url' into cache ($cache)..."
    if ! "$GIT" clone --depth 1 "$url" "$cache"; then
      rm -rf "$cache"
      echo "error: failed to clone remote upstream '$url' and no cache exists — cannot proceed offline" >&2
      exit 1
    fi
    "$GIT" -C "$cache" remote set-head origin -a >/dev/null 2>&1 || true
    return 0
  fi

  if ! "$GIT" -C "$cache" fetch --depth 1 origin; then
    local last_refresh
    last_refresh="$(date -r "$cache/.git/FETCH_HEAD" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo unknown)"
    echo "WARNING: fetch failed for remote upstream '$url' — proceeding with STALE cache at $cache (last refreshed: $last_refresh)" >&2
    return 0
  fi

  local default_branch
  default_branch="$(resolve_default_branch "$cache")"
  [ -n "$default_branch" ] || { echo "error: could not resolve default branch for remote upstream '$url'" >&2; exit 1; }
  "$GIT" -C "$cache" reset --hard "origin/$default_branch"
}

resolve_upstream_root() { # resolve_upstream_root <upstream-string> -> prints local root to read from
  local upstream="$1"
  if is_url_upstream "$upstream"; then
    local cache
    cache="$(cache_dir_for "$upstream")"
    refresh_remote_cache "$upstream" "$cache" 1>&2
    printf '%s\n' "$cache"
  else
    [ -d "$upstream" ] || { echo "error: upstream '$upstream' (from .template.lock) not found" >&2; exit 1; }
    printf '%s\n' "$upstream"
  fi
}

# Copies every path in a template-manifest.yaml's `managed:` list from $1 (source repo
# root) to $2 (destination repo root). Directory entries end in "/**": the destination
# directory is replaced wholesale (so upstream deletions propagate too), never merged.
copy_managed_paths() {
  local src="$1" dst="$2" manifest_src="$3"
  local path
  while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [[ "$path" == *'/**' ]]; then
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
  [ -n "$upstream" ] || upstream="$(default_upstream "$ROOT")"

  [ -f "$LOCK" ] && { echo "error: $LOCK already exists — this is already a derivation (delete it first to re-derive)" >&2; exit 1; }
  [ -f "$ROOT/VERSION" ] || { echo "error: no VERSION file at $ROOT — this doesn't look like a template checkout" >&2; exit 1; }

  local template_version
  template_version="$(tr -d '[:space:]' < "$ROOT/VERSION")"

  # Strip template-only identity: this workflow's own journal starts empty — any content
  # here at derive time is the template's own example/test material, not this derivation's.
  find "$ROOT/journal" -type f ! -name '.gitkeep' -delete 2>/dev/null || true

  # Orchestration run state is identity too, and it is COMMITTED (unlike workspace/), so
  # a derive-by-clone carries the template's own in-flight runs into the new workflow —
  # task lists and notes for work that has nothing to do with it. Clear it for the same
  # reason as journal/: a run belongs to the repo that performed it. Two strata to clear
  # differently: workflows/<workflow>/<target>/ is INSTANCE state (clear it); a bare
  # workflows/<workflow>/ with no target subdirs is the DURABLE procedure and must
  # survive derive, same as .agents/skills/ does. .workflow/<slug>/ is the legacy
  # (pre-stratification) layout, kept only as a one-version fallback — clear it too.
  for d in "$ROOT"/workflows/*/*/; do
    [ -f "$d/tasks.md" ] && rm -rf "$d"
  done
  rm -rf "$ROOT/.workflow"/*/ 2>/dev/null || true

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
  local pinned upstream upstream_root template_version upstream_version derived
  pinned="$(lock_get pinned)"
  upstream="$(lock_get upstream)"
  template_version="$(lock_get template_version)"
  derived="$(lock_get derived)"   # read BEFORE the lock file is rewritten below
  upstream_root="$(resolve_upstream_root "$upstream")"
  [ -f "$upstream_root/VERSION" ] || { echo "error: no VERSION file at upstream root '$upstream_root' (upstream: $upstream)" >&2; exit 1; }
  upstream_version="$(tr -d '[:space:]' < "$upstream_root/VERSION")"

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
  copy_managed_paths "$upstream_root" "$ROOT" "$upstream_root/template-manifest.yaml"

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
  local pinned upstream upstream_root template_version upstream_version
  pinned="$(lock_get pinned)"
  upstream="$(lock_get upstream)"
  template_version="$(lock_get template_version)"
  upstream_root="$(resolve_upstream_root "$upstream")"
  [ -f "$upstream_root/VERSION" ] || { echo "error: no VERSION file at upstream root '$upstream_root' (upstream: $upstream)" >&2; exit 1; }
  upstream_version="$(tr -d '[:space:]' < "$upstream_root/VERSION")"

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
