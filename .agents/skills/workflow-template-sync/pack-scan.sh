#!/usr/bin/env bash
# pack-scan.sh — inspect a pack before its files enter a workflow repo.
#
# Installing a pack copies executable scripts and always-loaded doctrine into a repo you
# then run agents inside. That is a supply-chain path, and this script is the gate on it.
#
# READ THIS BEFORE TRUSTING IT: a heuristic scan is NOT a security boundary. It finds
# careless and obvious-malicious patterns. It does not find a competent attacker, and
# nothing at this size could. The real control is social: install packs you wrote, or
# packs whose maintainers you would already trust with a commit bit on this repo.
# Everything below narrows the window; it does not close it.
#
# Usage:
#   pack-scan.sh <pack-root> [<paths-file>]
#     <pack-root>   directory holding the pack (a checkout, or the sync cache)
#     <paths-file>  optional; the provides list, one path per line. Read from the
#                   pack's own pack.yaml when omitted.
#
# Exit codes: 0 nothing found, 2 findings reported, 1 the scan could not run.
set -uo pipefail

ROOT="${1:-}"
PATHS_FILE="${2:-}"
[ -n "$ROOT" ] || { echo "usage: pack-scan.sh <pack-root> [<paths-file>]" >&2; exit 1; }
[ -d "$ROOT" ] || { echo "error: '$ROOT' is not a directory" >&2; exit 1; }

findings=0
block()  { echo "BLOCK  $1"; findings=$((findings+1)); }
note()   { echo "NOTE   $1"; }

# --- what the pack claims ----------------------------------------------------

tmp_paths=""
if [ -z "$PATHS_FILE" ]; then
  [ -f "$ROOT/pack.yaml" ] || { echo "error: no pack.yaml at '$ROOT' and no paths file given" >&2; exit 1; }
  command -v yq >/dev/null || { echo "error: yq is required — run /workflow-init first" >&2; exit 1; }
  tmp_paths="$(mktemp)"; PATHS_FILE="$tmp_paths"
  yq -r '(.provides // [])[]' "$ROOT/pack.yaml" 2>/dev/null | grep -v '^null$' > "$PATHS_FILE" || true
fi

# A pack may claim ONLY these shapes. Everything else — root law, settings, hooks, MCP
# registrations, overlay slots, application data — belongs to the repo or to the core,
# and a pack asking for it is the finding, whatever the file contains.
#
#   .agents/skills/<name>/**              a skill body
#   .claude/skills/<name>/SKILL.md        its discovery stub
#   workflows/<name>/SKILL.md             a workflow's TIMELESS half
#   workflows/<name>/references/**        and its depth material
#
# Note what is absent: workflows/<name>/<app>/** . A pack ships the TTPs; the
# applications, their carried work, and their sessions are the repo's own data, and a
# pack that could overwrite them could erase a year of work on the next update.
path_allowed() { # path_allowed <path>
  case "$1" in
    .agents/skills/*/\*\*)                        return 0 ;;
    .claude/skills/*/SKILL.md)                    return 0 ;;
    workflows/*/SKILL.md)                         return 0 ;;
    workflows/*/references/\*\*)                  return 0 ;;
    .claude/skills/*/*/*)                         return 1 ;;
  esac
  return 1
}

while IFS= read -r p; do
  [ -n "$p" ] || continue
  if ! path_allowed "$p"; then
    case "$p" in
      .claude/settings*|.claude/hooks*|.mcp.json|*/hooks/*)
        block "claims '$p' — hooks, settings, and MCP registrations execute on every session, without an agent choosing to invoke anything. No pack may install them." ;;
      AGENTS.md|AGENTS.CORE.md|CLAUDE.md|VOICE.md|GLOSSARY.md)
        block "claims '$p' — always-loaded law. A pack that owns this owns every instruction the agent starts with." ;;
      .agents/orchestrate/*|.agents/craft/*|.agents/code-craft/*|.agents/init/tools.local.d/*|*.local.md|*.local.yaml)
        block "claims '$p' — an overlay slot. Overlays are the repo's answer to the pack; a pack that writes its own overlay has removed the repo's only override." ;;
      workflows/*/*/*)
        block "claims '$p' — application data under a workflow (profile, carried work, or a session). A pack ships the TTPs, never the repo's record of its own work." ;;
      *)
        block "claims '$p' — outside the pack namespace (.agents/skills/<name>/**, .claude/skills/<name>/SKILL.md, workflows/<name>/SKILL.md, workflows/<name>/references/**)." ;;
    esac
  fi
done < "$PATHS_FILE"

# --- what the claimed files contain ------------------------------------------
# Content checks run only over files the pack actually installs. Anything else in the
# repo is never copied, so it cannot execute here.

files="$(mktemp)"
while IFS= read -r p; do
  [ -n "$p" ] || continue
  t="$ROOT/${p%/\*\*}"
  if [ -d "$t" ]; then find "$t" -type f >> "$files" 2>/dev/null
  elif [ -f "$t" ]; then printf '%s\n' "$t" >> "$files"
  fi
done < "$PATHS_FILE"
sort -u "$files" -o "$files"

hits() { # hits <label> <extended-regex>
  local label="$1" re="$2" out
  out="$(grep -rInE --binary-files=without-match "$re" $(tr '\n' ' ' < "$files") 2>/dev/null | head -20)"
  [ -n "$out" ] || return 0
  block "$label"
  printf '%s\n' "$out" | sed "s|^$ROOT/||; s/^/         /"
}

if [ -s "$files" ]; then
  hits "reads credentials or secrets — a pack has no reason to touch these." \
    '(\.ssh/|id_rsa|id_ed25519|\.aws/|\.netrc|\.npmrc|GITHUB_TOKEN|ANTHROPIC_API_KEY|gh auth token|printenv|env \|)'

  hits "sends data out, or runs downloaded content." \
    '(curl[^|]*\||wget[^|]*\||\| *(ba)?sh\b|nc -|/dev/tcp/|ssh +[^ ]+@|git +push)'

  hits "deletes or writes outside the repo it is installed into." \
    '(rm +-[rf]{1,2}[a-z]* +(/|\$HOME|~)|> *(/etc/|\$HOME/|~/)|chmod +[0-7]*7[0-7]* +/)'

  hits "obfuscated payload — decoding into a shell hides what the file does from review." \
    '(base64 +(-d|--decode)|eval +"?\$|printf +.\\\\x)'

  # Informational: every executable file, always listed. Not a finding -- a pack of
  # skills legitimately ships scripts -- but the reviewer should know what will land.
  execs="$(grep -rIl --binary-files=without-match '^#!' $(tr '\n' ' ' < "$files") 2>/dev/null | sed "s|^$ROOT/||")"
  if [ -n "$execs" ]; then
    note "executable files this pack installs — read them before trusting the pack:"
    printf '%s\n' "$execs" | sed 's/^/         /'
  fi
fi

rm -f "$files" ${tmp_paths:+"$tmp_paths"}

echo
if [ "$findings" -eq 0 ]; then
  echo "pack-scan: no findings. This is a heuristic pass, not a guarantee — it does not"
  echo "           detect a competent attacker. Install packs you wrote, or packs whose"
  echo "           maintainer you already trust with this repo."
  exit 0
fi
echo "pack-scan: $findings finding(s). Read each one; they are reasons to inspect the pack,"
echo "           not verdicts. Install anyway with 'add --reviewed' once you have."
exit 2
