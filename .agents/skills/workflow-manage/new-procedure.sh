#!/usr/bin/env bash
# workflow-manage — new-procedure: scaffold a derivation-local procedure skill.
#
# A procedure (AGENTS.CORE.md, "The shapes") is a reusable way of working — it lives as
# a derivation-local skill: canonical body at .agents/skills/<name>/SKILL.md, proxy stub
# at .claude/skills/<name>/SKILL.md (frontmatter mirrored, body only a pointer — the
# proxy rule), plus references/ for detail. This is the one scaffolder for that shape —
# AGENTS.CORE.md's categorical rule: the template owns every operation on a shape it
# defines; a derivation names procedures, never hand-rolls this tooling.
#
# Usage:
#   new-procedure.sh <name>
#
# Refuses: reserved workflow-*/craft-* prefixes (template-owned; a future
# `workflow-template-sync update` may silently clobber a derivation-local skill using
# them), illegal names (mirrors orchestrate.sh's own workflow/target name validation,
# for consistency), and overwriting an existing skill (either half).
#
# Exit codes: 0 success, 1 error (bad usage, reserved prefix, bad name, already exists).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"

name="${1:-}"
[ -n "$name" ] || { echo "usage: new-procedure.sh <name>" >&2; exit 1; }

case "$name" in
  workflow-*|craft-*)
    echo "error: '$name' uses a reserved template prefix (workflow-* or craft-*)." >&2
    echo "       Those namespaces are template-owned (AGENTS.CORE.md, 'Template link, the" >&2
    echo "       categorical rule, and the covenant') — a derivation-local skill named" >&2
    echo "       like this may be silently overwritten the next time" >&2
    echo "       'workflow-template-sync update' runs. Pick a name outside both prefixes." >&2
    exit 1
    ;;
esac

case "$name" in
  -*) echo "error: name may not start with a dash: $name" >&2; exit 1 ;;
esac
[[ "$name" =~ ^[A-Za-z0-9._-]+$ ]] || { echo "error: name may contain only letters, digits, dot, underscore, dash (no spaces, no path separators): $name" >&2; exit 1; }

canonical_dir="$ROOT/.agents/skills/$name"
stub_dir="$ROOT/.claude/skills/$name"

if [ -e "$canonical_dir" ] || [ -e "$stub_dir" ]; then
  echo "error: a skill named '$name' already exists (${canonical_dir#"$ROOT"/} or ${stub_dir#"$ROOT"/}) — refusing to overwrite" >&2
  exit 1
fi

mkdir -p "$canonical_dir/references" "$stub_dir"
# references/ starts empty — a procedure's detail material is written once the
# procedure itself has content worth deferring; .gitkeep only so the directory (part
# of the shape every procedure gets) survives an empty first commit.
touch "$canonical_dir/references/.gitkeep"

cat > "$canonical_dir/SKILL.md" <<EOF
---
name: $name
description: >-
  TODO — one paragraph: what this procedure does, AND when to reach for it. This
  description is the entire retrieval surface (loaded every session; the body below
  loads only on invocation) — a vague one means this procedure is never found. List the
  concrete trigger phrases a user or agent would actually say. Shape: "<what it does>.
  Use when <trigger phrase>, <trigger phrase>, or <trigger phrase>."
---

# $name

TODO — one-sentence statement of the reusable way of working this procedure captures.

## When to use

TODO — the situations that should make an agent reach for this, in the words someone
would actually use them.

## Steps

TODO — keep this page thin; the procedure at a glance. Defer detail to \`references/\`.

1. ...
2. ...

## References

Load a \`references/\` file when you reach the step that needs it.

- \`references/TODO.md\` — TODO
EOF

# Proxy stub: frontmatter copied verbatim from the canonical file (Claude Code
# discovery needs it in both places), body is only the pointer import — same form
# workflow-agents-sync's create_stub_from_canonical produces, reproduced here so
# new-procedure.sh doesn't have to shell out to it.
awk 'BEGIN{c=0} /^---$/{c++; print; if(c==2) exit; next} {print}' "$canonical_dir/SKILL.md" > "$stub_dir/SKILL.md"
{
  echo ""
  echo "@../../../.agents/skills/$name/SKILL.md"
} >> "$stub_dir/SKILL.md"

echo "created:"
echo "  ${canonical_dir#"$ROOT"/}/SKILL.md"
echo "  ${canonical_dir#"$ROOT"/}/references/  (.gitkeep)"
echo "  ${stub_dir#"$ROOT"/}/SKILL.md"
echo
echo "next: fill in the TODOs, then run /workflow-agents-sync --check"
