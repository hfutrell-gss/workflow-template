# Promotion — the full procedure and its failure modes

Every failure below was paid for in a real session. They are listed with the symptom
first, because the symptom is what you will see.

## 1. Bind and verify the upstream

`.template.lock` records `upstream:`. A local path or a git URL both work. Verify it is
reachable **and writable** before planning any work against it:

```sh
/usr/bin/git ls-remote <upstream> >/dev/null && echo reachable
```

**Failure mode: read access is not write access.** An SSH config alias can authenticate
clone, fetch, and `--check` as one identity while the push identity has no permission.
The defect stays invisible until the push at the end of the work. Symptom:

```
Permission to <org>/<repo>.git denied to <user>
```

Fix the remote and correct `.template.lock` and `binds.yaml` together. A `.template.lock`
that names a URL you cannot push to will send the next session down the same path.

**Failure mode: concluding there is no upstream.** Read `.template.lock` before deciding
that in-place editing is the only option. A wrong reading here inverts the whole
approach and every task built on it.

## 2. Change upstream, never in place

Work in `workspace/workflow-template`. If parallel workers touch the template, give each
one a git worktree. The Agent tool's `isolation: 'worktree'` flag isolates the
**session's own** repo, which is the wrong repo in a workflow-over-substrate layout. See
`/workflow-orchestrate` `references/worktrees.md`.

**Failure mode: a wholesale rewrite on a stale base.** A worker that rewrites a managed
file loses concurrent edits **without conflicting** — git merges the rewrite cleanly and
the lost lines look like they were never there. Before merging a rewrite, diff the merged
result against the pre-merge tip for rules that vanished, not just for conflicts.

## 3. Manifest before VERSION

`template-manifest.yaml` lists the managed set exactly. `update` copies only what it
lists. Directory globs (`path/**`) are replaced wholesale, so upstream deletions
propagate.

**Failure mode: a new skill or workflow that no derivation ever receives.** Bumping the
manifest `version:` in one task while the new path is added in a later task ships a
version number with nothing behind it. Add the path first. Verify:

```sh
grep -n '<new-path>' template-manifest.yaml
```

## 4. Run the checks the change touches

- Doctrine or bridge change → `.agents/skills/workflow-agents-sync/agents-sync.sh`
- Any script → `bash -n <script>`, then exercise its exit codes directly. Do not pipe
  the output through another command and read that command's status.
- Orchestration change → `orchestrate.sh status` against a real session directory.
- Loading-path change → probe it. `claude -p` from context only will say whether a file
  actually reaches context. Do not assume an import chain resolves.

**Failure mode: a script committed without its executable bit.** Symptom: `permission
denied` where a documented gate should run. Check:

```sh
/usr/bin/git ls-files -s <script>   # expect 100755
```

## 5. Push, then converge

Prefer `workflow-template-sync update` in the derivation.

When `update` is gated — a live session, a script the update would swap mid-run — you may
hand-apply the change to the derivation's managed copy **only** when the result is
byte-identical to upstream. Verify it, and say in the commit message that the copy is
converged rather than edited:

```sh
diff -q <derivation>/<file> workspace/workflow-template/<file>
```

Anything less than identical is drift wearing a convergence label.

## 6. State the remaining gate

After a release the derivation often still runs stale managed scripts. A checker that
enforces the rule the release just reversed will report the new, correct state as DRIFT.
Say so. An unexplained DRIFT line reads as a defect and gets "fixed" backwards by the
next session.

## Files that `update` cannot carry

`CLAUDE.md` and `AGENTS.md` are derivation-owned. A change to their required shape must
ship as a `--fix` path in `agents-sync.sh`, or every existing derivation keeps the old
shape forever. Ask, for any shape change: *what mechanism moves existing derivations?*
If the answer is "a person edits it by hand", the change is not finished.
