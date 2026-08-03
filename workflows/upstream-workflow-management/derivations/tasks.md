# derivations — carried work and history

Opened 2026-08-01. This file **crosses sessions**. It is not a session task list and
`orchestrate.sh` never reads it as one. It answers two questions a reader standing at
the application asks: **what is still wanted**, and **what has been done here**.

What belongs here:

- **Epics** — work too large for one session, tracked across several.
- **Deferred tasks** — promoted out of a session that closed. Each arrives with the
  session that raised it and why it could not finish there.
- **Standing threads** — anything that must be picked up by whoever runs the next
  session against derivations.
- **Security findings** — exposure this application carries, found by a session that was
  not looking for it.
- **Closed threads** — what each of the above resolved to, and what closing it found.
- **History** — one line per closed session, written by `orchestrate.sh close`.

What does not belong here: the application's operational particulars (that is
`profile.md`), a way of working (that is `workflows/upstream-workflow-management/SKILL.md`), or a
decision about this workflow repo itself (that is `journal/`).

## Open

<!-- - **<short title>** — raised by <session>. <why it is still open, what unblocks it.> -->

## Security

Exposure this application carries: what is reachable, what is unencrypted, what is
authorized more widely than intended. **Not work — a standing fact about the
application**, which is why it does not live in `## Open`. Work in `## Open` reads as
something a session may pick up and close; an exposure stays true until somebody changes
the system, and a reader must be able to see all of it without inferring which open
threads happen to be security.

Most entries here are found by a session that was **not looking for them** — a by-product
of a probe, a config read, a measurement. That is exactly why they need a home: the
session that stumbles on one has no reason to keep it, and it is the finding least likely
to be rediscovered on purpose.

Each entry states **what is exposed**, **the evidence**, and **what would settle it** —
never a guessed severity. An unverified default is recorded as unverified. Read-only
discipline holds: reachability stops at a handshake, nothing is authenticated against,
nothing is modified to prove a point.

An entry leaves only two ways, and both go to `## Closed` — this is not a second ledger:
**fixed**, with the change; or **accepted**, with the `signoff:` of whoever accepted the
risk. Silence is neither, and an entry with neither stays here.

<!-- - **<what is exposed>** — raised by <session>. <the evidence, exact. what would
     settle it. read-only caveats if the finding came from a probe.> -->

## Closed

A thread that finished: who raised it, who closed it, the commit, and **what the
resolution found that the raising session did not know**. Moved here out of `## Open`,
and never deleted — a thread that merely vanishes reads as one still wanted.

This is not a second `## History`. The two answer different questions at different
grains: a History line is per **session** (its directive, its counts, where its reaping
landed) and cannot say what any one thread resolved to.

<!-- - **<short title>** — raised by <session>, closed by <session> (<commit>). <what
     the resolution found; anything it deliberately did not settle, and why.> -->

## History

One line per session closed against derivations, appended by `orchestrate.sh close`.
Permanent: the session directory is deleted, and this is what remains of it besides
`git log`. Do not hand-write entries here — a line nobody earned by passing the DoD
gate is a claim, not a record.
