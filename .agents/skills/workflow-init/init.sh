#!/usr/bin/env bash
# workflow-init — install/verify the tooling this repo's procedures assume, then
# record the init version in <repo-root>/init.lock (per-machine, gitignored).
#
# Usage: init.sh                         # ensure required + decided-install recommended
#                                         # tools, write init.lock
#        init.sh --check                 # verify only (see exit-code rules below)
#        init.sh decide <tool> <install|skip>
#                                         # record this machine's per-tool decision into
#                                         # init.lock's decisions: section
#
# ---- tool tiers ---------------------------------------------------------------
# REQUIRED  — every procedure in this repo assumes these; missing = hard failure.
# RECOMMENDED — useful, but opt-in per machine via `decide`. A recommended tool with
#   no decision (or decision=skip) is never installed by a plain run and never fails
#   --check; it only prints an informational NOTE. A recommended tool decided
#   "install" but not actually present IS a failure (the decision was made; this
#   machine isn't honoring it) — both for --check and for a plain run's own install
#   attempt.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$HERE/VERSION")"
LOCK="$ROOT/init.lock"

REQUIRED=(git yq)
RECOMMENDED=(obsidian codegraph opencodex)

# ---- derivation-owned tool overlays ------------------------------------------
# The categorical rule: the template defines the shapes and owns every operation on
# them; derivations contribute data. Tool installation is a template shape (tiers,
# per-machine decisions, init.lock), so a derivation must NOT fork this script to add
# a tool of its own — an `update` would overwrite it. Instead it drops a definition
# into .agents/init/tools.local.d/<tool>.sh, which is unmanaged and never touched by
# `update`, exactly like .agents/craft/<skill>.local.md and
# .agents/orchestrate/roster.local.yaml.
#
# Each overlay file defines, for a tool named <tool>:
#   check_<tool>()              REQUIRED. Print a version/"present" on stdout and
#                               return 0 when installed; return non-zero (or print
#                               nothing) when not.
#   install_<tool>()            REQUIRED. Install it. Return non-zero on failure.
#   unsupported_reason_<tool>() OPTIONAL. Print why THIS machine cannot host the tool
#                               and return 0; return 1 when the machine is fine. Used
#                               for platform-limited tools — see tool_unsupported_reason.
# and declares itself with:
#   register_tool <tool>        appends <tool> to the RECOMMENDED tier.
#
# Overlay tools are always RECOMMENDED: a derivation cannot make its own tool mandatory
# for a machine, because `--check` failing on a tool the template never heard of would
# make the constitution's init mandate unsatisfiable for anyone without it.
# The overlay directory is sourced further down, AFTER this script's own helpers and
# check_/install_ functions exist — an overlay may legitimately want `have` or
# resolve_git_bin, and validation of the registered set has to run once everything is
# defined. See "derivation tool overlays" below.
TOOLS_OVERLAY_DIR="$ROOT/.agents/init/tools.local.d"
OVERLAY_TOOLS=()          # names registered by overlays (not the template's own tools)

register_tool() {
  local t="$1"
  case "$t" in
    ''|*[!a-z0-9_-]*)
      echo "error: register_tool: '$t' is not a valid tool name (lowercase letters, digits, '_' and '-' only)" >&2
      return 1 ;;
  esac
  # A required tool's name is reserved — silently shadowing git or yq would be a
  # spectacular way for a derivation to break its own bootstrap.
  local r
  for r in "${REQUIRED[@]}"; do
    [ "$t" = "$r" ] && { echo "error: register_tool: '$t' is a REQUIRED tool name and cannot be redefined by an overlay" >&2; return 1; }
  done
  for r in "${RECOMMENDED[@]}"; do
    [ "$t" = "$r" ] && return 0   # already registered (template's own, or a re-source)
  done
  RECOMMENDED+=("$t")
  OVERLAY_TOOLS+=("$t")
}

# ---- platform gate ------------------------------------------------------------
# init.sh's install_* functions (yq/obsidian/codegraph/opencodex binaries, WSLg
# wrapper) are only written/vetted for Linux x86_64 (incl. WSL2). Fail loudly before
# attempting any install on anything else, rather than partially installing the wrong
# arch.
_os="$(uname -s)"; _arch="$(uname -m)"
if [ "$_os-$_arch" != "Linux-x86_64" ]; then
  echo "error: init currently supports Linux x86_64 / WSL2 only (detected: $_os-$_arch); extend init.sh for this platform." >&2
  exit 1
fi

# ---- tool checks ------------------------------------------------------------
have() { command -v "$1" >/dev/null 2>&1; }

check_yq()       { have yq && yq --version 2>/dev/null | grep -o 'v[0-9][0-9.]*' | head -1; }
check_obsidian() { have obsidian && echo present; }
check_codegraph(){ have codegraph && (codegraph --version 2>/dev/null || echo present) | head -1; }
check_opencodex(){ have ocx && (ocx --version 2>/dev/null || echo present) | head -1; }

# git is special: on this machine's history, `git` was aliased/PATH-resolved to the
# Windows binary (/mnt/c/.../Git/bin/git.exe), which behaves differently enough from
# native git (line endings, permissions, and historically: silently mishandling
# committed symlinks when core.symlinks=false) that AGENTS.CORE.md mandates native
# git explicitly for every git operation in this repo and its derivations. check_git
# must catch both halves of that trap: a non-native git resolving on PATH, and
# core.symlinks=false here. GIT_BIN=/path/to/git is an escape hatch to force a binary.
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

# Loudly warn (read-only, non-fatal) about the Windows-git trap even when check_git
# itself passes — this script runs under bash, which never sources ~/.zshenv or
# ~/.zshrc, so a human's interactive `git` can still be shadowed by a `git=...exe`
# alias there while this script's own `command -v git` resolves fine. Grubs both
# rc files (read-only grep, no sourcing) and this script's own PATH resolution.
# Called unconditionally so both --check and a normal run print it.
warn_windows_git_alias() {
  local rc hit path_git
  for rc in "$HOME/.zshenv" "$HOME/.zshrc"; do
    [ -f "$rc" ] || continue
    hit="$(grep -nE 'alias[[:space:]]+git=.*(\.exe|/mnt/c)' "$rc" 2>/dev/null | head -1 || true)"
    if [ -n "$hit" ]; then
      echo "WARNING: 'git' is aliased to a Windows binary at $rc:${hit%%:*} — this shadows native git in interactive shells (this script itself is unaffected; bash doesn't source $rc). Always invoke /usr/bin/git explicitly for this repo, or fix/guard the alias in $rc." >&2
    fi
  done
  path_git="$(command -v git 2>/dev/null || true)"
  if [ -n "$path_git" ] && is_windows_git "$path_git"; then
    echo "WARNING: the first 'git' on this script's PATH resolves to a Windows binary ($path_git). Use /usr/bin/git explicitly for this repo, or set GIT_BIN=/usr/bin/git." >&2
  fi
  return 0
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
native Linux git is available at /usr/bin/git. AGENTS.CORE.md mandates
native git explicitly for this repo and its derivations.

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
  # but core.symlinks is false in this repo. Fix it directly — cheap and safe.
  bin="${path_git:-/usr/bin/git}"
  echo "core.symlinks is false in this repo; fixing with 'git config core.symlinks true' ..." >&2
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
  #
  # Pinned to the v1.5.0 tag (the release vetted 2026-07-27) rather than `main`, so a
  # future push to main can't silently swap in unvetted install logic. Verified this
  # exact tag path resolves (curl -fsI -> 200) before fetching it.
  local pin="v1.5.0"
  local url="https://raw.githubusercontent.com/colbymchenry/codegraph/${pin}/install.sh"
  if ! curl -fsSI "$url" >/dev/null 2>&1; then
    echo "error: pinned codegraph installer not found at $url (tag '$pin' missing/moved?). Not falling back to 'main' — set CODEGRAPH_INSTALL to override." >&2
    return 1
  fi
  # install.sh (inspected at this tag) DOES support a version pin: CODEGRAPH_VERSION
  # (defaults to resolving GitHub's "latest" release otherwise). Pin the binary release
  # to match the installer source, so both halves of "codegraph v1.5.0" refer to the
  # same vetted artifact. Residual risk: the release DOES publish a SHA256SUMS asset
  # (github.com/colbymchenry/codegraph/releases/tag/v1.5.0), but install.sh does not
  # verify the downloaded tarball against it, and reimplementing that check here would
  # mean re-downloading the tarball ourselves outside the vendored installer flow —
  # deferred rather than forking their script. Transport is at least TLS-pinned GitHub
  # Releases, not an arbitrary mirror.
  local cmd="${CODEGRAPH_INSTALL:-curl -fsSL $url | CODEGRAPH_VERSION=$pin sh}"
  echo "installing codegraph via: $cmd" >&2
  eval "$cmd"
}

install_opencodex() {
  # opencodex (https://github.com/lidge-jun/opencodex, npm @bitkyc08/opencodex) — a
  # local model-gateway proxy (Codex/Claude Code/Claude Desktop -> 40+ providers).
  # Vetted 2026-07-28: MIT license, ~5.5k GitHub stars, actively released (npm
  # dist-tag "latest" resolved to 2.7.42 on the vetting date). PROVENANCE NOTE: this
  # is an individual-maintainer project (bitkyc08/lidge-jun) whose whole purpose is
  # to sit directly in the path of every LLM request a routed session makes — that is
  # a materially different trust posture than yq/Obsidian/codegraph. It is
  # RECOMMENDED-tier, never auto-installed: this function only runs when this
  # machine's init.lock decisions: section says `opencodex: install` (see
  # `init.sh decide opencodex install`). See workflow-gateway's SKILL.md for the
  # opt-in-per-session usage doctrine once installed.
  #
  # Pinned to the exact version verified above rather than "latest", so a future
  # publish can't silently swap in unvetted code.
  #
  # User-scoped, never sudo: this repo's other installers (yq, Obsidian, codegraph)
  # all land in ~/.local/{bin,opt} with no root required, and a system-package npm
  # (e.g. Debian/Ubuntu's) commonly defaults its global prefix to a root-owned path
  # like /usr/lib/node_modules — a bare `npm install -g` there fails EACCES for a
  # non-root user. Use an explicit user-owned --prefix instead, and symlink the
  # resulting binaries into ~/.local/bin (same landing spot as codegraph) so
  # check_opencodex's `have ocx` finds them the same way every other tool here does.
  local pin="2.7.42"
  local prefix="$HOME/.local/share/npm-global"
  command -v npm >/dev/null 2>&1 || { echo "error: npm not found — opencodex requires Node 18+ (npm on PATH). Install Node first." >&2; return 1; }
  mkdir -p "$prefix" "$HOME/.local/bin"
  echo "installing opencodex (pinned @bitkyc08/opencodex@$pin) via 'npm install -g --prefix $prefix' ..." >&2
  npm install -g --prefix "$prefix" "@bitkyc08/opencodex@$pin"
  local bin
  for bin in ocx opencodex; do
    [ -e "$prefix/bin/$bin" ] && ln -sf "$prefix/bin/$bin" "$HOME/.local/bin/$bin"
  done
}

# ---- source derivation tool overlays ----------------------------------------
# Deliberately here, not up beside the tier declaration: everything above is now
# defined, so an overlay may use `have`/`resolve_git_bin`, and the validation below can
# check the registered set once all functions exist.
if [ -d "$TOOLS_OVERLAY_DIR" ]; then
  for _overlay in "$TOOLS_OVERLAY_DIR"/*.sh; do
    [ -f "$_overlay" ] || continue          # unmatched glob
    # shellcheck source=/dev/null
    . "$_overlay" || { echo "error: failed to source tool overlay $_overlay" >&2; exit 1; }
  done
  unset _overlay
  # Validate only what the overlays registered — the template's own tools are defined
  # in this file and need no proof. Fail loudly on a half-written overlay here, rather
  # than at the point of use where a missing install_ would surface as a mysterious
  # "command not found" partway through an install.
  for _t in "${OVERLAY_TOOLS[@]+"${OVERLAY_TOOLS[@]}"}"; do
    for _fn in "check_$_t" "install_$_t"; do
      declare -F "$_fn" >/dev/null || {
        echo "error: tool '$_t' is registered but $_fn() is not defined — check $TOOLS_OVERLAY_DIR/$_t.sh" >&2
        exit 1
      }
    done
  done
  unset _t _fn
fi

# ---- decisions (recommended-tier, per-machine, stored in init.lock) ----------
# init.lock's `decisions:` section maps a RECOMMENDED tool to install|skip, each line
# formatted `  <tool>: <install|skip>  # <date>`. Parsed with awk/sed only — yq itself
# is a required tool this script may still be bootstrapping, so the lock format can't
# depend on it.

has_decisions_section() { [ -f "$LOCK" ] && grep -q '^decisions:' "$LOCK"; }

# Prints the tool's decisions: line verbatim (minus the "  <tool>: " prefix), e.g.
# "install  # 2026-07-27" — or nothing if the tool has no recorded decision.
get_decision_raw() {
  local tool="$1"
  [ -f "$LOCK" ] || return 0
  awk -v pfx="  $tool:" '
    /^decisions:/ { indec=1; next }
    indec && /^[^[:space:]]/ { indec=0 }
    indec && index($0, pfx) == 1 {
      line = substr($0, length(pfx) + 1)
      sub(/^[[:space:]]+/, "", line)
      print line
      exit
    }
  ' "$LOCK" 2>/dev/null || true
}

# Prints just the value (install/skip), trailing comment stripped.
get_decision_value() {
  get_decision_raw "$1" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*#.*$//'
}

# init.sh decide <tool> <install|skip> — records/updates this machine's decision for
# a recommended tool directly in init.lock (creating it if absent). Does not itself
# install/uninstall anything or touch the tools: section — run init.sh afterward to
# apply.
cmd_decide() {
  local tool="${1:-}" value="${2:-}"
  [ -n "$tool" ] || { echo "usage: init.sh decide <tool> <install|skip>  (tools: ${RECOMMENDED[*]})" >&2; exit 1; }
  # Validate against the RECOMMENDED array rather than a hardcoded list, so tools
  # registered by a derivation's overlay are decidable too.
  local known=0 r
  for r in "${RECOMMENDED[@]}"; do [ "$tool" = "$r" ] && { known=1; break; }; done
  [ "$known" -eq 1 ] || {
    echo "error: '$tool' is not a recommended tool (choices: ${RECOMMENDED[*]}) — required tools (${REQUIRED[*]}) aren't decided, they're mandatory" >&2
    exit 1
  }
  case "$value" in
    install|skip) ;;
    *) echo "error: decision must be 'install' or 'skip' (got '${value:-<empty>}')" >&2; exit 1 ;;
  esac

  local today tmp
  today="$(date -I)"
  tmp="$(mktemp)"
  if [ -f "$LOCK" ]; then cp "$LOCK" "$tmp"; else : > "$tmp"; fi

  if grep -q '^decisions:' "$tmp"; then
    # Drop any existing line for this tool, then re-insert right after the header.
    grep -vE "^  $tool: " "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
    awk -v t="$tool" -v v="$value" -v d="$today" '
      { print }
      /^decisions:/ && !done { print "  " t ": " v "  # " d; done=1 }
    ' "$tmp" > "$tmp.2" && mv "$tmp.2" "$tmp"
  else
    {
      echo "decisions:"
      echo "  $tool: $value  # $today"
    } >> "$tmp"
  fi

  mv "$tmp" "$LOCK"
  echo "recorded decision: $tool = $value ($today) in $LOCK"
  echo "next: run '.agents/skills/workflow-init/init.sh' to apply it"
}

# ---- dispatch: decide subcommand ---------------------------------------------
if [ "${1:-}" = "decide" ]; then
  shift
  cmd_decide "$@"
  exit 0
fi

# ---- run --------------------------------------------------------------------
warn_windows_git_alias   # loud, read-only, non-fatal — runs in --check and normal runs alike

declare -A got
declare -A decision       # tool -> "install"/"skip"/"" (recommended tools only)
declare -A decision_raw   # tool -> exact existing "value  # date" line, if one exists
missing_required=()
recommended_decided_missing=()   # decided install, but check_$tool failed
recommended_unsupported=()       # decided install, but this platform can't host it
declare -A unsupported_reason    # tool -> why this platform can't host it

# A tool may be viable only on a subset of the platforms that clear the Linux-x86_64
# gate above (e.g. one needing WSL/Windows interop). A tool decided `install` on a
# machine that physically cannot host it is NOT drift to fail on: the decision is
# honored as far as the machine allows, and the shortfall is reported as a NOTE.
# Without this, a single `decide <tool> install` shared through init.lock would make
# --check fail forever on every machine that cannot run it.
#
# Opt in by defining unsupported_reason_<tool>() in the tool's overlay: print the
# reason and return 0 when this machine can't host it, return 1 when it can.
tool_unsupported_reason() {
  local fn="unsupported_reason_$1"
  declare -F "$fn" >/dev/null || return 1
  "$fn"
}

for tool in "${REQUIRED[@]}"; do
  v="$("check_$tool" || true)"
  if [ -n "$v" ]; then got[$tool]="$v"; else missing_required+=("$tool"); fi
done

for tool in "${RECOMMENDED[@]}"; do
  v="$("check_$tool" || true)"
  [ -n "$v" ] && got[$tool]="$v"

  raw="$(get_decision_raw "$tool")"
  if [ -n "$raw" ]; then
    decision_raw[$tool]="$raw"
    decision[$tool]="$(printf '%s\n' "$raw" | sed -E 's/^[[:space:]]*//; s/[[:space:]]*#.*$//')"
  elif [ -f "$LOCK" ] && ! has_decisions_section && { [ "$tool" = "obsidian" ] || [ "$tool" = "codegraph" ]; } && [ -n "$v" ]; then
    # Migration: a pre-v4 init.lock that EXISTS but has no decisions: section at all
    # implicitly ran these two tools unconditionally. Grandfather this machine as
    # having decided "install" for whichever of the two are already present, rather
    # than silently dropping tools a prior init already installed. Guarded on
    # [ -f "$LOCK" ] so a genuinely fresh machine (no lock at all yet) is NOT
    # grandfathered — it starts undecided like opencodex, which is never
    # grandfathered under any circumstance (it's new; there is no prior init.sh run
    # to inherit a decision from).
    decision[$tool]="install"
  fi

  if [ -z "${got[$tool]:-}" ] && [ "${decision[$tool]:-}" = "install" ]; then
    if reason="$(tool_unsupported_reason "$tool")"; then
      recommended_unsupported+=("$tool")
      unsupported_reason[$tool]="$reason"
    else
      recommended_decided_missing+=("$tool")
    fi
  fi
done

if [ "${1:-}" = "--check" ]; then
  ok=1
  lockv="$( [ -f "$LOCK" ] && grep -m1 '^version:' "$LOCK" | awk '{print $2}' || echo none)"
  if [ "$lockv" != "$VERSION" ]; then
    echo "init.lock version '$lockv' != required '$VERSION'"
    ok=0
  fi
  if [ "${#missing_required[@]}" -gt 0 ]; then
    echo "missing required tools: ${missing_required[*]}"
    ok=0
  fi
  if [ "${#recommended_decided_missing[@]}" -gt 0 ]; then
    echo "recommended tools decided 'install' but not present on this machine: ${recommended_decided_missing[*]} (the decision was made; this machine isn't honoring it — run init.sh)"
    ok=0
  fi
  for tool in "${recommended_unsupported[@]+"${recommended_unsupported[@]}"}"; do
    echo "NOTE: recommended tool '$tool' — decision 'install' cannot be honored on this platform (${unsupported_reason[$tool]}); informational only, not drift."
  done
  for tool in "${RECOMMENDED[@]}"; do
    [ -n "${got[$tool]:-}" ] && continue
    d="${decision[$tool]:-}"
    [ "$d" = "install" ] && continue   # already reported above (failure, or unsupported NOTE)
    echo "NOTE: recommended tool '$tool' not installed (decision: ${d:-undecided}) — informational only. Opt in with: init.sh decide $tool install && init.sh"
  done
  if [ "$ok" -eq 1 ]; then
    echo "init ok (version $VERSION; present: ${!got[*]})"
    exit 0
  fi
  exit 1
fi

for tool in "${missing_required[@]+"${missing_required[@]}"}"; do
  "install_$tool"
  v="$("check_$tool" || true)"
  [ -n "$v" ] && got[$tool]="$v" || { echo "error: $tool still unavailable after install" >&2; exit 1; }
done

for tool in "${RECOMMENDED[@]}"; do
  [ -n "${got[$tool]:-}" ] && continue   # already present, nothing to do
  d="${decision[$tool]:-}"
  if [ "$d" = "install" ]; then
    if reason="$(tool_unsupported_reason "$tool")"; then
      echo "NOTE: recommended tool '$tool' decided 'install', but this platform can't host it — $reason. Skipping (not an error)." >&2
      continue
    fi
    "install_$tool"
    v="$("check_$tool" || true)"
    [ -n "$v" ] && got[$tool]="$v" || { echo "error: $tool still unavailable after install (decision: install)" >&2; exit 1; }
  else
    echo "NOTE: recommended tool '$tool' not installed (decision: ${d:-undecided}) — opt in with: init.sh decide $tool install && init.sh"
  fi
done

{
  echo "version: $VERSION"
  echo "date: $(date -I)"
  echo "tools:"
  for tool in "${REQUIRED[@]}" "${RECOMMENDED[@]}"; do
    [ -n "${got[$tool]:-}" ] && echo "  $tool: ${got[$tool]}"
  done
  echo "decisions:"
  for tool in "${RECOMMENDED[@]}"; do
    if [ -n "${decision_raw[$tool]:-}" ]; then
      echo "  $tool: ${decision_raw[$tool]}"
    elif [ -n "${decision[$tool]:-}" ]; then
      echo "  $tool: ${decision[$tool]}  # $(date -I) (grandfathered)"
    fi
  done
} > "$LOCK"
echo "init complete — wrote $LOCK (version $VERSION)"
