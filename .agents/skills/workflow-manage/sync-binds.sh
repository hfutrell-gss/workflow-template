#!/usr/bin/env bash
# workflow-manage — sync-binds: assemble/refresh every standing bind that declares a
# `url` onto disk under `base`. THIS is the managed capability for substrate assembly —
# see AGENTS.CORE.md's categorical rule: the template defines binds.yaml's shape, so the
# template owns every operation on it. A derivation never hand-rolls this tooling.
#
# Usage:
#   sync-binds.sh                 # sync every standing bind that declares a url
#   sync-binds.sh <repo> [...]    # sync only the named standing bind(s)
#
# For each targeted standing bind: clone it into `base` if missing (using its `branch`
# if one is set, otherwise the remote's default branch); otherwise fetch and
# fast-forward ONLY when the checkout is clean and sitting on the tracked branch. A
# dirty tree, an off-branch checkout, or a diverged history is still fetched (so the
# report reflects current state) but reported as skipped, never forced — never
# clobbers local work.
#
# Summary line: "N ok, M skipped, K failed" — nonzero exit iff failed > 0.
# Env override: BINDS_FILE=/path/to/binds.yaml (for testing).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
BINDS="${BINDS_FILE:-$ROOT/binds.yaml}"
command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflow-init first" >&2; exit 1; }
[ -f "$BINDS" ] || { echo "error: binds file not found: $BINDS" >&2; exit 1; }

# Path resolution rule (shared with workflow-agents-sync's scope-2 scan): `base`
# starting with `/` or `~` is absolute/home-relative (legacy, still supported);
# anything else is resolved RELATIVE TO THIS WORKFLOW REPO'S ROOT (the dir containing
# binds.yaml) — the norm, since a workflow manages its own substrate workspace rather
# than reaching into the user's personal checkouts. Default: `./workspace`.
base_raw="$(yq -r '.base // "./workspace"' "$BINDS")"
case "$base_raw" in
  /*) BASE="$base_raw" ;;
  \~*) BASE="${base_raw/#\~/$HOME}" ;;
  *) BASE="$ROOT/${base_raw#./}" ;;
esac

all_names="$(yq -r '.standing[]? | select(.url != null) | .repo' "$BINDS")"

names=""
bad=0

if [ "$#" -eq 0 ]; then
  if [ -z "$all_names" ]; then
    echo "no standing binds with a url in $BINDS — nothing to sync"
    exit 0
  fi
  names="$all_names"
else
  for want in "$@"; do
    if printf '%s\n' "$all_names" | grep -qxF -- "$want"; then
      names="$names$want"$'\n'
    else
      exists="$(yq -r ".standing[]? | select(.repo == \"$want\") | .repo" "$BINDS")"
      if [ -n "$exists" ]; then
        printf '  %-24s ! no url in binds.yaml — not sync-able\n' "$want"
      else
        printf '  %-24s ! not a standing bind in binds.yaml\n' "$want"
      fi
      bad=$((bad+1))
    fi
  done
fi

mkdir -p "$BASE"
echo "standing binds (with url)   base: $BASE"
echo

ok=0; skipped=0; failed=$bad
while IFS= read -r name; do
  [ -n "$name" ] || continue
  url="$(yq -r ".standing[] | select(.repo == \"$name\") | .url" "$BINDS")"
  branch="$(yq -r ".standing[] | select(.repo == \"$name\") | .branch // \"\"" "$BINDS")"
  [ "$branch" = "null" ] && branch=""
  dir="$BASE/$name"

  if [ ! -e "$dir/.git" ]; then
    if [ -n "$branch" ]; then
      printf '  %-24s cloning (%s)\n' "$name" "$branch"
      if /usr/bin/git clone --branch "$branch" "$url" "$dir" >/dev/null 2>&1; then
        ok=$((ok+1))
      else
        printf '  %-24s ! clone failed (%s)\n' "$name" "$url"; failed=$((failed+1))
      fi
    else
      printf '  %-24s cloning (default branch)\n' "$name"
      if /usr/bin/git clone "$url" "$dir" >/dev/null 2>&1; then
        ok=$((ok+1))
      else
        printf '  %-24s ! clone failed (%s)\n' "$name" "$url"; failed=$((failed+1))
      fi
    fi
    continue
  fi

  # existing repo: fetch, then fast-forward the tracked branch only if it's safe
  if [ -n "$(/usr/bin/git -C "$dir" status --porcelain)" ]; then
    printf '  %-24s ~ dirty working tree — fetch only, not pulling\n' "$name"
    /usr/bin/git -C "$dir" fetch --quiet origin || true
    skipped=$((skipped+1)); continue
  fi

  cur="$(/usr/bin/git -C "$dir" branch --show-current)"
  if ! /usr/bin/git -C "$dir" fetch --quiet origin; then
    printf '  %-24s ! fetch failed\n' "$name"; failed=$((failed+1)); continue
  fi

  track="${branch:-$cur}"
  if [ -n "$branch" ] && [ "$cur" != "$branch" ]; then
    printf '  %-24s ~ on %s (binds.yaml tracks %s) — fetch only\n' "$name" "$cur" "$branch"
    skipped=$((skipped+1)); continue
  fi

  if /usr/bin/git -C "$dir" merge --ff-only "origin/$track" >/dev/null 2>&1; then
    printf '  %-24s up to date (%s)\n' "$name" "$track"; ok=$((ok+1))
  else
    printf '  %-24s ~ %s has diverged from origin — resolve manually\n' "$name" "$track"
    skipped=$((skipped+1))
  fi
done <<< "$names"

echo
echo "$ok ok, $skipped skipped, $failed failed"
[ "$failed" -eq 0 ]
