#!/usr/bin/env bash
# workflows-init — install/verify the tooling this monorepo's procedures assume,
# then record the init version in <repo-root>/init.lock (per-machine, gitignored).
#
# Usage: init.sh          # ensure everything, write init.lock
#        init.sh --check  # verify only: exit 0 if lock matches VERSION and tools present
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$HERE/VERSION")"
LOCK="$ROOT/init.lock"

# ---- tool checks ------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

check_yq()       { have yq && yq --version 2>/dev/null | grep -o 'v[0-9][0-9.]*' | head -1; }
check_obsidian() { have obsidian && echo present; }
check_codegraph(){ have codegraph && (codegraph --version 2>/dev/null || echo present) | head -1; }

install_yq() {
  echo "installing yq (mikefarah v4) to ~/.local/bin ..." >&2
  mkdir -p "$HOME/.local/bin"
  curl -fsSL -o "$HOME/.local/bin/yq" \
    "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64" \
    && chmod +x "$HOME/.local/bin/yq"
}

install_obsidian() {
  # Mirrors the established WSLg install: AppImage extracted to ~/.local/opt/obsidian
  # with a --disable-gpu wrapper at ~/.local/bin/obsidian (Electron SIGTRAP workaround).
  echo "installing Obsidian (AppImage, WSLg wrapper) ..." >&2
  local url dir="$HOME/.local/opt/obsidian"
  url="$(curl -fsSL https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest \
        | grep -o 'https://[^"]*Obsidian-[0-9.]*\.AppImage' | head -1)"
  [ -n "$url" ] || { echo "error: could not resolve Obsidian AppImage url" >&2; return 1; }
  mkdir -p "$dir" "$HOME/.local/bin"
  curl -fsSL -o "$dir/Obsidian.AppImage" "$url" && chmod +x "$dir/Obsidian.AppImage"
  (cd "$dir" && ./Obsidian.AppImage --appimage-extract >/dev/null)
  cat > "$HOME/.local/bin/obsidian" <<'WRAP'
#!/bin/sh
# Obsidian AppImage under WSLg. --disable-gpu* avoids Electron SIGTRAP crashes
# that leave multi-GB dumps in %LOCALAPPDATA%\Temp\wsl-crashes.
APPDIR="$HOME/.local/opt/obsidian/squashfs-root"
export APPDIR
export DISPLAY="${DISPLAY:-:0}"
exec "$APPDIR/AppRun" \
  --no-sandbox \
  --disable-gpu \
  --disable-gpu-sandbox \
  --disable-dev-shm-usage \
  "$@"
WRAP
  chmod +x "$HOME/.local/bin/obsidian"
}

install_codegraph() {
  # Default is the official install method per the repo's own README
  # (https://github.com/colbymchenry/codegraph, install.sh "curl/shell script
  # (macOS/Linux)" section): a user-scoped installer with no sudo, no shell-profile
  # mutation, that downloads only from GitHub Releases (SHA256SUMS published) and
  # symlinks the binary at ~/.local/bin/codegraph. Vetted 2026-07-27 (MIT license,
  # active releases). Note the bare `codegraph` npm package and the
  # `@colbymchenry/codegraph-<platform>` bundles are NOT this — the scoped
  # `@colbymchenry/codegraph` meta-package (README's npm alternative) is the only
  # other officially sanctioned channel. Override via CODEGRAPH_INSTALL if needed.
  local cmd="${CODEGRAPH_INSTALL:-curl -fsSL https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.sh | sh}"
  echo "installing codegraph via: $cmd" >&2
  eval "$cmd"
}

# ---- run --------------------------------------------------------------------
declare -A got
missing=()
for tool in yq obsidian codegraph; do
  v="$("check_$tool" || true)"
  if [ -n "$v" ]; then got[$tool]="$v"; else missing+=("$tool"); fi
done

if [ "${1:-}" = "--check" ]; then
  lockv="$( [ -f "$LOCK" ] && grep -m1 '^version:' "$LOCK" | awk '{print $2}' || echo none)"
  [ "$lockv" = "$VERSION" ] && [ "${#missing[@]}" -eq 0 ] \
    && { echo "init ok (version $VERSION; tools: ${!got[*]})"; exit 0; }
  [ "$lockv" != "$VERSION" ] && echo "init.lock version '$lockv' != required '$VERSION'"
  [ "${#missing[@]}" -gt 0 ] && echo "missing tools: ${missing[*]}"
  exit 1
fi

for tool in "${missing[@]+"${missing[@]}"}"; do
  "install_$tool"
  v="$("check_$tool" || true)"
  [ -n "$v" ] && got[$tool]="$v" || { echo "error: $tool still unavailable after install" >&2; exit 1; }
done

{
  echo "version: $VERSION"
  echo "date: $(date -I)"
  echo "tools:"
  for tool in yq obsidian codegraph; do echo "  $tool: ${got[$tool]}"; done
} > "$LOCK"
echo "init complete — wrote $LOCK (version $VERSION)"
