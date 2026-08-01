# 2026-08-01 — the ledger, and what the journal is actually for (v35)

Two questions, one answer.

**"We harvested a session and I see nothing."** True. Harvest recorded *where output
landed*. Nothing recorded *that the session ran*, against what, or with what result. The
session directory was deleted by hand and took the only account of the run with it.

**"What is the journal for?"** It had two jobs and they contradicted. `AGENTS.CORE.md`
called it "what happened on a given day"; the harvest law routed "what merely happened"
there. Evidence from the two repos that use it:

| Repo | Entries | Kind |
|---|---|---|
| `workflow-template` | 9 | every one a decision about the system |
| `workflow-personal-app-management` | 2 | one derivation record, one session narrative |

The nine that earned their keep are all system decisions. The single session narrative is
the form the user rejected on sight — because `git log` already holds it, verbatim and
for free.

## What changed

**`orchestrate.sh close`** — new, and now the only supported way a session ends. It
re-checks the DoD, appends one line to the application's `tasks.md` under `## History`,
and deletes the session directory. One command, because it was two steps before and the
ledger was the step nobody did.

The line is derived from the task list, never written by hand:

```
- **2026-08-01-gate** — Do the thing.
  1 done · 1 dropped · 1 carried · 0 blocked. Harvest: workspace/app/docs/
```

Directive verbatim, counts by disposition, harvest destination. It cannot flatter the run
because nothing in it is prose anyone chose at closing time.

**The journal is now one thing:** a decision about *this workflow repo*, written when the
reason would not survive in a diff. The test, stated in the constitution: *would this
still matter to someone who never touched the application it came from?* No → it is a
ledger line. `workflow-bind` no longer writes session binds there either; those are run
state and belong in the session's `## Log`.

**`LAYOUT-008`** — every application `tasks.md` has `## Open` and `## History`. `close`
creates `## History` if it must, but nothing creates `## Open`: a session that ends with
carried work and no place to put it loses it silently, which is the exact failure the
application level exists to prevent.

## Why the ledger sits at the application

Because that is where a reader stands. The question is "what has been done to this app?",
and it is asked next to the carried work the same sessions produced. A record at the
session level cannot answer it — the session is gone. `git log` can answer it, and only
for a reader who already knew to look.

Dispatch mechanics still do not survive: tier, agent, ordering, the dependency graph are
how the work was organized, not facts about the application. Unchanged.

## Action items

None. Core at v35; derivations converge with `/workflow-template-sync update`.
