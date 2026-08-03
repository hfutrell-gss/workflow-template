---
name: workflow-template-sync
description: >-
  Composition for a workflow repo. A repo is assembled from PACKS: one core (this
  template — the shapes, tracked in .template.lock) plus any number of optional packs
  (declared in packs.yaml, each with its own pack.yaml). `derive` turns a fresh
  copy/clone of the core into a workflow repo. `add`/`remove` install and uninstall a
  pack. `update` pulls the core and every pack forward. `list` shows what is installed.
  `--check` reports versions. `--audit` checks composition integrity offline. Use when
  asked to derive a new workflow repo, to add or drop a pack, to sync a repo's managed
  paths, to check whether anything is behind, or to pin/unpin.
---

# workflow-template-sync

## Run
```sh
S=.agents/skills/workflow-template-sync/template-sync.sh
$S derive [--upstream PATH]      # in a fresh copy/clone of the core
$S add <url-or-path> [--name N] [--reviewed]   # install a pack
$S scan <url-or-path-or-name>    # what would it install, and does it look wrong
$S remove <pack>                 # uninstall a pack and delete its paths
$S update [<pack>]               # pull the core and every pack forward
$S list                          # what is installed, from where, what version
$S --audit                       # composition integrity (PACK-*); offline
$S --check                       # versions; exit 1 if anything unpinned is behind
```

## The model

| | Core | Pack |
|---|---|---|
| Manifest | `template-manifest.yaml` (`managed:`) | `pack.yaml` (`provides:`) |
| Version | root `VERSION` file | `version:` in `pack.yaml` |
| Declared in the repo | `.template.lock` | `packs.yaml` |
| Installed state | (its manifest, on disk) | `packs.lock` — version + exact paths |
| Count | exactly one, never removable | any number, each removable |

Three invariants, all enforced by the script:

1. **One owner per path.** A path claimed by two packs is refused **before any write**.
2. **A dropped path is removed.** A path a pack stops providing is deleted on the next
   update, and now-empty parent directories are pruned.
3. **No inter-pack dependencies.** No resolver, no ordering, no version solving.

## Modes

### `derive` — turn a core copy into a workflow repo
Run this **inside a fresh copy or clone of the core** — nothing else. It:
1. Refuses if `.template.lock` already exists (already derived) or `VERSION` is missing
   (doesn't look like a core checkout).
2. Clears core-only identity: the core's own ADRs out of `docs/adrs/` (the managed
   `0000-adr-template.md` survives, and the index is reset to an empty table), every application
   directory under `workflows/<workflow>/` (profiles, carried work, sessions — the
   workflow's own `SKILL.md` and `references/` survive, being TIMELESS), and any legacy
   run state under `.workflow/`. All of it is **committed** (unlike `workspace/`), so a
   derive-by-clone would otherwise carry the core's own applications and in-flight
   sessions into the new repo. A session belongs to the repo that performed it.
3. Scaffolds `GLOSSARY.local.md` if absent and the `code-craft` pack's asset is present —
   unmanaged, never overwritten (`GLOSSARY.md` holds the system's terms).
4. Removes the root `VERSION` file — that describes the *core's* own version; a
   derivation's relationship to it lives entirely in `.template.lock`.
5. Writes `.template.lock`: `template_version`, `upstream`, `derived`, `pinned: false`.
   `upstream` resolves by precedence: `--upstream PATH` > `$WORKFLOW_TEMPLATE_UPSTREAM`
   > this checkout's own `origin` remote URL > hardcoded `~/workbench/workflow-template`.
   The `origin` step is what makes `derive` correct inside a fresh `git clone` of the
   published core; a `cp -r` copy has no `.git/origin` and falls through. When `origin`
   is chosen, `derive` echoes it, so the inference is visible rather than silent.
6. Leaves `AGENTS.md` as the skeleton — write this workflow's doctrine into it next.

Asks nothing interactively.

### `add` — install a pack
```sh
$S add git@host:org/pack-code-craft
$S add ../pack-code-craft --name code-craft
$S add <url> --reviewed          # proceed despite scan findings you have read
```
Order of refusal, all before any write:
1. no `pack.yaml` at the root, a name already declared, or the reserved core name.
2. **`requires_core:` unmet** — the pack states the minimum core it was written against.
3. **`scan` findings** — waived only by `--reviewed`.
4. **path collision** with the core or another pack — never waivable; two owners for one
   path is broken whoever reviewed it.

On success: appends to `packs.yaml` (created if absent), copies the `provides:` paths in,
records version + paths in `packs.lock`.

### `scan` — read a pack before trusting it
Takes a URL, a path, or the name of an already-declared pack. Two passes:

- **Shape.** A pack may claim exactly four things: `.agents/skills/<name>/**`,
  `.claude/skills/<name>/SKILL.md`, `workflows/<name>/SKILL.md`,
  `workflows/<name>/references/**`. Anything else is a finding, with the reason —
  `workflows/<name>/<app>/**` is the repo's record of its own work; `.claude/settings*`,
  hooks and `.mcp.json` execute without anyone invoking them; root law is always loaded;
  an overlay slot is the repo's answer to the pack, so a pack must not write its own.
- **Content**, over the claimed files only: credential reads, egress, pipe-to-shell,
  destructive writes outside the repo, obfuscation. Every executable file is listed.

**It is a heuristic, not a security boundary.** It catches carelessness and the obvious.
It will not catch a competent attacker, and nothing this size could. The real control is
social: install packs you wrote, or packs whose maintainer you would already trust with a
commit bit on this repo.

### `remove` — uninstall a pack
Deletes exactly the paths `packs.lock` records for that pack, prunes emptied parent
directories, and drops it from both `packs.yaml` and `packs.lock`. The core cannot be
removed — eject instead, by deleting `.template.lock`.

**Overlays survive.** `.agents/<pack-name>/` holds this repo's answers to that pack, not
the pack's property, so nothing deletes them. `remove` says so rather than leaving a
directory whose reason for existing has quietly gone.

### `update` — pull everything forward
With no argument: the core, then every declared pack. With a pack name (or
`workflow-core`): just that one.

- **`pinned: true`** (core: in `.template.lock`; pack: in its `packs.yaml` entry) →
  reports the available version, touches nothing.
- Otherwise, when upstream is ahead: **removes** paths the manifest no longer claims,
  then copies the current manifest's paths in. Directory entries (`.../**`) are replaced
  wholesale, so deletions inside them propagate too.
- Everything outside every manifest — `AGENTS.md`, `binds.yaml`, this repo's own
  workflows, its own ADRs, the overlay slots — is never touched, by construction: the copy
  step only ever reads paths a manifest names.
- A pack present in `packs.lock` but absent from `packs.yaml` prints a WARNING. `update`
  never deletes files for an undeclared pack; run `remove` deliberately.
- Versions are plain integers for the core (`sort -n`); packs compare for equality.

**How removal knows what to remove.** For a pack, `packs.lock` holds the exact installed
path list. For the core, the derivation's own copy of `template-manifest.yaml` is that
record — it is itself a managed path, so the pre-update copy on disk states what the core
previously owned.

### The stale-script constraint

**An update is run by the derivation's own copy of this script.** So the logic that
decides what an update DOES is the logic of the release *before* the one being applied. A
change to update semantics would otherwise reach a repo one release late — governing the
manifest after the one it was written for.

`update` closes that gap itself: when the core is behind and not pinned, it **stages the
upstream's `.agents/skills/workflow-template-sync/` over this repo's copy and re-execs
it** before doing anything else. Staging rewrites only that directory — never
`template-manifest.yaml` — so the old manifest is still on disk when the new script reads
it, and the dropped-path diff computes correctly. It happens once per run
(`WORKFLOW_TEMPLATE_SYNC_RESTAGED` guards the re-exec), only after the pinned /
up-to-date / upstream-behind gates, and only if the upstream copy differs and parses.

**What it cannot reach: a derivation whose installed script predates the staging step.**
That script stages nothing, so its first update still runs old logic. The case that costs
real work is a core older than **v30**, where `update_core` gained dropped-path removal
(`comm -23` against the old manifest, then `remove_paths`). Before v30 the script only
copies what the NEW manifest lists. Every path the new manifest retired is left orphaned
on disk, `.template.lock` is stamped with the new version, every later `update` reports
"up to date", and the old manifest — the only record of what the core used to own — has
been overwritten. Nothing reports any of it.

**Stage by hand before the first update of any pre-v30 derivation**, while its manifest is
still the old one:

```sh
cp -r <upstream>/.agents/skills/workflow-template-sync/. \
      <derivation>/.agents/skills/workflow-template-sync/
bash <derivation>/.agents/skills/workflow-template-sync/template-sync.sh update
```

Correct order matters: copy the skill, do **not** touch `template-manifest.yaml`, then
run `update`. Each retired path then prints as `removed <path>`. No `removed` line where
the release retired a path means the stage did not take.

Read `.template.lock`'s `template_version` before deciding — v30 and later needs nothing.

### Remote upstreams
A URL upstream (core or pack) resolves through a cache checkout at
`${XDG_CACHE_HOME:-$HOME/.cache}/workflow-template-sync/<sha1 of the url>`:
- **No cache yet** → `git clone --depth 1 <url> <cache>`.
- **Cache exists** → `git fetch --depth 1 origin`, then hard-reset to the remote's
  default branch (via `origin/HEAD`, set with `git remote set-head origin -a` if absent).
- **Fetch/clone fails, cache exists** → loud `WARNING` to stderr, proceed against the
  **stale cache**, noting its last-refresh time. Offline runs keep working.
- **Fetch/clone fails, no cache** → clear error, nonzero exit. Never a half-update.

All git operations use `/usr/bin/git` explicitly.

### Repointing an upstream
Edit `upstream:` in `.template.lock` (core) or in the pack's `packs.yaml` entry. Local
path or URL, either direction. No re-derive needed.

A **relative** local path resolves against the repo root, not the caller's working
directory — so `upstream: workspace/pack-code-craft` means the same thing from anywhere. Note
that `workspace/` is gitignored and per-machine: a pack referenced there works on this
machine only. Publish the pack and repoint at its URL before the repo travels.

### `--audit` — composition integrity
Checks the composition itself, and reports `PACK-001` … `PACK-005`:

| | |
|---|---|
| `PACK-001` | one owner per path — no path claimed by the core and a pack, or by two packs |
| `PACK-002` | every path a pack's `packs.lock` entry claims is present on disk |
| `PACK-003` | `packs.yaml` and `packs.lock` agree — nothing installed undeclared, nothing declared uninstalled |
| `PACK-004` | every installed pack's `requires_core:` is still satisfied by this repo's core |
| `PACK-005` | every installed pack has its overlay directory `.agents/<pack-name>/` |

**Offline.** It reads `.template.lock`, `packs.yaml`, `packs.lock`, and the disk. No
upstream is contacted, so it is cheap and works with no network. Findings print as
`DRIFT`/`MISSING` lines and it always exits 0 — an unmet constraint is a result, not a
tool failure. This is the mode `/workflow-check` runs, and the only path that reports the
`PACK-*` family. Statements and rationale live in the registry:
`.agents/skills/workflow-check/references/constraints.md`.

### `--check` — report drift
One line per pack: installed vs available. Exit 1 if anything is behind — a constraint
result (`TEMPLATE-*`), consumed by `/workflow-check`. Contacts every upstream.

**A pinned thing is not a violation.** A `pinned: true` core or pack that is behind
reports `PINNED` with both versions and does not count toward the failing exit: pinning
freezes updates without ejecting, so the drift is the decision working. The fact stays on
stdout — visible, not red.

## Authoring a pack

A pack is an ordinary repo with `pack.yaml` at its root:

```yaml
name: code-craft
version: 1
requires_core: 30          # optional; the minimum core this pack was written against
provides:
  - .agents/skills/code-craft-tdd/**
  - .claude/skills/code-craft-tdd/SKILL.md
```

A pack may ship **skills or workflows** — the TTPs of a nature of work generalize as
readily as a test protocol does.

Rules that keep a pack composable:
- **Claim only the four allowed shapes.** `scan` enforces it; see above for each reason.
- **Read overlay slots; never write them.** A configurable pack reads an unmanaged
  `.agents/<pack-name>/*.local.*` and lets the repo's copy win. Claiming that path takes
  away the repo's only override, and is refused.
- **State `requires_core:`** if you rely on anything the core added. Checked at `add`, at
  `update`, and again as `PACK-004` — a core pinned or rolled back afterwards breaks the
  assumption silently otherwise.
- **Bump `version:` on every change.** It is the only signal an installed repo has.
- **Never depend on another pack.** Degrade instead: keep the duty, lose the guidance.

## The covenant
This skill is the only thing allowed to touch a managed path. It adds, overwrites, and
removes exactly the paths a manifest names, and nothing else — see `AGENTS.CORE.md`
("Composition") for the doctrine.
