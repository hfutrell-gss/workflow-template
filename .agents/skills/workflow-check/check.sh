#!/usr/bin/env bash
# workflow-check -- run every organizational constraint this repo declares, in one pass.
#
# It OWNS NOTHING. Each skill owns the constraints for the shapes it defines (the
# categorical rule); this dispatches to them and returns one verdict. A constraint
# implemented here instead of in its owner is the fragmentation this exists to end.
#
# Owners and their rule prefixes -- the registry is references/constraints.md:
#   TOOL-*     workflow-init        per-machine tooling and init.lock
#   AGENTS-*   workflow-agents-sync canonical file format, bridges, stubs, glossary slot
#   LAYOUT-*   workflow-orchestrate workflow/application/session directory shape
#   TASK-*     workflow-orchestrate task grammar and anti-cheat inside each session
#              (an OPEN session is not a violation -- work in progress is normal)
#   TEMPLATE-* workflow-template-sync  the core/pack version drift against upstream
#   PACK-*     workflow-template-sync  composition integrity: one owner per path,
#              installed == declared, claimed paths present (offline; no upstream)
#   PLUGIN-*   workflow-plugins     the plugin registry: the default set matches
#              plugins.yaml, every plugin is reviewed, every decline names its reason
#
# Usage:
#   check.sh            report; exit 0 all clear, 2 violations found, 1 error
#   check.sh --fix      same, but let owners that can repair safely do so
#
# Exit 2 is an ordinary state, not a failure: it means a constraint is unmet and is
# reported. Only a broken tool exits 1.
set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
S="$ROOT/.agents/skills"
MODE="${1:-}"
[ "$MODE" = "--fix" ] || [ -z "$MODE" ] || { echo "usage: check.sh [--fix]" >&2; exit 1; }

rc=0
report_block() {                         # report_block <label> <status> <output>
  local label="$1" status="$2" out="$3"
  case "$status" in
    0) printf '%-10s ok\n' "$label" ;;
    2) printf '%-10s VIOLATIONS\n' "$label"; printf '%s\n' "$out" | sed 's/^/           /'; rc=2 ;;
    *) printf '%-10s ERROR (exit %d)\n' "$label" "$status"
       printf '%s\n' "$out" | sed 's/^/           /'
       [ "$rc" = 0 ] && rc=1 ;;
  esac
}

run_exit_coded() {                       # owner already returns 0/2 correctly
  local label="$1"; shift
  local out status
  out="$("$@" 2>&1)"; status=$?
  report_block "$label" "$status" "$out"
}

run_stdout_coded() {                     # owner reports on stdout and exits 0
  local label="$1"; shift
  local out status
  out="$("$@" 2>&1)"; status=$?
  if [ "$status" -ne 0 ]; then report_block "$label" "$status" "$out"; return; fi
  if printf '%s\n' "$out" | grep -qE '^(DRIFT|MISSING|NOTE|WARN)'; then
    report_block "$label" 2 "$(printf '%s\n' "$out" | grep -E '^(DRIFT|MISSING|NOTE|WARN)')"
  else
    report_block "$label" 0 ""
  fi
}

run_nonzero_is_violation() {             # owner exits 1 to mean "not conforming"
  local label="$1"; shift                # -- a constraint result, not a tool defect
  local out status
  out="$("$@" 2>&1)"; status=$?
  [ "$status" -eq 1 ] && status=2
  report_block "$label" "$status" "$out"
}

echo "workflow-check — organizational constraints (registry: .agents/skills/workflow-check/references/constraints.md)"
echo

# init.sh --check exits 0 conforming / 1 not -- its 1 is a constraint result.
[ -f "$S/workflow-init/init.sh" ] && run_nonzero_is_violation "TOOL" bash "$S/workflow-init/init.sh" --check
# agents-sync exits 0 conforming / 1 drift -- its 1 is a constraint result, not a defect.
run_nonzero_is_violation "AGENTS" bash "$S/workflow-agents-sync/agents-sync.sh" ${MODE:+"$MODE"}
run_exit_coded   "LAYOUT" bash "$S/workflow-orchestrate/orchestrate.sh" check
# --audit is offline (composition integrity); --check contacts each upstream and exits 1
# when something is behind -- a constraint result, not a tool defect.
if [ -f "$ROOT/.template.lock" ]; then
  run_stdout_coded        "PACK"     bash "$S/workflow-template-sync/template-sync.sh" --audit
  run_nonzero_is_violation "TEMPLATE" bash "$S/workflow-template-sync/template-sync.sh" --check
fi
# A repo with no plugins.yaml declares no plugins, which is a complete state -- the
# owner returns 0 silently, so this needs no guard of its own.
[ -f "$S/workflow-plugins/plugins.sh" ] && run_exit_coded "PLUGIN" bash "$S/workflow-plugins/plugins.sh" check

echo
case "$rc" in
  0) echo "all constraints met" ;;
  2) echo "constraints unmet — see above; each line names the rule it broke" ;;
  *) echo "a checker failed to run; that is a tool defect, not a constraint result" ;;
esac
exit "$rc"
