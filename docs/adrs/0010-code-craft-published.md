# ADR-0010: The first pack, published

**Status:** Accepted
**Date:** 2026-08-01
**Authors:** henning
**Deciders:** henning

**Scope (repos affected):**

- `workflow-template` — the core itself
- every derivation — receives this through the managed set

---

`pack-code-craft` is live at `git@github.com:henningfutrell/pack-code-craft` (branch
`main`). It is the first thing to prove the pack mechanism end to end: authored outside
the core, installed by URL, updated and removed by the same machinery that manages the
core.

## The rename, and why the name mattered

`craft` said nothing about what it was craft **of**. Renamed all the way down:

| Was | Now |
|---|---|
| `pack-craft` | `pack-code-craft` |
| pack `craft` | pack `code-craft` |
| `craft-tdd` | `code-craft-tdd` |
| `craft-code-quality` | `code-craft-quality` |
| `craft-event-naming` | `code-craft-event-naming` |
| `craft-ubiquitous-language` | `code-craft-ubiquitous-language` |
| `.agents/craft/<skill>.local.md` | `.agents/code-craft/<skill>.local.md` |

`code-craft-code-quality` stutters, so that one dropped the doubled word. Done now
because a name is cheapest to change before anything depends on it, and the pack had
existed for under an hour.

## What the rename exposed: the core knew a pack's prefix

`new-workflow.sh` refused `workflow-*|craft-*`. After the rename that list was simply
wrong — and it would have been wrong again the first time anyone installed a pack the
core had never heard of. A hardcoded prefix list is the core knowing something only the
composition knows.

Replaced with the fact instead of the list:

- **`workflow-*` stays reserved.** The core owns it, so the core may assert it.
- **Everything else is read from disk.** `.agents/skills/<name>` exists → refuse. That
  covers every pack, installed or not yet imagined, and it self-corrects on
  `add`/`remove`.

The general rule, worth applying to the next thing that reaches for a list: **the core
may hardcode only what the core owns.** Anything about what is installed is a question
for `packs.lock` and the filesystem.

Same edit in prose: `README.md` and `AGENTS.md` no longer name two reserved prefixes.
One is reserved; the rest belong to whatever is installed.

## Publishing details worth keeping

- `gh` is authenticated as `henningfutrell`; the `github-gss` SSH alias authenticates as
  a **different** account, `hfutrell-gss`, which owns `workflow-template`. `gh repo
  create` under that account fails and the failure does not say why. The pack was
  published under the `gh` account instead, at the user's direction.
- `gh repo create --push` pushed `master`. Renamed to `main`, repointed the repo's
  default branch through the API, deleted `master`. Worth doing at creation: every other
  repo here is `main`, and a `pack.yaml` upstream resolves through `origin/HEAD`.

## Action items

None. The core is at v32, the pack at v1 with a remote, and this repo's derivation
converges next.

## Correction — 2026-08-01, under T004

Two claims above are wrong on this machine. Verified under T004; full evidence at
`workflows/upstream-workflow-management/derivations/2026-08-01-v37-adoption/notes/T004-pack.md`.
Original text above is left as written.

- **Clone URL.** `git@github.com:henningfutrell/pack-code-craft` fails here:
  `ssh -T git@github.com` → `Permission denied (publickey)`. The repo is **private**.
  The only form that clones it from this machine is
  `ssh://github-personal/henningfutrell/pack-code-craft.git` — SSH alias
  `github-personal`, key `id_github-personal`, account `henningfutrell`. Verified by
  direct clone: `EXIT=0`.
- **scp-style form is not tooling-safe.** `github-personal:henningfutrell/pack-code-craft.git`
  clones fine by hand, but `is_url_upstream` in
  `.agents/skills/workflow-template-sync/template-sync.sh:72-77` matches only
  `https:// http:// git@ ssh:// file://` — the scp form matches none of them and would
  be misread as a local path by `template-sync.sh add`/`update`. Use the `ssh://` form
  for anything `packs.yaml` or tooling reads.
- **`gh` account.** Not `henningfutrell`. `gh auth status` reports account
  `hfutrell-gss`. That account also owns `workflow-template` and, separately, the
  `github-gss` SSH alias authenticates as `hfutrell-gss` too — and gets "Repository not
  found" against `pack-code-craft` (it has no access; the repo is private).
- **Consequence.** Any other machine or CI running `update` against this pack needs the
  `github-personal` key provisioned, or the pack silently stops updating.
