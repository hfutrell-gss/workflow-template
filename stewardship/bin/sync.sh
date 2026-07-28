#!/usr/bin/env bash
# Assemble the GSS multi-repo workspace from manifest.yaml.
#
# Usage:
#   ./sync.sh [workspace]     # default workspace: globalshopsolutions
#   ./sync.sh --all           # every repo in the manifest
#   ./sync.sh --list          # list workspaces and exit
#
# For each repo: clone it into `base` if missing, otherwise fetch and fast-forward
# its tracked branch. Never clobbers local work — a dirty tree or non-ff pull is
# reported and skipped, not forced (surface, don't suppress).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
MANIFEST="${GSS_MANIFEST:-$HERE/../../manifest.yaml}"   # monorepo root; override for testing
command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflows-init (.claude/skills/workflows-init/init.sh) first" >&2; exit 1; }

base_raw="$(yq -r '.base' "$MANIFEST")"
BASE="${base_raw/#\~/$HOME}"

ws="${1:-globalshopsolutions}"
case "$ws" in
  --list) yq -r '.workspaces | keys | .[]' "$MANIFEST"; exit 0 ;;
  --all)  names="$(yq -r '.repos[].name' "$MANIFEST")" ;;
  *)      yq -e ".workspaces.\"$ws\"" "$MANIFEST" >/dev/null 2>&1 \
            || { echo "error: unknown workspace '$ws' (try --list)" >&2; exit 1; }
          names="$(yq -r ".workspaces.\"$ws\"[]" "$MANIFEST")" ;;
esac

mkdir -p "$BASE"
echo "workspace: $ws   base: $BASE"
echo

ok=0; skipped=0; failed=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  url="$(yq -r ".repos[] | select(.name == \"$name\") | .url" "$MANIFEST")"
  branch="$(yq -r ".repos[] | select(.name == \"$name\") | .branch" "$MANIFEST")"
  dir="$BASE/$name"

  if [ -z "$url" ] || [ "$url" = "null" ]; then
    printf '  %-24s ! not in manifest.repos\n' "$name"; failed=$((failed+1)); continue
  fi

  if [ ! -e "$dir/.git" ]; then
    printf '  %-24s cloning (%s)\n' "$name" "$branch"
    if git clone --branch "$branch" "$url" "$dir" >/dev/null 2>&1; then
      ok=$((ok+1))
    else
      printf '  %-24s ! clone failed (%s)\n' "$name" "$url"; failed=$((failed+1))
    fi
    continue
  fi

  # existing repo: fetch, then fast-forward the tracked branch only if it's safe
  if [ -n "$(git -C "$dir" status --porcelain)" ]; then
    printf '  %-24s ~ dirty working tree — fetch only, not pulling\n' "$name"
    git -C "$dir" fetch --quiet origin || true
    skipped=$((skipped+1)); continue
  fi
  cur="$(git -C "$dir" branch --show-current)"
  git -C "$dir" fetch --quiet origin || { printf '  %-24s ! fetch failed\n' "$name"; failed=$((failed+1)); continue; }
  if [ "$cur" != "$branch" ]; then
    printf '  %-24s ~ on %s (manifest tracks %s) — fetch only\n' "$name" "$cur" "$branch"
    skipped=$((skipped+1)); continue
  fi
  if git -C "$dir" merge --ff-only "origin/$branch" >/dev/null 2>&1; then
    printf '  %-24s up to date (%s)\n' "$name" "$branch"; ok=$((ok+1))
  else
    printf '  %-24s ~ %s has diverged from origin — resolve manually\n' "$name" "$branch"
    skipped=$((skipped+1))
  fi
done <<< "$names"

echo
echo "done: $ok ok, $skipped skipped, $failed failed"
[ "$failed" -eq 0 ]
