#!/usr/bin/env bash
# workflow-orchestrate — session task-list mechanics.
#
# The task list at .workflow/<session-slug>/tasklist.md is the durable state of an
# orchestration run (grammar + anti-cheat rules: references/tasklist.md). This script
# only scaffolds and reports; it never marks a task done, because recording completion
# requires judgment about evidence and a script that mutates markers invites marking
# work done without any.
#
# Usage:
#   orchestrate.sh init <name>        scaffold .workflow/<YYYY-MM-DD-name>/
#   orchestrate.sh status [<slug>]    counts, violations, ready set, DoD verdict
#   orchestrate.sh ready  [<slug>]    tasks whose deps are all done
#   orchestrate.sh list               every session with its verdict
#
# Exit codes (status/ready/list): 0 = exhausted and clean, 2 = NOT exhausted (an
# ordinary state, not a failure), 1 = usage or IO error.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
WF="$ROOT/.workflow"
ASSETS="$HERE/assets"

die() { echo "error: $*" >&2; exit 1; }

usage() {
  sed -n '10,17p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

# Resolve a session slug: explicit argument, else the only session present, else the
# only session that is not exhausted. Ambiguity is an error, never a guess.
resolve_slug() {
  local want="${1:-}"
  [ -n "$want" ] && { [ -f "$WF/$want/tasklist.md" ] || die "no such session: $want"; echo "$want"; return; }
  [ -d "$WF" ] || die "no .workflow/ yet — run: orchestrate.sh init <name>"
  local all=() open=() d slug
  for d in "$WF"/*/; do
    [ -f "$d/tasklist.md" ] || continue
    slug="$(basename "$d")"
    all+=("$slug")
    report "$d/tasklist.md" status >/dev/null 2>&1 || open+=("$slug")
  done
  [ "${#all[@]}" -eq 0 ] && die "no sessions under .workflow/ — run: orchestrate.sh init <name>"
  [ "${#all[@]}" -eq 1 ] && { echo "${all[0]}"; return; }
  [ "${#open[@]}" -eq 1 ] && { echo "${open[0]}"; return; }
  die "$( [ "${#open[@]}" -eq 0 ] && echo "all sessions exhausted" || echo "${#open[@]} open sessions" ); name one: ${all[*]}"
}

# report <tasklist.md> <status|ready>  — the whole parser/validator.
report() {
  awk -v mode="$2" '
    function has(id, key) { return ((id SUBSEP key) in field) }
    function bad(msg)     { viol[++nv] = msg }

    /^## Directive/        { in_dir = 1; in_tasks = 0; next }
    /^## Tasks/            { in_tasks = 1; in_dir = 0; next }
    /^## /                 { in_tasks = 0; in_dir = 0 }
    { if (/<!--/) gc = 1 }                                  # HTML comments are never content
    gc                     { if (/-->/) gc = 0; next }
    in_dir                 { if ($0 !~ /^[ \t]*$/) ndir++; next }
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
      if (marker !~ /^[ ~x!-]$/)                          bad(id ": unknown marker [" marker "]")
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
      for (i = 1; i <= nt; i++) {
        id = order[i]; m = mark[id]
        if (!has(id, "accept"))                  bad(id ": missing accept: (every task needs its acceptance test)")
        if (m == "x" && !has(id, "evidence"))    bad(id ": [x] without evidence:")
        if (m == "~" && !has(id, "agent"))       bad(id ": [~] without agent:")
        if (m == "!" && !has(id, "blocked"))     bad(id ": [!] without blocked:")
        if (m == "-" && !has(id, "why"))         bad(id ": [-] without why:")
        if (m == "-" && !has(id, "signoff"))     bad(id ": [-] without signoff: (dropping a task needs user sign-off)")
        rem[id] = 1
        if (deps[id] == "-" || deps[id] == "") continue
        nd = split(deps[id], d, ",")
        for (j = 1; j <= nd; j++) {
          if (d[j] == id)          bad(id ": depends on itself")
          else if (!(d[j] in mark)) bad(id ": depends on unknown " d[j])
          else if (mark[d[j]] == "-") bad(id ": depends on dropped " d[j] " — re-plan or drop it too")
        }
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
      if (mode == "ready") {
        for (i = 1; i <= nr; i++) printf "%s · %s · %s\n", ready[i], tier[ready[i]], title[ready[i]]
        if (nr == 0) printf "(none ready: %d pending, %d in flight, %d blocked)\n", count[" "], count["~"], count["!"]
      } else {
        printf "tasks       %d\n", nt
        printf "  pending   %d\n  in flight %d\n  done      %d\n  blocked   %d\n  dropped   %d\n", \
               count[" "], count["~"], count["x"], count["!"], count["-"]
        if (nr > 0) { printf "ready      "; for (i = 1; i <= nr; i++) printf "%s%s", ready[i], (i < nr ? " " : "\n") }
        if (nv > 0) { print  "violations " nv; for (i = 1; i <= nv; i++) print "  ! " viol[i] }
        if (open == 0 && nv == 0)  print "DoD: EXHAUSTED"
        else if (nv > 0)           printf "DoD: NOT EXHAUSTED (%d open, %d violation%s)\n", open, nv, (nv == 1 ? "" : "s")
        else                       printf "DoD: NOT EXHAUSTED (%d open)\n", open
      }
      exit (open == 0 && nv == 0) ? 0 : 2
    }
  ' "$1"
}

cmd_init() {
  local name="${1:-}" slug today
  [ -n "$name" ] || die "usage: orchestrate.sh init <name>"
  [[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || die "name may contain only letters, digits, dot, underscore, dash: $name"
  today="$(date +%F)"
  if [[ "$name" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}- ]]; then slug="$name"; else slug="$today-$name"; fi
  local dir="$WF/$slug"
  [ -e "$dir/tasklist.md" ] && die "session already exists: .workflow/$slug/tasklist.md"
  mkdir -p "$dir/notes"
  local f
  for f in tasklist roster; do
    sed -e "s/__SLUG__/$slug/g" -e "s/__DATE__/$today/g" "$ASSETS/$f.template.md" > "$dir/$f.md"
  done
  : > "$dir/notes/.gitkeep"
  echo "created .workflow/$slug/{tasklist.md,roster.md,notes/}"
  echo "next: paste the directive verbatim, resolve the roster, then decompose."
}

cmd_list() {
  [ -d "$WF" ] || die "no .workflow/ yet — run: orchestrate.sh init <name>"
  local rc=0 d slug verdict
  for d in "$WF"/*/; do
    [ -f "$d/tasklist.md" ] || continue
    slug="$(basename "$d")"
    verdict="$(report "$d/tasklist.md" status | grep '^DoD:' || true)"
    report "$d/tasklist.md" status >/dev/null 2>&1 || rc=2
    printf '%-32s %s\n' "$slug" "${verdict:-DoD: unparseable}"
  done
  return "$rc"
}

case "${1:-}" in
  init)          shift; cmd_init "${1:-}" ;;
  status|ready)  mode="$1"; shift; slug="$(resolve_slug "${1:-}")"
                 echo "session: $slug"; report "$WF/$slug/tasklist.md" "$mode" ;;
  list)          cmd_list ;;
  -h|--help|help) usage 0 ;;
  *)             usage 1 ;;
esac
