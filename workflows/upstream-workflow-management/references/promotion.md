# Promotion — the full procedure and its failure modes

Read each failure mode symptom first — the symptom is what you will see.

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
one a git worktree; a change one worker makes to files no concurrent worker touches needs
no worktree, and adding one there costs setup and a merge for nothing. The Agent tool's
`isolation: 'worktree'` flag isolates the **session's own** repo, which is the wrong repo
in a workflow-over-substrate layout. See `/workflow-orchestrate`
`references/worktrees.md`.

**Failure mode: a wholesale rewrite on a stale base.** A worker that rewrites a managed
file loses concurrent edits **without conflicting** — git merges the rewrite cleanly and
the lost lines look like they were never there. Before merging a rewrite, diff the merged
result against the pre-merge tip for rules that vanished, not just for conflicts.

## 3. Manifest before VERSION

The destination's manifest lists its managed set exactly — `template-manifest.yaml`
(`managed:`) for the core, `pack.yaml` (`provides:`) for a pack. `update` copies only
what it lists. Directory globs (`path/**`) are replaced wholesale, so deletions inside
them propagate.

**A path removed from a manifest is DELETED downstream** on the next update, with its
emptied parent directories pruned. That is how a retired skill actually leaves; it also
means an accidental deletion from the manifest destroys the path in every repo. Diff the
manifest, not just the files.

**Most new files need coverage verified, not an entry added.** Manifest entries are
mostly directory globs (`.agents/skills/<name>/**`), so a new file inside an existing
glob is already carried and a literal `grep` for its path returns nothing — which reads
as a failure and invites a duplicate entry. Ask whether some entry covers the path:

```sh
new=.agents/skills/workflow-agents-sync/agents-sync.sh
yq -r '.managed[]' template-manifest.yaml | while read -r p; do
  case "$new" in ${p%\*\*}*) echo "covered by: $p" ;; esac
done
```

No output means no entry covers it — add one, then bump.

**Failure mode: a new skill or workflow that no derivation ever receives.** Bumping the
manifest `version:` in one task while its coverage is added in a later task ships a
version number with nothing behind it. Cover the path first, bump second.

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

**A rename of a managed skill lands with a grep of every standing bind for the old
name.** `update` carries the managed paths and nothing else, so a rename propagates to
zero substrate: a bound repo's own `AGENTS.md`, docs, and task lists keep citing a skill
name that no longer resolves, and nothing reports it. Run the grep as part of the
release, and fix or list every hit:

```sh
/usr/bin/git grep -n '<old-skill-name>' -- . ; \
  for r in workspace/*/; do /usr/bin/git -C "$r" grep -n '<old-skill-name>' || true; done
```

## 6. State the remaining gate

After a release the derivation often still runs stale managed scripts. A checker that
enforces the rule the release just reversed will report the new, correct state as DRIFT.
Say so. An unexplained DRIFT line reads as a defect and gets "fixed" backwards by the
next session.

## Files that `update` cannot carry

Check the manifest before assuming. `CLAUDE.md` **is** managed and `update` carries it.
`AGENTS.md` is derivation-owned and it does not. A change to `AGENTS.md`'s required shape
must therefore ship as a `--fix` path in `agents-sync.sh`, or every existing derivation
keeps the old shape forever. Ask, for any shape change: *what mechanism moves existing derivations?*
If the answer is "a person edits it by hand", the change is not finished.
