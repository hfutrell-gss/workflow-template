---
name: workflow-manage
description: >-
  Administer this workflow: add, remove, or edit standing binds in binds.yaml (kind +
  why), assemble or refresh the substrate those binds describe (clone missing repos,
  fast-forward clean ones — sync-binds.sh), or review the bind registry. Use when asked
  to register a related repo, change why/how a repo relates to this workflow, mark a
  bind as default, sync/refresh standing-bind repos on disk, or list what this workflow
  stands next to.
---

# workflow-manage

This skill owns two managed shapes — see AGENTS.CORE.md's categorical rule: the
template defines a shape, so the template owns every operation on it; a derivation
contributes only its data and its judgment about it, never hand-rolled tooling.

1. **Standing binds** (`binds.yaml`) — a **registry**, not a session state (see
   `AGENTS.CORE.md`, "Bind law"). Editing it is `yq`; assembling the substrate it
   describes onto disk is `sync-binds.sh`. `/workflow-bind` is the companion skill that
   actually attaches repos to a session.
2. **Workflows** — the TTPs of one nature of work (`AGENTS.CORE.md`, "The shapes"),
   which live as a skill with state. Scaffolding one correctly means knowing the proxy
   rule, the reserved `workflow-*`/`craft-*` machinery prefixes, and the managed
   workflow names; `new-workflow.sh` is the one tool for it.

## Scaffold a workflow
```sh
.agents/skills/workflow-manage/new-workflow.sh <name>
```
Creates the canonical body (`workflows/<name>/SKILL.md`, TODO-scaffolded — a
frontmatter `description` prompting for concrete trigger phrases, since that
description is the whole retrieval surface, plus a thin body pointing at
`references/`), the discovery stub (`.claude/skills/<name>/SKILL.md`, frontmatter
mirrored, body only the pointer import — the proxy rule), and an empty `references/`
dir. Applications, their profiles, their carried work, and sessions arrive later, from
`orchestrate.sh init <name> <app>`.
Refuses: a `workflow-*`/`craft-*` name (those prefixes are template-owned; a
derivation-local skill so named risks being clobbered by a future
`workflow-template-sync update`), an illegal name, or overwriting an existing skill.
Exit 0 on success, 1 on any refusal. Run `/workflow-agents-sync --check` afterward, same
as after any bind edit.

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
   Add `"url"` / `"branch"` keys too if the repo should be `sync-binds.sh` capable.
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

## The workspace, in full

Every workflow owns `workspace/` at its root (see AGENTS.CORE.md "The workspace" for
the one-paragraph summary) — a per-machine working area, **gitignored** so nested
substrate clones never appear in the workflow's own `git status`. `binds.yaml`'s `base`
key controls where standing binds actually land on disk; it defaults to `./workspace`
and is always resolved **relative to the repo root**, never to the current working
directory, so `sync-binds.sh` behaves identically regardless of where it's invoked
from. `sync-binds.sh` (below) is what actually populates `base` — a workflow manages
its own repos here: pull, organize, and branch inside `workspace/<repo>`, never on
checkouts it doesn't own, including the user's own personal working copies elsewhere on
disk. Inside `workspace/<repo>`, that repo's own git and its own law (`AGENTS.md`)
apply — the workspace only changes *where* the clone lives, not what governs working in
it (see "Cross-repo changes" below).

## Sync binds (substrate assembly)
```sh
.agents/skills/workflow-manage/sync-binds.sh                # every standing bind with a url
.agents/skills/workflow-manage/sync-binds.sh <repo> [...]   # only the named ones
```
This is the one tool for bringing every standing bind with a `url` onto disk under
`base` and keeping it current — clone-if-absent and ongoing refresh are the same
operation, not two. `sync-binds.sh` populates `base`; a workflow never resolves
standing binds into the user's personal checkouts. For each targeted bind:
- **Missing on disk** → clones it (`--branch` if `binds.yaml` sets one, else the
  remote's default branch).
- **Present, clean, on the tracked branch** → fetches and fast-forwards.
- **Present but dirty, on a different branch, or diverged from origin** → fetches (so
  the report is current) and is reported **skipped**, never forced. This tool never
  clobbers local work — that's the whole safety case for letting it run unattended.
- **Clone or fetch failure** → reported **failed**.

Ends with a summary line — `N ok, M skipped, K failed` — and exits nonzero iff
`failed > 0`. An empty or example-only `binds.yaml` (no `standing:` entries, or none
with a `url` — the template's own schema example) is a clean no-op: `no standing binds
with a url in binds.yaml — nothing to sync`.

Override the binds file for testing with `BINDS_FILE=/path/to/binds.yaml`.

### When to run it
- Before starting work that touches a standing bind, to make sure it's present and
  current.
- Routinely, as part of drift watch (a good pairing with `/workflow-agents-sync`).
- After registering a new standing bind with a `url` (below), to actually bring it
  onto disk rather than leaving the registry entry aspirational.

### Reading the report
- `cloning` / `up to date` — healthy, no action needed.
- `~ dirty working tree — fetch only` — someone's in-flight work; leave it. Note it in
  the journal only if it's been dirty a long time (that's drift, not activity).
- `~ on <X> (binds.yaml tracks <Y>)` — expected for active feature work; only worth
  flagging if it's stale.
- `~ diverged — resolve manually` — always surface to the repo's owner and journal it.
  Never force a resolution.
- `! clone/fetch failed` — auth or registry rot; fix the cause (credentials, a stale
  URL), not the symptom.

## After any edit
Run `/workflow-agents-sync --check` — it scans every standing bind present on disk for
a conforming `AGENTS.md`/`CLAUDE.md` bridge.

## Cross-repo changes, inside the workspace

When a task needs a branch or a commit in a standing bind, do it inside
`workspace/<repo>` (per the resolved `base`), never in a checkout this workflow doesn't
own. Once there, that repo's own git and its own `AGENTS.md` law apply — branch,
commit, and push per *that* repo's conventions, same as you would in any checkout of
it. The workspace only changes *where* the clone lives, not what governs working in it.
