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

# git is special: on this machine's history, `git` was aliased/PATH-resolved to
# the Windows binary (/mnt/c/.../Git/bin/git.exe) with core.symlinks=false in
# this repo — which silently turns committed symlinks (.constitution.md ->
# AGENTS.md) into plain files with no error. check_git must catch both halves
# of that trap: a non-native git resolving on PATH, and core.symlinks=false
# here. GIT_BIN=/path/to/git is an escape hatch to force a specific binary.
is_windows_git() { case "$1" in /mnt/c/*|*.exe) return 0 ;; *) return 1 ;; esac; }

# Prints a usable native git binary path on stdout, or nothing (exit 1) if
# none is found. Warns on stderr when PATH git had to be bypassed.
resolve_git_bin() {
  if [ -n "${GIT_BIN:-}" ]; then printf '%s\n' "$GIT_BIN"; return 0; fi
  local path_git
  path_git="$(command -v git 2>/dev/null || true)"
  if [ -n "$path_git" ] && ! is_windows_git "$path_git"; then
    printf '%s\n' "$path_git"; return 0
  fi
  if [ -x /usr/bin/git ]; then
    [ -n "$path_git" ] && echo "warning: PATH git ('$path_git') resolves to the Windows binary; using /usr/bin/git instead" >&2
    printf '%s\n' /usr/bin/git; return 0
  fi
  return 1
}

check_git() {
  local bin symlinks
  bin="$(resolve_git_bin)" || return 0
  symlinks="$("$bin" -C "$ROOT" config --get core.symlinks 2>/dev/null || true)"
  [ "$symlinks" = "false" ] && return 0   # symlinks disabled in this repo — treat as unfixed/missing
  "$bin" --version 2>/dev/null | grep -o '[0-9][0-9.]*' | head -1
}

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

install_git() {
  local path_git bin
  path_git="$(command -v git 2>/dev/null || true)"

  if [ -n "$path_git" ] && is_windows_git "$path_git"; then
    if [ -x /usr/bin/git ]; then
      cat >&2 <<EOF
error: 'git' on PATH resolves to the Windows binary ($path_git), while a
native Linux git is available at /usr/bin/git. This repo relies on
committed symlinks (.constitution.md -> AGENTS.md) that the Windows binary
silently mishandles (especially combined with core.symlinks=false) — that
exact trap broke symlinks earlier in this repo's history.

This is a human-fixable shell misconfiguration, not something init.sh can
install, so it will not attempt to install anything. To fix:
  - use /usr/bin/git explicitly for this repo's git operations, and/or
  - find and fix the 'alias git=...' (or PATH ordering) pointing at the
    Windows git in your shell rc files (~/.zshenv, ~/.zshrc, ~/.bashrc, ...)
  - re-run this init (or set GIT_BIN=/usr/bin/git) once fixed
EOF
    else
      echo "error: 'git' on PATH is the Windows binary ($path_git) and no native /usr/bin/git was found. Install a native Linux git (e.g. 'sudo apt install git') and retry." >&2
    fi
    return 1
  fi

  if [ -z "$path_git" ] && [ ! -x /usr/bin/git ]; then
    echo "error: no git found on PATH or at /usr/bin/git. Install a native Linux git (e.g. 'sudo apt install git') and retry." >&2
    return 1
  fi

  # Only remaining case check_git would have flagged: a native git is present,
  # but core.symlinks is false in this repo. That one IS safe to fix directly.
  bin="${path_git:-/usr/bin/git}"
  echo "core.symlinks is false in this repo (breaks committed symlinks like .constitution.md); fixing with 'git config core.symlinks true' ..." >&2
  "$bin" -C "$ROOT" config core.symlinks true
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
for tool in yq obsidian codegraph git; do
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
  for tool in yq obsidian codegraph git; do echo "  $tool: ${got[$tool]}"; done
} > "$LOCK"
echo "init complete — wrote $LOCK (version $VERSION)"
