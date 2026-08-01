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
.agents/skills/workflow-template-sync/template-sync.sh derive [--upstream PATH]
.agents/skills/workflow-template-sync/template-sync.sh update
.agents/skills/workflow-template-sync/template-sync.sh --check
```

## Modes

### `derive` — turn a template copy into a derivation
Run this **inside a fresh copy or clone of workflow-template** — nothing else. It:
1. Refuses if `.template.lock` already exists (already derived) or `VERSION` is
   missing (doesn't look like a template checkout).
2. Clears template-only identity: example content out of `journal/`, any INSTANCE run state
   under `workflows/<workflow>/<target>/` (a bare `workflows/<workflow>/` with no target
   subdirs is the DURABLE procedure and survives), and any legacy run state under
   `.workflow/`. That matters because both are **committed** (unlike `workspace/`), so a
   derive-by-clone would otherwise carry the template's own in-flight runs and notes into the
   new workflow. A run belongs to the repo that performed it.
3. Removes the root `VERSION` file — that describes the *template's* own version;
   a derivation's relationship to it lives entirely in `.template.lock` instead.
4. Writes `.template.lock`: `template_version`, `upstream`, `derived` (today's date),
   `pinned: false`. `upstream` is resolved by precedence: `--upstream PATH` >
   `$WORKFLOW_TEMPLATE_UPSTREAM` env var > this checkout's own `origin` remote URL
   (`git -C <dir> remote get-url origin`), if one exists > hardcoded fallback
   `~/workbench/workflow-template`. The `origin`-remote step is what makes `derive`
   correct when run inside a fresh `git clone` of the published template — the
   canonical create path — instead of silently writing the local hardcoded path; a
   plain `cp -r` copy has no `.git/origin` and falls through to the next step exactly
   as before. When the `origin` remote is what's chosen, `derive` echoes it so the
   inference is visible rather than silent.
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
  its procedure skills, `journal/`, anything else — is never touched, by construction (the
  copy step only ever reads paths named in the manifest).
- `upstream` may be a **local path or a git URL** (`https://`, `git@...`, `ssh://`,
  `file://`). A URL upstream is fetched into a cached shallow clone (see "Remote
  upstreams" below); everything downstream of that — reading `VERSION`, reading
  `template-manifest.yaml`, copying the managed set — works identically to a local
  path, against the cache checkout.
- VERSION is a plain integer; comparison uses `sort -n`.

**Known caveat — structural moves in the managed set leave orphans.** `copy_managed_paths`
only ever *adds/overwrites* the exact paths named in the **upstream's current**
manifest; it never diffs against the paths named in an *older* manifest, so it can't
know a path was retired. When a template version moves content rather than just
editing it in place (e.g. v8's skills-under-`.agents` refactor, which retired the old
`.claude/skills/<name>/**` directory entries in favor of `.agents/skills/<name>/**` +
single-file `.claude/skills/<name>/SKILL.md` stubs), `update` copies the new paths in
correctly but leaves the old files that are no longer in the manifest sitting on disk
untouched — e.g. the pre-v8 `.claude/skills/<name>/*.sh` scripts survive as orphaned
duplicates alongside the new canonical copies under `.agents/skills/`. **After any
`update` that crosses a structural move like this, check the release notes for the
new version and manually remove anything the old manifest managed that the new one
doesn't** — `workflow-agents-sync`'s skill-stub check (`DRIFT ... non-stub file under
.claude/skills`) will flag exactly this case for the skills package specifically, but
the general problem (arbitrary managed-path renames) has no automated cleanup yet.
Filed as a real limitation, not fixed as of v8 — a future version could add a
"retired paths" list to `template-manifest.yaml` that `update` deletes explicitly.

### Remote upstreams
A URL `upstream` is resolved through a cache checkout at
`${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync/<sha1 of the url>`:
- **No cache yet** → `git clone --depth 1 <url> <cache>`.
- **Cache exists** → `git fetch --depth 1 origin`, then hard-reset to the remote's
  default branch (resolved via `origin/HEAD`, set with `git remote set-head origin -a`
  if that symref isn't there yet).
- **Fetch/clone fails and a cache already exists** → a loud `WARNING` to stderr, then
  `update`/`--check` proceed against the **stale cache**, noting its last-refresh time.
  Offline runs against a previously-synced remote upstream keep working this way.
- **Fetch/clone fails and no cache exists** → a clear error, nonzero exit. Never a
  half-update.

All git operations use `/usr/bin/git` explicitly (see `AGENTS.CORE.md`'s git
discipline).

### Repointing upstream
Edit `upstream:` in `.template.lock` by hand — that is the supported repoint
procedure, whether moving to a different local path or switching to a URL (or back).
No re-derive needed.

### `--check` — report drift
Prints `template_version`, `upstream`, the upstream's current version, and `pinned`.
Exits 1 if behind (regardless of pinned — pinned just means `update` won't act on it).

## The covenant
This skill is the only thing in a derivation allowed to touch the managed set listed in
`template-manifest.yaml`, and it only ever adds/overwrites those exact paths — never
anything else. See `AGENTS.CORE.md` ("Template link") for the full doctrine.
