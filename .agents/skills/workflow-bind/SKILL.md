---
name: workflow-bind
description: >-
  Bind repos to the current session: attach this workflow's default standing binds
  (binds.yaml) plus anything else asked for, via /add-dir, and record what got bound in
  today's journal entry. Use when asked to bind a repo, start a session against this
  workflow's substrate, or attach standing binds for today's work. No separate CLI —
  this is a procedure for Claude to run in-session.
---

# workflow-bind

Session binds are repos actually attached to *this* session (see `AGENTS.CORE.md`,
"Bind law") — distinct from the standing-bind registry in `binds.yaml`, which just
declares relationships. This skill has no script: binding happens through the running
session itself (`/add-dir`), which a helper process can't do on your behalf.

## Procedure

1. **Read `binds.yaml`.** List `standing` entries; note which have `default: true`.
   ```sh
   yq -r '.standing[] | select(.default == true) | .repo' binds.yaml
   ```
2. **Resolve each repo to bind** — every `default: true` standing bind, plus any repo
   the user asked for on top (by name, if it's a standing bind; by path otherwise).
   - Look up `base` in `binds.yaml` (defaults to `./workspace` — this workflow's own
     substrate workspace, gitignored, resolved relative to the repo root; an absolute
     or `~`-prefixed `base` is the legacy, discouraged form that points at a shared
     checkout instead). A named standing bind resolves to `<resolved base>/<repo>` —
     e.g. `workspace/<repo>` in the normal case.
   - If it isn't on disk yet and has a `url`, offer `/workflow-manage`'s
     `sync-binds.sh <repo-name>` before binding (or ask the user first — cloning
     is a real side effect, unlike attaching an existing dir).
3. **Attach each resolved path** with `/add-dir <path>` (already in a running session)
   — or, if this is guidance for launching a *new* session, tell the user to pass
   `claude --add-dir <path>` (repeatable) at launch instead; `/add-dir` only works
   in-session.
4. **On each bind, obey the bind law**: read the target's `AGENTS.md` before doing
   anything in it, and honor its acknowledgement protocol if it has one. Repo law wins
   inside that repo's own boundaries.
5. **Record it.** Append (or create) today's journal entry —
   `journal/YYYY-MM-DD-<slug>.md` — noting which repos got session-bound and why. Don't
   edit a previous day's file; one dated file per run.

## Notes
- Standing binds are declarative only — being listed in `binds.yaml` (even with
  `default: true`) doesn't mean a repo is bound to any particular session until this
  procedure (or an explicit `--add-dir`) actually runs.
- `default: true` is a convenience default, not a requirement — bind fewer or more
  repos than the defaults whenever the work calls for it.
