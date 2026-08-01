# Worktree isolation for concurrent-mutation workers

When multiple workers mutate the same repo concurrently, isolate them. **Which repo gets the
worktree depends on where the work actually happens — the Agent tool's `isolation: 'worktree'`
flag does not answer that question, it only isolates one specific repo.**

## Why the flag is often the wrong mechanism

`isolation: 'worktree'` isolates the repo containing the **session's own working directory** —
the workflow repo you are running in. That is correct when the workflow repo is also the thing
being mutated. It is wrong whenever the work lands in a *different* repo than the session's own
— most commonly a workflow-over-substrate layout, where the workflow repo owns doctrine and the
substrate a worker actually edits lives elsewhere (e.g. under a gitignored `workspace/`, per
`AGENTS.CORE.md`'s "The workspace"). A worktree of the workflow repo then contains **no
substrate at all** — a worker dispatched into one finds nothing to work on.

This fails as a **silent no-op, not an error.** The worktree is created successfully, the worker
starts successfully, and it either does nothing or improvises against whatever it can find. Test
the flag against one worker before trusting it for a batch — do not assume it isolates the repo
you meant.

**The general rule: worktree the repo actually being mutated, not the repo the session happens
to be running in.** When those are the same repo, the flag is the right tool and setup ends
there. When they differ, cut the worktree by hand against the substrate repo, as below.

## The procedure

```sh
# one per task, cut from the substrate's current main
/usr/bin/git -C workspace/<repo> worktree add ../<repo>-wt/<TASK> -b wt/<TASK> main
# the toolchain has to work without a reinstall
ln -sfn "$PWD/workspace/<repo>/node_modules" workspace/<repo>-wt/<TASK>/node_modules
# ...and the symlink must be excluded, or it shows as untracked - see below
echo node_modules >> "$(/usr/bin/git -C workspace/<repo>-wt/<TASK> rev-parse --git-path info/exclude)"
```

**The exclude line is not optional.** A repo's `.gitignore` conventionally says `node_modules/`
with a trailing slash, which matches a *directory* and **not a symlink** — so the symlink you
just created shows up as untracked in the worker's `git status` even though the real directory
it points at is ignored. Consequences: a worker distrusts the `git add -A` its briefing told it
was safe and hand-builds a pathspec list instead, and `worktree remove` later refuses on
"modified or untracked files". `.git/info/exclude` is the right home for it — it is
worktree-local and per-machine, so nothing is added to the substrate repo's committed ignore
rules for scaffolding that is ours, not the app's.

Verify the toolchain in one worktree before dispatching the batch — a broken symlink discovered
by five workers at once is five wasted dispatches.

A worktree cut under a gitignored parent (`workspace/<repo>-wt/`, if `workspace/` itself is
gitignored) never appears in the workflow's own `git status`. If your layout puts worktrees
somewhere else, gitignore them explicitly — a stray worktree directory showing as untracked in
the *workflow* repo is the same class of error this file exists to prevent.

## What the briefing must say

Every worker briefing carries, verbatim in substance:

- your working directory is `<abs path to worktree>`, on branch `wt/<TASK>`, cut from main at
  `<sha>`
- work **only** there; do not touch the shared checkout or any other worktree
- **`git add -A` is safe here and you should use it** — you have the tree to yourself
- commit on `wt/<TASK>`; do **not** merge, rebase, push, or switch branches
- report your branch and commit sha; the orchestrator merges
- your baseline is green (state the test/typecheck counts) — **so any error you see is yours.**
  There is no "pre-existing breakage from another worker" excuse available

That last line is worth its space. Under a shared tree, "pre-existing, not mine" is the single
most common unfalsifiable claim in a worker report, and checking each one costs the orchestrator
real verification effort. A green baseline in a private tree makes the claim checkable by
construction.

## `git add -A` is correct in a worktree and forbidden in a shared tree

The rule was always about **tree ownership**, never about the isolation mechanism. Do not carry
a shared-tree prohibition into a worktree briefing: it makes workers hand-build fragile pathspec
lists to solve a problem they do not have.

## Merge and cleanup — the orchestrator's job, not the worker's

On a returned branch:

1. Verify the work against the task's own acceptance test, as always.
2. `/usr/bin/git -C workspace/<repo> merge --no-ff wt/<TASK> -m "merge(<TASK>): <what it does>"`
3. **Run the integration check on main** — full suite and typecheck. This is the signal a shared
   tree gives continuously and a worktree defers to exactly this moment. Skipping it is how a
   clean merge ships a broken tree.
4. **Clean up immediately, in the same step:**
   ```sh
   rm -f workspace/<repo>-wt/<TASK>/node_modules          # the symlink, or removal refuses
   /usr/bin/git -C workspace/<repo> worktree remove ../<repo>-wt/<TASK>
   /usr/bin/git -C workspace/<repo> branch -d wt/<TASK>
   ```
   The symlink deletion is not optional: `worktree remove` refuses on "modified or untracked
   files" because the `node_modules` symlink is untracked in the worktree. **Do not reach for
   `--force` — the refusal is correct and it is the same check that would stop you deleting a
   worker's real uncommitted work.** Remove the scaffolding you created, then let the unforced
   command run. If it still refuses, something real is in there: look at it, do not force it.

   Use `branch -d`, never `-D`, for the same reason — it refuses if the branch is not merged,
   which is exactly the mistake worth catching at this step.

   Cleanup belongs to the merge, not to a sweep at the end of the run. A worktree left behind
   after its branch is merged is stale state a later cold tick has to reason about, and
   `git worktree list` is the only place it shows.
5. Record the merge and the cleanup on the task's `evidence:`/`merge:` lines.

Cut later worktrees from the **merged** main so each new task inherits the work already landed.
Only branch from an older point deliberately, and say why.

## When a worker is already running, leave it

Do not move a live worker into a worktree mid-flight — it strands uncommitted work. Same call as
a harness death: resume what exists, migrate the next batch.

## Why this is doctrine and not a preference

**A shared index is a global lock held by people who cannot know they hold it.**

Concurrent workers in one checkout interfere through three shared resources, none of which a
worker can see it is contending over:

- **the stash** — one worker's `git stash` carries another's file, and is unusable for a whole
  task while another worker's work sits unmerged
- **the index** — files revert under a worker that never touched them; `git add -A` is unsafe
  because the staging area is not the worker's own
- **the type-checker** — a live type flickers under `tsc` for two unrelated workers, so a build
  error is a fact about timing, not about the code

The cost lands as tokens spent investigating another worker's transients, not as broken code.
That is why it is nearly invisible in the artifact afterward, and easy to under-price in
advance: the work looks fine at the end, and nothing records what it cost to get there.

The argument that loses to this is merge cost. It measures the wrong thing: merges are cheap,
legible, and happen once per task, under an orchestrator that is already verifying that task.
Cross-worker interference is none of those.
