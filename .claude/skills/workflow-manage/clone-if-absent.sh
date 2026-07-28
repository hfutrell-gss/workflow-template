#!/usr/bin/env bash
# workflow-manage helper — clone a standing bind's repo into `base` if it isn't there
# yet. Reads url/branch straight from binds.yaml; never touches an existing checkout.
#
# Usage: clone-if-absent.sh <repo-name>
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
BINDS="$ROOT/binds.yaml"
command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflow-init first" >&2; exit 1; }

name="${1:?usage: clone-if-absent.sh <repo-name>}"
base_raw="$(yq -r '.base // "~/workbench"' "$BINDS")"; BASE="${base_raw/#\~/$HOME}"
dir="$BASE/$name"

if [ -e "$dir/.git" ]; then
  echo "$name already present at $dir — not touching it"
  exit 0
fi

url="$(yq -r ".standing[] | select(.repo == \"$name\") | .url // \"\"" "$BINDS")"
branch="$(yq -r ".standing[] | select(.repo == \"$name\") | .branch // \"\"" "$BINDS")"
[ -n "$url" ] || { echo "error: '$name' has no url in binds.yaml — add one or clone it manually into $BASE" >&2; exit 1; }

mkdir -p "$BASE"
if [ -n "$branch" ]; then
  echo "cloning $name ($branch) from $url into $BASE"
  /usr/bin/git clone --branch "$branch" "$url" "$dir"
else
  echo "cloning $name (default branch) from $url into $BASE"
  /usr/bin/git clone "$url" "$dir"
fi
