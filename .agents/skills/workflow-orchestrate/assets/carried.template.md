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
- **History** — one line per closed session, written by `orchestrate.sh close`.

What does not belong here: the application's operational particulars (that is
`profile.md`), a way of working (that is `workflows/__WORKFLOW__/SKILL.md`), or a
decision about this workflow repo itself (that is `journal/`).

## Open

<!-- - **<short title>** — raised by <session>. <why it is still open, what unblocks it.> -->

## Closed

<!-- Move an entry here with the session that finished it. Delete nothing: the next
     session needs to know a thread was closed, not merely that it vanished. -->

## History

One line per session closed against __APP__, appended by `orchestrate.sh close`.
Permanent: the session directory is deleted, and this is what remains of it besides
`git log`. Do not hand-write entries here — a line nobody earned by passing the DoD
gate is a claim, not a record.
