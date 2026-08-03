# orchestrate: split procedure from run, add the reaping gate

VERSION 20. `.workflow/<session-slug>/` conflated two things "workflow" was supposed to keep
apart: the reusable procedure for a kind of work, and one dated run of it. `playbooks/` — the
nominal home for the procedure — stayed empty because nothing ever wrote to it; every run's
notes and decisions lived and died inside its own dated directory instead.

## The split

```
workflows/<workflow>/                    DURABLE — the procedure. Never pruned.
workflows/<workflow>/<target>/tasks.md   INSTANCE — one run. Disposable after reaping.
```

`<workflow>` names a way-of-working (`refactor`, `create-web-app`, `onboard-app`).
`<target>` is the repo the work lands in, not a date — a long-lived task set per
(workflow, target) pair, reopened across sessions rather than recreated daily. The rule
that keeps the conflation from re-forming: **everything under `<target>/` is disposable
after reaping, by definition.** Anything not disposable belongs one level up, in the
target's own docs, or in the journal.

## Reaping is now part of DoD

Exhaustion alone let a run finish every task and still leave its durable output
stranded in a directory a later prune deletes. `orchestrate.sh status` now also reads a
`## Reaping` section's `reaping:` field — `pending` (the default, including for files
that predate this gate) or `done <where it went>`. Bare `done` with no destination is a
violation, same tier as `[x]` without `evidence:`. Chose a field in the file `status`
already parses over a separate `REAPED` marker file — one place to check, no risk of
the marker and the task list disagreeing.

Confirmed against the actual craft-covenants run
(`.workflow/2026-07-30-craft-covenants/`): before the gate it reported `EXHAUSTED`; after,
correctly `NOT EXHAUSTED (reaping pending)` — its output had genuinely shipped (VERSION
18's managed craft assets) but nothing said so in the file. Added a retroactive
`reaping: done ...` line recording that; verdict returns to `EXHAUSTED`.

## Backward compatibility

A live run exists in a bound derivation at `.workflow/2026-07-30-tempest-apps/` (73
tasks, 13 open). `status`/`ready`/`list` keep resolving `.workflow/<slug>/tasklist.md`
for one version, printing a `NOTE:` naming the path every time. `init` never writes
there — only the new layout. The fallback is documented as scheduled for removal in
`references/tasklist.md` "Legacy layout".

## CLI shape

`init <workflow> <target>` replaces `init <name>` (which prepended today's date). A run
is now keyed by the pair, not a date — `status`/`ready` take that same key
(`<workflow>/<target>`, or a bare legacy slug); `list` shows both layouts side by side.

## Bug caught during verification

`resolve_session`'s per-branch `[ "$legacy" = "1" ] && note_legacy ...; return` pattern
silently made the function return the *left-hand test's* exit status whenever the
condition was false — `return` with no argument inherits the previous command's status.
Under `set -e` that terminated the whole script with exit 1 and no message, on the
ordinary (non-legacy) path. Fixed by converting every such guard to an explicit `if`
block ending in `return 0`. Caught by actually running the script against a real
non-legacy run, not by reading it — the reason the task required a verification
transcript rather than a claim.

## Retrieval mechanism — not built, only named

`workflows/<workflow>/` is a directory; nothing loads it at the moment of need.
`references/tasklist.md` now documents the intended pattern — a thin, derivation-local
skill stub outside the `workflow-*`/`craft-*` prefixes, whose frontmatter `description`
is the retrieval surface and whose body points at `workflows/<workflow>/`. No specific
stub was built; the doctrine only names the shape so a derivation can fill it once a
procedure is worth retrieving.
