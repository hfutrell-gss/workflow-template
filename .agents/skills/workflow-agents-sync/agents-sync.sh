#!/usr/bin/env bash
# workflow-agents-sync — enforce the canonical-format invariant:
#   AGENTS.md (and .agents/) are canonical; CLAUDE.md is at most a header bridge
#   importing @AGENTS.md (root also imports @AGENTS.CORE.md and @VOICE.md, ahead of
#   @AGENTS.md).
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

# One bridge form everywhere, root included: CLAUDE.md holds a single pointer at the
# canonical AGENTS.md and never composes. At the root, AGENTS.md imports AGENTS.CORE.md
# and AGENTS.CORE.md imports VOICE.md -- checked separately by check_root_chain.
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

# root=1 additionally requires the AGENTS-side chain: AGENTS.CORE.md must exist,
# AGENTS.md must import it, and it must import VOICE.md. CLAUDE.md is the same single
# pointer everywhere -- it never composes.
check_root_chain() {
  local dir="$1" label="$2"
  local core="$dir/AGENTS.CORE.md" agents="$dir/AGENTS.md" voice="$dir/VOICE.md"

  if [ ! -f "$core" ]; then
    note "MISSING $label: AGENTS.CORE.md not found at repo root (expected here -- template link broken?)"
    return 0
  fi
  if ! grep -q '@AGENTS.CORE.md' "$agents"; then
    if [ "$MODE" = "--fix" ]; then
      # Insert after YAML frontmatter if present, else at the very top.
      awk 'NR==1 && $0=="---" {fm=1; print; next}
           fm==1 && $0=="---" {print; print ""; print "@AGENTS.CORE.md"; fm=2; next}
           fm!=1 && !done {print "@AGENTS.CORE.md"; print ""; done=1}
           {print}' "$agents" > "$agents.tmp" && mv "$agents.tmp" "$agents"
      echo "FIXED   $label: AGENTS.md now imports @AGENTS.CORE.md"
    else
      note "DRIFT   $label: AGENTS.md does not import @AGENTS.CORE.md -- the managed core won't load this session"
    fi
  fi
  if [ -f "$voice" ] && ! grep -q '@VOICE.md' "$core"; then
    note "DRIFT   $label: AGENTS.CORE.md does not import @VOICE.md -- the mandated voice loads nowhere (fix upstream, not here)"
  fi
}

check_dir() {
  local dir="$1" label="$2" root="${3:-0}"
  local bridge="$BRIDGE"
  local agents="$dir/AGENTS.md" claude="$dir/CLAUDE.md"

  check_skill_stubs "$dir" "$label"

  [ -f "$agents" ] || return 0        # no law here; nothing to bridge

  [ "$root" = "1" ] && check_root_chain "$dir" "$label"

  if [ ! -f "$claude" ]; then
    if [ "$MODE" = "--fix" ]; then
      printf '%s' "$bridge" > "$claude"
      echo "FIXED   $label: created CLAUDE.md bridge"
    else
      note "MISSING $label: AGENTS.md has no CLAUDE.md bridge (--fix creates it)"
    fi
    return 0
  fi
  # conformance: one pointer at @AGENTS.md, a header at most, and no composition --
  # a root CLAUDE.md importing AGENTS.CORE.md/VOICE.md directly is drift now, not the
  # required form, because that decision belongs to the AGENTS chain.
  if ! grep -q '@AGENTS.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md does not import @AGENTS.md — move its content into AGENTS.md, replace with the bridge"
  elif grep -qE '^@(AGENTS\.CORE|VOICE)\.md' "$claude"; then
    note "DRIFT   $label: CLAUDE.md composes (@AGENTS.CORE.md/@VOICE.md) — that belongs in AGENTS.md -> AGENTS.CORE.md -> VOICE.md; CLAUDE.md holds one pointer"
  elif [ "$(wc -l < "$claude")" -gt "$MAX_BRIDGE_LINES" ]; then
    note "DRIFT   $label: CLAUDE.md exceeds $MAX_BRIDGE_LINES lines — content belongs in AGENTS.md"
  fi
}

# ---- scope 1: this workflow's own root ---------------------------------------
check_dir "$ROOT" "root" 1

# ---- scope 2: standing-bind repos from binds.yaml ----------------------------
if [ -f "$BINDS" ] && command -v yq >/dev/null; then
  # Same path-resolution rule as workflow-manage/sync-binds.sh: `base` starting with
  # `/` or `~` is absolute/home-relative (legacy); anything else resolves relative to
  # this workflow repo's root. Default: `./workspace`.
  base_raw="$(yq -r '.base // "./workspace"' "$BINDS")"
  case "$base_raw" in
    /*) BASE="$base_raw" ;;
    \~*) BASE="${base_raw/#\~/$HOME}" ;;
    *) BASE="$ROOT/${base_raw#./}" ;;
  esac
  mkdir -p "$BASE"
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
