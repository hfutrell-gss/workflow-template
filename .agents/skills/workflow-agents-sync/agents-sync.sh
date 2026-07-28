#!/usr/bin/env bash
# workflow-agents-sync — enforce the canonical-format invariant:
#   AGENTS.md (and .agents/) are canonical; CLAUDE.md is at most a header bridge
#   importing @AGENTS.md (root also imports @AGENTS.CORE.md, ahead of @AGENTS.md).
#   Also enforces the proxy rule for skills: .claude/skills/<name>/SKILL.md must be a
#   thin stub (frontmatter + short pointer) whose canonical body + scripts live at
#   .agents/skills/<name>/SKILL.md — never the reverse, and never scripts under
#   .claude/skills/**.
# Applies to this workflow's own root and to every standing-bind repo from
# binds.yaml that is present on disk under `base`.
#
# Usage: agents-sync.sh [--check|--fix]
#   --check (default)  report drift, exit 1 if any
#   --fix              create missing bridges; create missing skill stubs from their
#                      canonical counterpart; non-conforming CLAUDE.md files and
#                      non-conforming skill stubs are still only REPORTED (moving
#                      content into the canonical file is a judgment call — do it,
#                      then re-run)
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
BINDS="$ROOT/binds.yaml"
MODE="${1:---check}"
MAX_BRIDGE_LINES=8
MAX_STUB_BODY_LINES=6

# Root bridge: imports the managed core ahead of this repo's own doctrine.
ROOT_BRIDGE='# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.CORE.md + AGENTS.md are canonical -->

@AGENTS.CORE.md
@AGENTS.md
'
# Standing-bind repo bridge: the plain single-import form (these repos have no
# AGENTS.CORE.md of their own — that file only exists at this workflow's root).
BRIDGE='# CLAUDE.md
<!-- managed by /workflow-agents-sync — no content here; AGENTS.md is canonical -->

@AGENTS.md
'

drift=0
note() { echo "$@"; drift=1; }

# Writes a skill proxy stub at $3, duplicating the canonical file $2's frontmatter
# verbatim (name/description — Claude Code discovery needs it in both places) and a
# body that is only the pointer import. Keep it simple: no attempt to reconcile
# frontmatter drift beyond copying it fresh each time this is called.
create_stub_from_canonical() {
  local name="$1" canonical="$2" dest="$3"
  mkdir -p "$(dirname "$dest")"
  awk 'BEGIN{c=0} /^---$/{c++; print; if(c==2) exit; next} {print}' "$canonical" > "$dest"
  {
    echo ""
    echo "@../../../.agents/skills/$name/SKILL.md"
  } >> "$dest"
}

# The proxy rule for skills (AGENTS.CORE.md): .claude/skills/<name>/SKILL.md is a thin
# stub — frontmatter + a short pointer — whose canonical body + scripts live at
# .agents/skills/<name>/SKILL.md. Runs against any directory that has a .claude/skills/
# (independent of AGENTS.md presence, unlike the bridge check below).
check_skill_stubs() {
  local dir="$1" label="$2"
  local claude_skills="$dir/.claude/skills" agents_skills="$dir/.agents/skills"
  [ -d "$claude_skills" ] || return 0

  # No script (or other non-SKILL.md) files anywhere under .claude/skills/** — nothing
  # executable belongs on the proxy side.
  local f
  while IFS= read -r -d '' f; do
    note "DRIFT   $label: non-stub file under .claude/skills: ${f#"$dir"/} (scripts/other files belong under .agents/skills)"
  done < <(find "$claude_skills" -type f ! -name 'SKILL.md' -print0 2>/dev/null)

  local skill name stub canonical fm_end body_lines
  for skill in "$claude_skills"/*/; do
    [ -d "$skill" ] || continue
    name="$(basename "$skill")"
    stub="$skill/SKILL.md"
    canonical="$agents_skills/$name/SKILL.md"

    if [ ! -f "$canonical" ]; then
      note "DRIFT   $label: .claude/skills/$name/SKILL.md has no canonical counterpart at .agents/skills/$name/SKILL.md"
      continue
    fi

    if [ ! -f "$stub" ]; then
      if [ "$MODE" = "--fix" ]; then
        create_stub_from_canonical "$name" "$canonical" "$stub"
        echo "FIXED   $label: created .claude/skills/$name/SKILL.md stub from canonical"
      else
        note "MISSING $label: .claude/skills/$name/SKILL.md stub missing (--fix creates it from canonical)"
      fi
      continue
    fi

    if ! head -1 "$stub" | grep -q '^---$'; then
      note "DRIFT   $label: .claude/skills/$name/SKILL.md is missing discovery frontmatter"
      continue
    fi
    fm_end="$(awk '/^---$/{c++; if(c==2){print NR; exit}}' "$stub")"
    if [ -z "$fm_end" ]; then
      note "DRIFT   $label: .claude/skills/$name/SKILL.md frontmatter never closes"
      continue
    fi
    body_lines="$(tail -n +"$((fm_end+1))" "$stub" | sed '/^[[:space:]]*$/d' | wc -l)"
    if [ "$body_lines" -gt "$MAX_STUB_BODY_LINES" ]; then
      note "DRIFT   $label: .claude/skills/$name/SKILL.md body is $body_lines non-blank lines (>$MAX_STUB_BODY_LINES) — doctrine belongs in the canonical .agents/skills/$name/SKILL.md"
    elif ! tail -n +"$((fm_end+1))" "$stub" | grep -q "\.agents/skills/$name/SKILL.md"; then
      note "DRIFT   $label: .claude/skills/$name/SKILL.md does not point at its canonical .agents/skills/$name/SKILL.md"
    fi
  done
}

# root=1 additionally requires AGENTS.CORE.md to exist and @AGENTS.CORE.md to be
# imported ahead of @AGENTS.md in CLAUDE.md.
check_dir() {
  local dir="$1" label="$2" root="${3:-0}"
  local bridge="$BRIDGE"
  [ "$root" = "1" ] && bridge="$ROOT_BRIDGE"
  local agents="$dir/AGENTS.md" claude="$dir/CLAUDE.md"

  check_skill_stubs "$dir" "$label"

  [ -f "$agents" ] || return 0        # no law here; nothing to bridge

  if [ "$root" = "1" ] && [ ! -f "$dir/AGENTS.CORE.md" ]; then
    note "MISSING $label: AGENTS.CORE.md not found at repo root (expected here — template link broken?)"
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
  # conformance: must import AGENTS.md (and, at root, @AGENTS.CORE.md too) and be a
  # header at most
  if ! grep -q '@AGENTS.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @AGENTS.md — move its content into AGENTS.md, replace with the bridge"
  elif [ "$root" = "1" ] && ! grep -q '@AGENTS.CORE.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @AGENTS.CORE.md — the managed core won't load this session"
  elif [ "$(wc -l < "$claude")" -gt "$MAX_BRIDGE_LINES" ]; then
    note "DRIFT   $label: CLAUDE.md exceeds $MAX_BRIDGE_LINES lines — content belongs in AGENTS.md"
  fi
}

# ---- scope 1: this workflow's own root ---------------------------------------
check_dir "$ROOT" "root" 1

# ---- scope 2: standing-bind repos from binds.yaml ----------------------------
if [ -f "$BINDS" ] && command -v yq >/dev/null; then
  base_raw="$(yq -r '.base // "~/workbench"' "$BINDS")"; BASE="${base_raw/#\~/$HOME}"
  count="$(yq -r '(.standing // []) | length' "$BINDS" 2>/dev/null || echo 0)"
  if [ "${count:-0}" -gt 0 ] 2>/dev/null; then
    while IFS= read -r name; do
      [ -n "$name" ] || continue
      repo="$BASE/$name"
      [ -e "$repo/.git" ] || continue   # not on disk; workflow-manage's sync-binds.sh handles presence
      check_dir "$repo" "$name"
    done < <(yq -r '.standing[].repo' "$BINDS")
  fi
else
  note "WARN    cannot scan standing binds: binds.yaml or yq unavailable"
fi

if [ "$drift" -eq 0 ]; then
  echo "agents-sync: all conforming"
else
  exit 1
fi
