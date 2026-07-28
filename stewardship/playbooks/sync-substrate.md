# Playbook: sync the substrate

Bring every repo in the manifest present + fresh under `base`, without touching anyone's
in-flight work.

## Procedure
1. `cd <workflows>/stewardship && ./bin/sync.sh --all` (or a named group: `./bin/sync.sh globalshopsolutions`).
2. Read the report line by line:
   - `cloning (branch)` / `up to date` — healthy.
   - `~ dirty working tree — fetch only` — someone's in-flight work; leave it. Note it in
     the journal only if it's been dirty for a long time (drift).
   - `~ on <X> (manifest tracks <Y>)` — expected for active feature work; drift if stale.
   - `~ diverged — resolve manually` — always journal + surface to the owner. Never force.
   - `! clone/fetch failed` — auth or manifest rot; fix the cause, not the symptom.
3. Journal anything skipped/failed as `journal/YYYY-MM-DD-sync.md` (one file per run).

## Notes
- `sync.sh` reads `../../manifest.yaml`; override with `GSS_MANIFEST=/path` for testing.
- Requires `yq` (mikefarah v4) + git auth for the GSS orgs (`github-gss` SSH alias / `gh`).
