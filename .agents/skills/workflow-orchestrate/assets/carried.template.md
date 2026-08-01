# __APP__ — carried work and history

Opened __DATE__. This file **crosses sessions**. It is not a session task list and
`orchestrate.sh` never reads it as one. It answers two questions a reader standing at
the application asks: **what is still wanted**, and **what has been done here**.

What belongs here:

- **Epics** — work too large for one session, tracked across several.
- **Deferred tasks** — promoted out of a session that closed. Each arrives with the
  session that raised it and why it could not finish there.
- **Standing threads** — anything that must be picked up by whoever runs the next
  session against __APP__.
- **Closed threads** — what each of the above resolved to, and what closing it found.
- **History** — one line per closed session, written by `orchestrate.sh close`.

What does not belong here: the application's operational particulars (that is
`profile.md`), a way of working (that is `workflows/__WORKFLOW__/SKILL.md`), or a
decision about this workflow repo itself (that is `journal/`).

## Open

<!-- - **<short title>** — raised by <session>. <why it is still open, what unblocks it.> -->

## Closed

A thread that finished: who raised it, who closed it, the commit, and **what the
resolution found that the raising session did not know**. Moved here out of `## Open`,
and never deleted — a thread that merely vanishes reads as one still wanted.

This is not a second `## History`. The two answer different questions at different
grains: a History line is per **session** (its directive, its counts, where its harvest
landed) and cannot say what any one thread resolved to. That last part is the whole
value — *the thread was under-counted when raised*, *this half was deliberately left
unsettled* — and it exists in no other record.

<!-- - **<short title>** — raised by <session>, closed by <session> (<commit>). <what
     the resolution found; anything it deliberately did not settle, and why.> -->

## History

One line per session closed against __APP__, appended by `orchestrate.sh close`.
Permanent: the session directory is deleted, and this is what remains of it besides
`git log`. Do not hand-write entries here — a line nobody earned by passing the DoD
gate is a claim, not a record.
