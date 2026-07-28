---
name: workflow-manage
description: >-
  Administer this workflow: add, remove, or edit standing binds in binds.yaml (kind +
  why), clone a standing bind's repo if it's absent from disk, or review the bind
  registry. Use when asked to register a related repo, change why/how a repo relates to
  this workflow, mark a bind as default, or list what this workflow stands next to.
---

# workflow-manage

Standing binds (`binds.yaml`) are a **registry**, not a session state — see
`AGENTS.CORE.md` ("Bind law"). This skill is instructions for editing that registry with
`yq`; there's no separate CLI. `/workflow-bind` is the companion skill that actually
attaches repos to a session.

## Review binds
```sh
yq -r '.standing[] | .repo + "  [" + .kind + "]  default=" + (.default // false | tostring) + "  — " + .why' binds.yaml
```

## Add a standing bind
1. Pick a `kind`: `reference` (material this workflow reads), `co-change` (tends to
   change alongside this workflow's work), `stewarded` (this workflow is accountable
   for it), `upstream` / `downstream` (dependency direction).
2. Write a one-sentence `why` — the relationship, not a repo description.
3. Append with `yq`, then re-sort by `repo` so the list stays scannable:
   ```sh
   yq -i '.standing += [{"repo": "NAME", "kind": "KIND", "why": "WHY", "default": false}]' binds.yaml
   yq -i '.standing |= sort_by(.repo)' binds.yaml
   ```
   Add `"url"` / `"branch"` keys too if the repo should be clone-if-absent capable.
4. If this repo should be attached automatically by `/workflow-bind`, set
   `"default": true` instead of `false` above (or edit it after the fact — see below).

## Edit an existing bind
```sh
yq -i '(.standing[] | select(.repo == "NAME") | .why) = "NEW WHY"' binds.yaml
yq -i '(.standing[] | select(.repo == "NAME") | .default) = true' binds.yaml
```

## Remove a standing bind
```sh
yq -i 'del(.standing[] | select(.repo == "NAME"))' binds.yaml
```
Removing a standing bind is a registry change only — it does not delete anything on
disk, and does not affect any repo already session-bound right now.

## Clone-if-absent
```sh
.claude/skills/workflow-manage/clone-if-absent.sh <repo-name>
```
No-ops if the repo is already present under `base` (never touches an existing
checkout); otherwise clones it using the bind's `url`/`branch`. Errors clearly if the
bind has no `url` — add one first, or clone it manually.

## After any edit
Run `/workflow-agents-sync --check` — it scans every standing bind present on disk for
a conforming `AGENTS.md`/`CLAUDE.md` bridge.
