---
name: workflow-template-sync
description: >-
  The upstream link between workflow-template and a derived workflow repo. `derive`
  turns a fresh copy/clone of the template into a derivation (writes .template.lock).
  `update` pulls forward changes to the managed set (AGENTS.CORE.md, CLAUDE.md,
  template-manifest.yaml, the workflow-* skills) from upstream, unless pinned.
  `--check` reports current vs upstream template version. Use when asked to derive a
  new workflow from the template, to sync/update a derivation's managed core, to check
  whether a derivation is behind upstream, or to pin/unpin a derivation.
---

# workflow-template-sync

## Run
```sh
.claude/skills/workflow-template-sync/template-sync.sh derive [--upstream PATH]
.claude/skills/workflow-template-sync/template-sync.sh update
.claude/skills/workflow-template-sync/template-sync.sh --check
```

## Modes

### `derive` — turn a template copy into a derivation
Run this **inside a fresh copy or clone of workflow-template** — nothing else. It:
1. Refuses if `.template.lock` already exists (already derived) or `VERSION` is
   missing (doesn't look like a template checkout).
2. Clears any template-only example content out of `journal/` and `playbooks/`.
3. Removes the root `VERSION` file — that describes the *template's* own version;
   a derivation's relationship to it lives entirely in `.template.lock` instead.
4. Writes `.template.lock`: `template_version`, `upstream` (path — defaults to
   `$WORKFLOW_TEMPLATE_UPSTREAM` or `~/workbench/workflow-template`, override with
   `--upstream`), `derived` (today's date), `pinned: false`.
5. Leaves `AGENTS.md` exactly as the template's carveout skeleton — write this
   workflow's actual doctrine into it next; that's the one thing derive never touches.

Asks nothing interactively — safe to run non-interactively right after a copy/clone.

### `update` — pull the managed set forward from upstream
Run inside a derivation. Reads `.template.lock`:
- **`pinned: true`** → reports the upstream version available and exits without
  touching anything. Flip to `pinned: false` to allow updates again.
- **`pinned: false`** → compares `template_version` to upstream's `VERSION`. If
  upstream is ahead, copies **only** the paths listed in the upstream's
  `template-manifest.yaml` into this repo (directory entries are replaced wholesale,
  so upstream deletions propagate), then bumps `template_version` in `.template.lock`.
  Everything outside the managed set — this workflow's `AGENTS.md`, `binds.yaml`,
  `playbooks/`, `journal/`, anything else — is never touched, by construction (the
  copy step only ever reads paths named in the manifest).
- Currently supports a **local path** upstream only (no remote fetch yet).
- VERSION is a plain integer; comparison uses `sort -n`.

### Repointing upstream
`upstream` is a local path today. If the template repo moves (or gains a URL later),
edit `upstream:` in `.template.lock` by hand — that is the supported repoint procedure.

### `--check` — report drift
Prints `template_version`, `upstream`, the upstream's current version, and `pinned`.
Exits 1 if behind (regardless of pinned — pinned just means `update` won't act on it).

## The covenant
This skill is the only thing in a derivation allowed to touch the managed set listed in
`template-manifest.yaml`, and it only ever adds/overwrites those exact paths — never
anything else. See `AGENTS.CORE.md` ("Template link") for the full doctrine.
