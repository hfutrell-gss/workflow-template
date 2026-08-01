# __APP__ — operational particulars

The durable picture of this application, as `workflows/__WORKFLOW__/` acts on it.
Survives every session. Update it when the facts change, not when a session ends.

Its own repo's docs stay authoritative for how it works internally. This file records
what the workflow needs to know to operate it.

Write every claim so it cannot decay silently: **a claim that can go out of date carries
the trigger that invalidates it, or it is not written here.** State what would make it
false — "no glossary yet; delete this line when `GLOSSARY.md` exists", "two docs are
stale as of the last schema change; re-check on the next one". A bare point-in-time fact
becomes false with nothing to signal it, and the next session reads it as true.

## What it is

<!-- One or two lines. -->

## How it runs locally

<!-- Exact commands. -->

## How it deploys

<!-- Or "it does not", stated plainly. -->

## What it depends on

<!-- Services, credentials, other applications. -->

## What breaks first

<!-- Known fragilities, in the order they have actually failed. -->

## Decisions taken and refused

<!-- A decision to refuse or de-scope work lands here when it is not the stewarded
     repo's own docs that hold it. One entry each:
     - **<what was refused or decided>** — <why>. Signed off by <who>, <date>.
     Keep refusals as long as the application lives: without them, "not built" is
     indistinguishable from an open gap and the question gets re-opened. -->

## Particulars

<!-- Anything true of this application and no other: adopted conventions, deliberate
     exceptions to workflow defaults, standing constraints. -->
