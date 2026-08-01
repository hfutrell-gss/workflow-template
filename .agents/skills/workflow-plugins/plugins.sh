#!/usr/bin/env bash
# workflow-plugins — the registry for capability consumed as a Claude Code PLUGIN.
#
# Packs install capability this system owns; plugins consume capability it does not.
# The harness already enforces the default set and the per-user override. What it does
# NOT hold is why the repo wants a plugin, what a review of it found, and why a given
# user declined it. That is this file's job. Doctrine: SKILL.md.
#
# Usage:
#   plugins.sh list     what is declared, and its state on this machine
#   plugins.sh render   plugins.yaml + the decline overlay -> the two settings files
#   plugins.sh check    PLUGIN-001..004; exit 0 clear, 2 unmet, 1 the tool broke
#
# Files (SKILL.md "The files"):
#   plugins.yaml                        the registry              committed
#   .claude/settings.json               the default set           committed, GENERATED
#   .agents/plugins/plugins.local.yaml  this user's declines      per-machine
#   .claude/settings.local.json         the declines, as read     per-machine, GENERATED
#
# render MERGES. Both settings files hold unrelated keys (permissions, model) that are
# not this skill's to touch, and it must be idempotent — PLUGIN-001 compares the
# committed file against a fresh render.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
REGISTRY="$ROOT/plugins.yaml"
OVERLAY="$ROOT/.agents/plugins/plugins.local.yaml"
SETTINGS="$ROOT/.claude/settings.json"
SETTINGS_LOCAL="$ROOT/.claude/settings.local.json"
GIT=/usr/bin/git

command -v yq >/dev/null || { echo "error: yq (mikefarah v4) is required — run /workflow-init first" >&2; exit 1; }
command -v jq >/dev/null || { echo "error: jq is required — run /workflow-init first" >&2; exit 1; }

die() { echo "error: $*" >&2; exit 1; }

# A repo with no registry is complete, not degraded. Every subcommand returns quietly.
no_registry() { [ ! -f "$REGISTRY" ]; }

names()        { yq -r '.plugins[]?.name' "$REGISTRY"; }
field()        { yq -r ".plugins[] | select(.name == \"$1\") | .$2 // \"\"" "$REGISTRY"; }
qualified() {                            # qualified <name> -> name@marketplace
  local mkt; mkt="$(field "$1" marketplace)"
  [ -n "$mkt" ] || die "plugins.yaml: '$1' has no marketplace:"
  printf '%s@%s\n' "$1" "$mkt"
}
declined_names() { [ -f "$OVERLAY" ] && yq -r '.decline[]?.name' "$OVERLAY" || true; }
decline_reason() { [ -f "$OVERLAY" ] && yq -r ".decline[] | select(.name == \"$1\") | .why // \"\"" "$OVERLAY" || true; }
is_declined()    { declined_names | grep -qxF "$1"; }

# ---------------------------------------------------------------- render

# The default set, as the harness reads it. Only `default: true` is enabled for
# everyone; `default: false` is declared and reviewed but nobody gets it automatically.
render_settings() {                      # -> the merged .claude/settings.json on stdout
  local marketplaces enabled
  marketplaces="$(yq -o=json '.marketplaces // {}' "$REGISTRY")"
  enabled="$(
    for n in $(names); do
      [ "$(field "$n" default)" = "true" ] || continue
      printf '%s\n' "$(qualified "$n")"
    done | jq -R . | jq -s 'map({key: ., value: true}) | from_entries'
  )"
  jq -n --argjson base "$( [ -f "$SETTINGS" ] && cat "$SETTINGS" || echo '{}' )" \
        --argjson m "$marketplaces" --argjson e "$enabled" '
    $base
    | if ($m | length) > 0 then .extraKnownMarketplaces = $m else del(.extraKnownMarketplaces) end
    | if ($e | length) > 0 then .enabledPlugins = $e else del(.enabledPlugins) end
  '
}

# A decline is an override of the repo's default, so it only ever writes `false`, and
# only for plugins this registry declares. It never removes a key the user set by hand
# through /plugin disable for something else.
render_settings_local() {                # -> the merged .claude/settings.local.json
  local declines
  declines="$(
    for n in $(declined_names); do
      names | grep -qxF "$n" || { echo "warn: decline overlay names '$n', which plugins.yaml does not declare — ignored" >&2; continue; }
      printf '%s\n' "$(qualified "$n")"
    done | jq -R . | jq -s 'map(select(length > 0) | {key: ., value: false}) | from_entries'
  )"
  jq -n --argjson base "$( [ -f "$SETTINGS_LOCAL" ] && cat "$SETTINGS_LOCAL" || echo '{}' )" \
        --argjson d "$declines" --argjson keys "$(
          for n in $(names); do printf '%s\n' "$(qualified "$n")"; done | jq -R . | jq -s 'map(select(length > 0))'
        )" '
    # Drop every entry this registry owns, then re-add only the current declines. That
    # is what makes render idempotent AND makes un-declining actually take effect.
    ($base.enabledPlugins // {}) as $ep
    | ($ep | with_entries(select(.key as $k | $keys | index($k) | not))) as $foreign
    | ($foreign + $d) as $merged
    | $base
    | if ($merged | length) > 0 then .enabledPlugins = $merged else del(.enabledPlugins) end
  '
}

cmd_render() {
  no_registry && { echo "no plugins.yaml — nothing to render"; return 0; }
  mkdir -p "$(dirname "$SETTINGS")"
  render_settings > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  echo "rendered ${SETTINGS#"$ROOT"/}"
  local local_out
  local_out="$(render_settings_local)"
  if [ "$local_out" = "{}" ] && [ ! -f "$SETTINGS_LOCAL" ]; then
    echo "no declines — ${SETTINGS_LOCAL#"$ROOT"/} not created"
  else
    printf '%s\n' "$local_out" > "$SETTINGS_LOCAL.tmp" && mv "$SETTINGS_LOCAL.tmp" "$SETTINGS_LOCAL"
    echo "rendered ${SETTINGS_LOCAL#"$ROOT"/}"
  fi
}

# ---------------------------------------------------------------- list

enabled_in() {                           # enabled_in <file> <name@marketplace>
  [ -f "$1" ] || return 1
  [ "$(jq -r --arg k "$2" '.enabledPlugins[$k] // "unset"' "$1")" = "true" ]
}
disabled_in() {                          # disabled_in <file> <name@marketplace>
  [ -f "$1" ] || return 1
  [ "$(jq -r --arg k "$2" '.enabledPlugins[$k] // "unset"' "$1")" = "false" ]
}

cmd_list() {
  no_registry && { echo "no plugins.yaml — this repo declares no plugins"; return 0; }
  printf '%-24s %-28s %s\n' PLUGIN STATE WHY
  local n q state why
  for n in $(names); do
    q="$(qualified "$n")"
    if is_declined "$n"; then
      why="$(decline_reason "$n")"
      state="declined"
      [ -n "$why" ] || why="(no reason given — PLUGIN-003)"
    elif disabled_in "$SETTINGS_LOCAL" "$q"; then
      state="disabled (no overlay entry)"
      why="declined through the harness; the reason is not recorded"
    elif enabled_in "$SETTINGS" "$q"; then
      state="enabled (repo default)"
      why="$(field "$n" why | tr '\n' ' ' | cut -c1-60)"
    elif [ "$(field "$n" default)" = "true" ]; then
      state="DECLARED, NOT RENDERED"
      why="run 'plugins.sh render' — PLUGIN-001"
    else
      state="opt-in (default: false)"
      why="$(field "$n" why | tr '\n' ' ' | cut -c1-60)"
    fi
    printf '%-24s %-28s %s\n' "$n" "$state" "$why"
  done
  echo
  echo "'enabled' means this repo declares it on. Whether it is INSTALLED is the"
  echo "harness's record, not this file's: run /plugin to see that."
}

# ---------------------------------------------------------------- check

rc=0
v() { echo "  ! $*"; rc=2; }

cmd_check() {
  no_registry && return 0

  # PLUGIN-002 — the review is the only control there is, so it is the one field that
  # cannot be skipped. A missing `why:` is a plugin nobody can justify keeping.
  local n
  for n in $(names); do
    [ -n "$(field "$n" why)" ] \
      || v "PLUGIN-002 plugins.yaml: '$n' has no why: — a dependency nobody can justify is one nobody can drop either"
    if [ -z "$(yq -r ".plugins[] | select(.name == \"$n\") | .reviewed // \"\"" "$REGISTRY")" ]; then
      v "PLUGIN-002 plugins.yaml: '$n' has no reviewed: block — a plugin executes arbitrary code with your privileges, and the review is the only control there is"
    elif [ -z "$(yq -r ".plugins[] | select(.name == \"$n\") | .reviewed.verdict // \"\"" "$REGISTRY")" ]; then
      v "PLUGIN-002 plugins.yaml: '$n' has a reviewed: block with no verdict: — notes without a conclusion do not tell the next reader whether it was accepted"
    fi
  done

  # PLUGIN-001 — a hand-edit of the generated file wins silently over the reviewed
  # registry. Compare against a fresh render rather than trusting either.
  if [ -f "$SETTINGS" ]; then
    if ! diff -q <(render_settings) "$SETTINGS" >/dev/null 2>&1; then
      v "PLUGIN-001 ${SETTINGS#"$ROOT"/} does not match plugins.yaml — run 'plugins.sh render'. It is generated; a hand-edit is a second source of truth for the default set, and it is the one that wins without being noticed"
    fi
  elif [ -n "$(names)" ]; then
    v "PLUGIN-001 no ${SETTINGS#"$ROOT"/} — plugins.yaml declares plugins that reach nobody until it is rendered"
  fi

  # PLUGIN-003 — the difference between declined-on-purpose and absent-by-accident.
  for n in $(declined_names); do
    [ -n "$(decline_reason "$n")" ] \
      || v "PLUGIN-003 ${OVERLAY#"$ROOT"/}: '$n' is declined with no why: — a session that finds the skill missing cannot tell whether to work around the gap or report a broken machine"
  done

  # PLUGIN-004 — committing one person's declines imposes them on everybody.
  if [ -f "$OVERLAY" ] && "$GIT" -C "$ROOT" ls-files --error-unmatch "${OVERLAY#"$ROOT"/}" >/dev/null 2>&1; then
    v "PLUGIN-004 ${OVERLAY#"$ROOT"/} is tracked by git — it is one machine's answer, and committing it imposes that answer on everyone, which inverts the feature. Add it to .gitignore and 'git rm --cached' it"
  fi

  return "$rc"
}

case "${1:-}" in
  list)   cmd_list ;;
  render) cmd_render ;;
  check)  cmd_check ;;
  *) echo "usage: plugins.sh {list|render|check}" >&2; exit 1 ;;
esac
