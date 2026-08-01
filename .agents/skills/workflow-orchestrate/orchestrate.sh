#!/usr/bin/env bash
# workflow-orchestrate — run mechanics.
#
# Four levels, never mixed (AGENTS.CORE.md "The shapes"):
#   workflows/<workflow>/SKILL.md              TIMELESS — the TTPs. Never pruned.
#   workflows/<workflow>/<app>/profile.md      DURABLE  — that application's particulars.
#   workflows/<workflow>/<app>/tasks.md        CARRIED  — epics, deferred work, and the
#                                                         ledger of sessions closed.
#                                                         Crosses sessions. Never a
#                                                         session list.
#   workflows/<workflow>/<app>/<session>/tasks.md  SESSION — one run. Deleted after harvest.
#
# A session tasks.md (grammar + anti-cheat rules: references/tasklist.md) is the durable
# state of that session for as long as it is open. This script only scaffolds and
# reports; it never marks a task done, because recording completion requires judgment
# about evidence and a script that mutates markers invites marking work done without any.
#
# Unfinished work never blocks a session forever. Promote it: mark the task [^] with a
# carried: line naming its entry in <app>/tasks.md. [^] is not open, so the session can
# reach exhaustion with the work preserved rather than abandoned or stalled.
#
# Legacy fallback: a session still at .workflow/<slug>/tasklist.md keeps resolving for
# one version — see references/tasklist.md "Legacy layout". `init` only writes the
# current layout.
#
# BEGIN-USAGE
# Usage:
#   orchestrate.sh init <workflow> <app> <slug>
#                                             scaffold workflows/<workflow>/<app>/<date>-<slug>/
#                                             <slug> says what the session is FOR; the date is
#                                             added for you. A bare date is refused.
#   orchestrate.sh status [<key>]             counts, violations, harvest, DoD verdict
#   orchestrate.sh ready  [<key>]             tasks whose deps are all done
#   orchestrate.sh list                       every session with its verdict
#   orchestrate.sh check                      LAYOUT constraints (see references/constraints.md)
#   orchestrate.sh close [<key>]              append the session's line to the application
#                                             ledger (<app>/tasks.md "## History"), then
#                                             delete the session directory. Refuses unless
#                                             DoD is met. One operation, so the ledger
#                                             entry and the deletion cannot come apart.
#
# <key> is <workflow>/<app>/<session>, or a bare slug for a session still at the legacy
# .workflow/<slug>/ path. Omit it to resolve the only session present, or the only one
# still open.
#
# Exit codes (status/ready/list): 0 = exhausted, clean, and harvested; 2 = NOT done (an
# ordinary state, not a failure); 1 = usage or IO error.
# END-USAGE
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
WORKFLOWS="$ROOT/workflows"
WF="$ROOT/.workflow"          # legacy layout — fallback only, see header
ASSETS="$HERE/assets"

die() { echo "error: $*" >&2; exit 1; }
note_legacy() { echo "NOTE: legacy session at .workflow/$1/ — migrate to workflows/<workflow>/<app>/<session>/ (this fallback is scheduled for removal in a future version)" >&2; }

usage() {
  sed -n '/^# BEGIN-USAGE/,/^# END-USAGE/p' "${BASH_SOURCE[0]}" | sed '1d;$d;s/^# \{0,1\}//'
  exit "${1:-1}"
}

# collect_sessions — populate SESS_KEY[]/SESS_PATH[]/SESS_LEGACY[] with every session
# found under both layouts. Current layout first, legacy second; order only matters for
# list's display order.
#
# <app>/tasks.md is CARRIED work, not a session, and is never collected here. Only
# <app>/<session>/tasks.md is a session. Treating carried work as a session would let a
# never-ending list of epics block every DoD verdict in the repo.
collect_sessions() {
  SESS_KEY=(); SESS_PATH=(); SESS_LEGACY=()
  local wdir adir sdir d key
  if [ -d "$WORKFLOWS" ]; then
    for wdir in "$WORKFLOWS"/*/; do
      [ -d "$wdir" ] || continue
      for adir in "$wdir"*/; do
        [ -d "$adir" ] || continue
        for sdir in "$adir"*/; do
          [ -f "$sdir/tasks.md" ] || continue
          key="$(basename "$wdir")/$(basename "$adir")/$(basename "$sdir")"
          SESS_KEY+=("$key"); SESS_PATH+=("$sdir/tasks.md"); SESS_LEGACY+=(0)
        done
      done
    done
  fi
  if [ -d "$WF" ]; then
    for d in "$WF"/*/; do
      [ -f "$d/tasklist.md" ] || continue
      key="$(basename "$d")"
      SESS_KEY+=("$key"); SESS_PATH+=("$d/tasklist.md"); SESS_LEGACY+=(1)
    done
  fi
}

# resolve_session <key> — sets RESOLVED_KEY / RESOLVED_PATH. Explicit key, else the
# only run present, else the only run that is not exhausted. Ambiguity is an error,
# never a guess. Emits a NOTE (not a suppression) whenever the resolved run is legacy.
resolve_session() {
  local want="${1:-}" i
  collect_sessions
  local n="${#SESS_KEY[@]}"
  if [ -n "$want" ]; then
    for i in "${!SESS_KEY[@]}"; do
      if [ "${SESS_KEY[$i]}" = "$want" ]; then
        RESOLVED_KEY="${SESS_KEY[$i]}"; RESOLVED_PATH="${SESS_PATH[$i]}"
        if [ "${SESS_LEGACY[$i]}" = "1" ]; then note_legacy "$RESOLVED_KEY"; fi
        return 0
      fi
    done
    die "no such session: $want (want <workflow>/<app>/<session>, or a legacy slug under .workflow/)"
  fi
  if [ "$n" -eq 0 ]; then die "no sessions under workflows/ or .workflow/ — run: orchestrate.sh init <workflow> <app> <slug>"; fi
  if [ "$n" -eq 1 ]; then
    RESOLVED_KEY="${SESS_KEY[0]}"; RESOLVED_PATH="${SESS_PATH[0]}"
    if [ "${SESS_LEGACY[0]}" = "1" ]; then note_legacy "$RESOLVED_KEY"; fi
    return 0
  fi
  local -a open_idx=()
  for i in "${!SESS_KEY[@]}"; do
    report "${SESS_PATH[$i]}" status >/dev/null 2>&1 || open_idx+=("$i")
  done
  if [ "${#open_idx[@]}" -eq 1 ]; then
    i="${open_idx[0]}"
    RESOLVED_KEY="${SESS_KEY[$i]}"; RESOLVED_PATH="${SESS_PATH[$i]}"
    if [ "${SESS_LEGACY[$i]}" = "1" ]; then note_legacy "$RESOLVED_KEY"; fi
    return 0
  fi
  if [ "${#open_idx[@]}" -eq 0 ]; then
    die "all sessions exhausted; name one: ${SESS_KEY[*]}"
  else
    die "${#open_idx[@]} open sessions; name one: ${SESS_KEY[*]}"
  fi
}

# report <tasks.md> <status|ready>  — the whole parser/validator.
report() {
  awk -v mode="$2" '
    function has(id, key) { return ((id SUBSEP key) in field) }
    function bad(msg)     { viol[++nv] = msg }

    /^## Directive/        { in_dir = 1; in_tasks = 0; in_harv = 0; next }
    /^## Tasks/            { in_tasks = 1; in_dir = 0; in_harv = 0; next }
    /^## Harvest/          { in_harv = 1; in_tasks = 0; in_dir = 0; next }
    /^## /                 { in_tasks = 0; in_dir = 0; in_harv = 0 }
    { if (/<!--/) gc = 1 }                                  # HTML comments are never content
    gc                     { if (/-->/) gc = 0; next }
    in_dir                 { if ($0 !~ /^[ \t]*$/) ndir++; next }
    in_harv {
      if ($0 ~ /^harvest:/) {
        v = $0; sub(/^harvest:[ \t]*/, "", v); gsub(/[ \t]+$/, "", v)
        if (v != "") harvest_val = v
      }
      next
    }
    !in_tasks {
      # A task line filed outside ## Tasks would be silently ignored — and silently
      # ignored work is how a list reaches exhaustion without doing it.
      if (/^- \[.\] /) bad("task line outside the ## Tasks section: " $0)
      next
    }

    /^- \[.\] / {
      marker = substr($0, 4, 1)
      n = split(substr($0, 7), f, / *· */)
      id = f[1]
      # A rejected line must also orphan its continuation fields — otherwise they are
      # credited to the previous task, hiding the missing fields of that task.
      if (n < 4 || id !~ /^T[0-9]+$/ || f[3] !~ /^deps:/) { bad("malformed task line: " $0); last = ""; next }
      if (id in mark) { bad(id ": duplicate id"); last = ""; next }
      t = f[4]; for (i = 5; i <= n; i++) t = t " · " f[i]   # a title may contain the separator
      order[++nt] = id
      mark[id]  = marker
      tier[id]  = f[2]
      deps[id]  = substr(f[3], 6)
      title[id] = t
      last = id
      if (marker !~ /^[ ~x!^-]$/)                         bad(id ": unknown marker [" marker "]")
      if (f[2] != "flagship" && f[2] != "workhorse" && f[2] != "fleet") bad(id ": invalid tier \"" f[2] "\" (flagship|workhorse|fleet)")
      if (f[4] == "")                                     bad(id ": empty title")
      count[marker]++
      next
    }
    /^[ \t]+[a-z]+:/ && last != "" {
      k = $1; sub(/:$/, "", k); sub(/:.*$/, "", k)
      v = $0; sub(/^[ \t]+[a-z]+:[ \t]*/, "", v)
      if (v != "") field[last, k] = 1
      next
    }

    END {
      # Vacuous exhaustion: an empty list, or one whose directive was never captured,
      # is NOT done — it is unstarted.
      if (nt == 0)   bad("no tasks — decompose the directive first")
      if (ndir == 0) bad("## Directive is empty — capture the directive verbatim")

      # Harvest gate: a run is not done until its durable output has left the run
      # directory. Absent section/field defaults to "pending" — so a run written before
      # this gate existed (or one that forgot it) is reported honestly, not silently
      # grandfathered in. "done" alone (no destination) is a violation, always: this is
      # the anti-cheat rule for the harvest gate and it must be checkable the same way
      # every other marker is.
      if (harvest_val == "") harvest_val = "pending"
      harvested = (harvest_val ~ /^done[ \t]+[^ \t]/)
      if (harvest_val != "pending" && !harvested)
        bad("harvest: \"" harvest_val "\" is not \"pending\" or \"done <where it went>\"")

      for (i = 1; i <= nt; i++) {
        id = order[i]; m = mark[id]
        if (!has(id, "accept"))                  bad(id ": missing accept: (every task needs its acceptance test)")
        if (m == "x" && !has(id, "evidence"))    bad(id ": [x] without evidence:")
        if (m == "~" && !has(id, "agent"))       bad(id ": [~] without agent:")
        if (m == "!" && !has(id, "blocked"))     bad(id ": [!] without blocked:")
        if (m == "-" && !has(id, "why"))         bad(id ": [-] without why:")
        if (m == "-" && !has(id, "signoff"))     bad(id ": [-] without signoff: (dropping a task needs user sign-off)")
        if (m == "^" && !has(id, "carried"))     bad(id ": [^] without carried: (name its entry in <app>/tasks.md — promoting work is not the same as dropping it)")
        rem[id] = 1
        if (deps[id] == "-" || deps[id] == "") continue
        # A dead-end dependency only matters for a task that still intends to run. A
        # task that is itself carried or dropped travels with its dependency; flagging
        # that pair would force an operator to sever links that are correct.
        stillopen = (m == " " || m == "~" || m == "!")
        nd = split(deps[id], d, ",")
        for (j = 1; j <= nd; j++) {
          if (d[j] == id)          bad(id ": depends on itself")
          else if (!(d[j] in mark)) bad(id ": depends on unknown " d[j])
          else if (!stillopen) continue
          else if (mark[d[j]] == "-") bad(id ": depends on dropped " d[j] " — re-plan or drop it too")
          else if (mark[d[j]] == "^") bad(id ": depends on carried " d[j] " — carry this one too, or it can never start")
        }
      }
      # Harvest completeness. A decision to NOT do work is a fact about the application,
      # and it is the fact most likely to be lost: de-scoping five tasks with a sign-off
      # tells the next reader why a "gap" is not a gap, and it dies with this directory
      # unless something names where it went. Checked only once harvest says done --
      # requiring it mid-run would be noise on work still in flight.
      # "landed: disposable — <reason>" is a legitimate answer. Silence is not.
      if (harvested)
        for (i = 1; i <= nt; i++) {
          id = order[i]; m = mark[id]
          if (m != "-" && m != "^") continue
          if (!has(id, "landed"))
            bad(id ": [" m "] without landed: — at harvest, a dropped or carried decision must name where its rationale went (a stewarded repo\047s own docs, <app>/profile.md, or \047disposable — <reason>\047)")
        }

      # Kahn: unknown deps count as satisfied (already reported), so what is left is a cycle.
      do {
        moved = 0
        for (i = 1; i <= nt; i++) {
          id = order[i]
          if (!(id in rem)) continue
          ok = 1
          if (deps[id] != "-" && deps[id] != "") {
            nd = split(deps[id], d, ",")
            for (j = 1; j <= nd; j++) if (d[j] in rem && d[j] != id) ok = 0
          }
          if (ok) { delete rem[id]; moved = 1 }
        }
      } while (moved)
      for (id in rem) bad(id ": dependency cycle")

      for (i = 1; i <= nt; i++) {
        id = order[i]
        if (mark[id] != " ") continue
        ok = 1
        if (deps[id] != "-" && deps[id] != "") {
          nd = split(deps[id], d, ",")
          for (j = 1; j <= nd; j++) if (mark[d[j]] != "x") ok = 0
        }
        if (ok) ready[++nr] = id
      }

      open = count[" "] + count["~"] + count["!"]
      exhausted = (open == 0 && nv == 0)
      if (mode == "ready") {
        for (i = 1; i <= nr; i++) printf "%s · %s · %s\n", ready[i], tier[ready[i]], title[ready[i]]
        if (nr == 0) printf "(none ready: %d pending, %d in flight, %d blocked)\n", count[" "], count["~"], count["!"]
      } else {
        printf "tasks       %d\n", nt
        printf "  pending   %d\n  in flight %d\n  done      %d\n  blocked   %d\n  carried   %d\n  dropped   %d\n", \
               count[" "], count["~"], count["x"], count["!"], count["^"], count["-"]
        printf "harvest     %s\n", harvest_val
        if (nr > 0) { printf "ready      "; for (i = 1; i <= nr; i++) printf "%s%s", ready[i], (i < nr ? " " : "\n") }
        if (nv > 0) { print  "violations " nv; for (i = 1; i <= nv; i++) print "  ! " viol[i] }
        if (exhausted && harvested)       print "DoD: EXHAUSTED"
        else if (exhausted && !harvested) print "DoD: NOT EXHAUSTED (harvest pending)"
        else if (nv > 0)                  printf "DoD: NOT EXHAUSTED (%d open, %d violation%s)\n", open, nv, (nv == 1 ? "" : "s")
        else                               printf "DoD: NOT EXHAUSTED (%d open)\n", open
      }
      exit (exhausted && harvested) ? 0 : 2
    }
  ' "$1"
}

cmd_init() {
  local workflow="${1:-}" app="${2:-}" slug="${3:-}" session today
  [ -n "$workflow" ] && [ -n "$app" ] && [ -n "$slug" ] \
    || die "usage: orchestrate.sh init <workflow> <app> <slug>
  <slug> names what the session is FOR, in two or three words: glossary, delayed-policies,
  auth-rewrite. The date is added for you. A bare date is refused -- \"2026-08-01\" tells
  the next reader nothing, and two sessions in one day would collide."
  today="$(date +%F)"
  # A slug that already carries its own date (a migrated session) is taken as-is.
  case "$slug" in
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) die "\"$slug\" is a bare date, not a name. Say what the session is for: init $workflow $app <slug>" ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*) session="$slug" ;;
    *) session="$today-$slug" ;;
  esac
  local seg
  for seg in "$workflow" "$app" "$session"; do
    [[ "$seg" =~ ^[A-Za-z0-9._-]+$ ]] || die "names may contain only letters, digits, dot, underscore, dash: $seg"
  done
  local wdir="$WORKFLOWS/$workflow" adir="$WORKFLOWS/$workflow/$app" dir="$WORKFLOWS/$workflow/$app/$session"
  [ -e "$dir/tasks.md" ] && die "session already exists: workflows/$workflow/$app/$session/tasks.md"
  [ -e "$wdir/SKILL.md" ] || echo "NOTE: workflows/$workflow/SKILL.md does not exist — this workflow has no TTPs written yet. Scaffold one with: /workflow-manage new-workflow $workflow" >&2
  mkdir -p "$wdir" "$adir" "$dir/notes"
  local f
  for f in tasks roster; do
    sed -e "s/__WORKFLOW__/$workflow/g" -e "s/__APP__/$app/g" -e "s/__SESSION__/$session/g" -e "s/__DATE__/$today/g" \
      "$ASSETS/$f.template.md" > "$dir/$f.md"
  done
  : > "$dir/notes/.gitkeep"
  # Carried work and the application profile are DURABLE. Created once, never
  # overwritten by a later session -- clobbering them is how cross-session work is lost.
  for f in carried:tasks profile:profile; do
    local src="${f%%:*}" dst="${f##*:}"
    if [ ! -e "$adir/$dst.md" ]; then
      sed -e "s/__WORKFLOW__/$workflow/g" -e "s/__APP__/$app/g" -e "s/__DATE__/$today/g" \
        "$ASSETS/$src.template.md" > "$adir/$dst.md"
      echo "created workflows/$workflow/$app/$dst.md"
    fi
  done
  echo "created workflows/$workflow/$app/$session/{tasks.md,roster.md,notes/}"
  echo "next: paste the directive verbatim, resolve the roster, then decompose."
}

# cmd_check -- LAYOUT constraints. Rule IDs are stable and citable; see
# references/constraints.md. This owns the shapes orchestrate defines (workflow,
# application, session) and nothing else -- other tools own theirs.
cmd_check() {
  local nv=0 wdir adir sdir wf app sess
  v() { echo "  ! $1"; nv=$((nv+1)); }

  if [ -d "$ROOT/.workflow" ]; then
    v "LAYOUT-001 .workflow/ still exists — sessions live at workflows/<workflow>/<app>/<session>/"
  fi

  [ -d "$WORKFLOWS" ] || { echo "layout     no workflows/ directory"; return 0; }

  for wdir in "$WORKFLOWS"/*/; do
    [ -d "$wdir" ] || continue
    wf="$(basename "$wdir")"
    [ -f "$wdir/SKILL.md" ] \
      || v "LAYOUT-002 workflows/$wf/ has no SKILL.md — a workflow with no TTPs is a directory, not a workflow"
    [ -f "$ROOT/.claude/skills/$wf/SKILL.md" ] \
      || v "LAYOUT-003 workflows/$wf/ has no .claude/skills/$wf/ stub — unreachable by the Skill tool, so it will never be found at the moment of need"

    for adir in "$wdir"*/; do
      [ -d "$adir" ] || continue
      app="$(basename "$adir")"
      [ "$app" = "references" ] && continue
      [ "$app" = "assets" ] && continue
      if [ -f "$adir/tasks.md" ]; then
        # Both sections must exist BEFORE they are needed. `close` appends History if it
        # is missing, but Open has no such writer: a session that ends with carried work
        # and no place to put it loses it silently, which is the failure this level exists
        # to prevent.
        grep -q '^## Open' "$adir/tasks.md" \
          || v "LAYOUT-008 workflows/$wf/$app/tasks.md has no '## Open' section — carried work promoted out of a closing session has nowhere to land"
        grep -q '^## History' "$adir/tasks.md" \
          || v "LAYOUT-008 workflows/$wf/$app/tasks.md has no '## History' section — the record that a session ran against this application has nowhere to land (orchestrate.sh close writes it)"
      else
        v "LAYOUT-004 workflows/$wf/$app/ has no tasks.md — carried work has nowhere to land when a session closes"
      fi
      [ -f "$adir/profile.md" ] \
        || v "LAYOUT-005 workflows/$wf/$app/ has no profile.md — this application's operational picture is unrecorded"

      for sdir in "$adir"*/; do
        [ -d "$sdir" ] || continue
        sess="$(basename "$sdir")"
        [ -f "$sdir/tasks.md" ] || continue
        case "$sess" in
          [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-?*) ;;
          *) v "LAYOUT-006 session $wf/$app/$sess is not named <date>-<slug>" ;;
        esac
        # The harvest law: a session that is exhausted AND harvested must be deleted, not
        # left on disk. Nothing checked this, and the template itself violated it for ten
        # versions.
        if report "$sdir/tasks.md" status >/dev/null 2>&1; then
          v "LAYOUT-007 session $wf/$app/$sess is exhausted and harvested but still on disk — delete it; git log is the archive"
        fi
      done
    done
  done

  # TASK-* -- grammar and anti-cheat violations inside each open session. An OPEN session
  # is not a violation; work in progress is the normal state. Only a malformed or
  # self-contradicting list is.
  local i out
  collect_sessions
  for i in "${!SESS_KEY[@]}"; do
    # report exits 2 for a session that is merely open, and pipefail would propagate
    # that into the assignment and trip set -e -- aborting the whole check silently.
    out="$( { report "${SESS_PATH[$i]}" status 2>/dev/null || true; } | sed -n 's/^  ! //p' )"
    [ -n "$out" ] || continue
    while IFS= read -r line; do
      [ -n "$line" ] && v "TASK-001 ${SESS_KEY[$i]}: $line"
    done <<< "$out"
  done

  if [ "$nv" -eq 0 ]; then echo "layout     all conforming"; return 0; fi
  echo "layout     $nv violation$([ "$nv" -eq 1 ] || echo s)"
  return 2
}

# close — the only supported way a session ends.
#
# Deletion used to be a manual `git rm`, and the record of the run went with it: harvest
# names WHERE output landed but nothing recorded THAT the session ran, against what, or
# with what result. So the answer to "what has been done to this app?" was `git log` and
# nothing else -- retained, but not readable by anyone who did not already know to look.
#
# The ledger fixes that at the APPLICATION level, which is where a reader stands. One
# line per session, permanent, next to the carried work it produced. Dispatch mechanics
# still do not survive -- tier, agent, ordering, the dependency graph are how the work was
# organized, not a fact about the application (AGENTS.CORE.md "Harvest law").
#
# Ledger and deletion are one command precisely because they were two steps before, and
# the second one is the step nobody forgets.
cmd_close() {
  resolve_session "${1:-}"
  # RESOLVED_PATH is the task FILE (collect_sessions), so the session directory is its
  # parent and the application directory is the grandparent.
  local path="$RESOLVED_KEY" tasks="$RESOLVED_PATH"
  local dir app_dir ledger
  dir="$(dirname "$tasks")"
  app_dir="$(dirname "$dir")"

  # DoD first: exhausted, harvested, no violations. report exits 2 when not done.
  local out
  if ! out="$(report "$tasks" status 2>&1)"; then
    echo "$out"
    die "refusing to close $path — it is not done. Fix what is reported above, or promote the remainder with [^]."
  fi

  # A legacy .workflow/<slug>/ session has no application level, so it has nowhere to
  # write a ledger line. Migrate it rather than closing it into a void.
  [ "$app_dir" = "$WF" ] && die "cannot close a legacy session at .workflow/$path — it has no application level, so the ledger line has nowhere to go. Move it to workflows/<workflow>/<app>/<session>/ first."

  ledger="$app_dir/tasks.md"
  [ -f "$ledger" ] || die "no application ledger at ${ledger#"$ROOT"/} — every application has a tasks.md (LAYOUT-004)"

  # One line, built from the list itself so it cannot flatter the run.
  local done_n drop_n carry_n block_n directive harvest_line
  done_n="$(grep -cE '^- \[x\] ' "$tasks" || true)"
  drop_n="$(grep -cE '^- \[-\] ' "$tasks" || true)"
  carry_n="$(grep -cE '^- \[\^\] ' "$tasks" || true)"
  block_n="$(grep -cE '^- \[!\] ' "$tasks" || true)"
  directive="$(awk '/^## Directive/{f=1;next} /^## /{f=0} f && NF && $0 !~ /^<!--/ {print; exit}' "$tasks" | cut -c1-140)"
  harvest_line="$(awk '/^harvest:/{sub(/^harvest:[ \t]*done[ \t]*(—|--)?[ \t]*/,""); print; exit}' "$tasks" | cut -c1-160)"

  grep -q '^## History' "$ledger" || printf '\n## History\n\nOne line per session closed against this application, appended by `orchestrate.sh\nclose`. Permanent: the session directory is deleted, and this is what remains of it\nbesides `git log`. Do not hand-write entries here — a line nobody earned by passing\nthe DoD gate is a claim, not a record.\n' >> "$ledger"

  printf -- '\n- **%s** — %s\n  %s done · %s dropped · %s carried · %s blocked. Harvest: %s\n' \
    "$(basename "$dir")" "${directive:-<no directive captured>}" \
    "$done_n" "$drop_n" "$carry_n" "$block_n" "${harvest_line:-<unrecorded>}" >> "$ledger"

  echo "ledger: appended $(basename "$dir") to ${ledger#"$ROOT"/}"

  if [ -d "$ROOT/.git" ] && /usr/bin/git -C "$ROOT" ls-files --error-unmatch "$dir" >/dev/null 2>&1; then
    /usr/bin/git -C "$ROOT" rm -rq "$dir"
  else
    rm -rf "$dir"
  fi
  echo "closed: $path — session directory deleted. git log is the archive."
  echo "next:   commit the ledger line and the deletion together."
}

cmd_list() {
  collect_sessions
  [ "${#SESS_KEY[@]}" -eq 0 ] && die "no sessions under workflows/ or .workflow/ — run: orchestrate.sh init <workflow> <app> <slug>"
  local rc=0 i verdict
  for i in "${!SESS_KEY[@]}"; do
    verdict="$(report "${SESS_PATH[$i]}" status | grep '^DoD:' || true)"
    report "${SESS_PATH[$i]}" status >/dev/null 2>&1 || rc=2
    [ "${SESS_LEGACY[$i]}" = "1" ] && note_legacy "${SESS_KEY[$i]}"
    printf '%-52s %s\n' "${SESS_KEY[$i]}" "${verdict:-DoD: unparseable}"
  done
  return "$rc"
}

case "${1:-}" in
  init)          shift; cmd_init "${1:-}" "${2:-}" "${3:-}" ;;
  status|ready)  mode="$1"; shift; resolve_session "${1:-}"
                 echo "session: $RESOLVED_KEY"; report "$RESOLVED_PATH" "$mode" ;;
  list)          cmd_list ;;
  check)         cmd_check ;;
  close)         shift; cmd_close "${1:-}" ;;
  -h|--help|help) usage 0 ;;
  *)             usage 1 ;;
esac
