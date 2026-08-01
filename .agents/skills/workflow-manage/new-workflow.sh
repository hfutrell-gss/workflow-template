#!/usr/bin/env bash
# workflow-manage — new-workflow: scaffold a workflow.
#
# A workflow (AGENTS.CORE.md, "The shapes") is the TTPs of one nature of work. It is a
# skill with state: canonical body at workflows/<name>/SKILL.md, references/ for depth,
# discovery stub at .claude/skills/<name>/SKILL.md (frontmatter mirrored, body only a
# pointer -- the proxy rule). Its directory later fills with the state the TTPs act on:
# applications, their profiles, their carried work, and sessions, all created by
# orchestrate.sh init.
#
# This is the one scaffolder for that shape -- AGENTS.CORE.md's categorical rule: the
# template owns every operation on a shape it defines; a derivation names workflows,
# never hand-rolls this tooling.
#
# Usage:
#   new-workflow.sh <name>
#
# Refuses: the core-owned `workflow-*` prefix, any name an installed skill already
# holds (core or pack -- both namespaces reach the Skill tool, and a future
# `workflow-template-sync update` would silently clobber the collision), the managed
# workflow names, illegal names, and overwriting either half.
#
# It does NOT hardcode any pack's prefix. Which prefixes are taken is a fact about what
# this repo has installed, and it is read from disk rather than from a list that goes
# stale the moment a pack is added or removed.
#
# Exit codes: 0 success, 1 error (bad usage, reserved name, bad name, already exists).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"

name="${1:-}"
[ -n "$name" ] || { echo "usage: new-workflow.sh <name>" >&2; exit 1; }

case "$name" in
  upstream-workflow-management)
    echo "error: '$name' is a managed workflow -- the template ships it to every" >&2
    echo "       derivation (template-manifest.yaml). Creating a local one would be" >&2
    echo "       overwritten by the next 'workflow-template-sync update'." >&2
    exit 1
    ;;
esac

case "$name" in
  workflow-*)
    echo "error: '$name' uses the reserved 'workflow-*' prefix, which the core owns" >&2
    echo "       (AGENTS.CORE.md, 'Composition'). Machinery skills and workflows both" >&2
    echo "       reach the Skill tool, so the names must not collide, and a collision is" >&2
    echo "       silently overwritten the next time 'workflow-template-sync update' runs." >&2
    exit 1
    ;;
esac

# A pack owns whatever prefix it ships; asking disk beats keeping a list.
if [ -e "$ROOT/.agents/skills/$name" ]; then
  echo "error: '$name' is already an installed skill (.agents/skills/$name) — it came" >&2
  echo "       from the core or from a pack, and a workflow of the same name would" >&2
  echo "       collide with it in the Skill tool. Run 'workflow-template-sync list' to" >&2
  echo "       see what is installed, then pick another name." >&2
  exit 1
fi

case "$name" in
  -*) echo "error: name may not start with a dash: $name" >&2; exit 1 ;;
esac
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "error: name may contain only letters, digits, dot, underscore, dash (no spaces, no path separators): $name" >&2; exit 1; }

canonical_dir="$ROOT/workflows/$name"
stub_dir="$ROOT/.claude/skills/$name"

if [ -e "$canonical_dir" ] || [ -e "$stub_dir" ]; then
  echo "error: a workflow named '$name' already exists (${canonical_dir#"$ROOT"/} or ${stub_dir#"$ROOT"/}) — refusing to overwrite" >&2
  exit 1
fi

mkdir -p "$canonical_dir/references" "$stub_dir"
# references/ starts empty -- detail material is written once the TTPs have content
# worth deferring; .gitkeep only so the directory survives an empty first commit.
touch "$canonical_dir/references/.gitkeep"

cat > "$canonical_dir/SKILL.md" <<EOF
---
name: $name
description: >-
  TODO — one paragraph: what nature of work this workflow covers, AND when to reach for
  it. This description is the entire retrieval surface (loaded every session; the body
  below loads only on invocation) — a vague one means this workflow is never found. List
  the concrete trigger phrases a user or agent would actually say. Shape: "<what it
  covers>. Use when <trigger phrase>, <trigger phrase>, or <trigger phrase>."
---

# $name

TODO — one sentence: the nature of work this workflow covers.

## When to use

TODO — the situations that should make an agent reach for this, in the words someone
would actually use them.

## TTPs

TODO — keep this page thin; the way of working at a glance. Defer detail to
\`references/\`.

1. ...
2. ...

## Applications

Each application this workflow acts on gets a directory beside this file:

- \`<app>/profile.md\` — its operational particulars
- \`<app>/tasks.md\` — carried work: epics and deferred tasks that cross sessions
- \`<app>/<session>/\` — one session, created by \`orchestrate.sh init $name <app>\`

## References

Load a \`references/\` file when you reach the step that needs it.

- \`references/TODO.md\` — TODO
EOF

# Proxy stub: frontmatter copied verbatim from the canonical file (Claude Code
# discovery needs it in both places), body is only the pointer import — same form
# workflow-agents-sync's create_stub_from_canonical produces, reproduced here so
# new-workflow.sh doesn't have to shell out to it.
awk 'BEGIN{c=0} /^---$/{c++; print; if(c==2) exit; next} {print}' "$canonical_dir/SKILL.md" > "$stub_dir/SKILL.md"
{
  echo ""
  echo "@../../../workflows/$name/SKILL.md"
} >> "$stub_dir/SKILL.md"

echo "created:"
echo "  ${canonical_dir#"$ROOT"/}/SKILL.md"
echo "  ${canonical_dir#"$ROOT"/}/references/  (.gitkeep)"
echo "  ${stub_dir#"$ROOT"/}/SKILL.md"
echo
echo
echo "next: fill in the TODOs, then start a session:"
echo "  .agents/skills/workflow-orchestrate/orchestrate.sh init $name <app>"
