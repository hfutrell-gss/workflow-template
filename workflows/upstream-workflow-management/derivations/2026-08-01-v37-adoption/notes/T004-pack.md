# T004 — pack-code-craft reachability, contents, scan

## 1. Clone URL — what actually works

The task's stated trap is itself wrong on this machine; verified directly rather than
trusted. Actual state:

```
$ gh auth status
github.com
  Logged in to github.com account hfutrell-gss
```
`gh` is authenticated as **hfutrell-gss**, not `henningfutrell` as the brief claimed.

SSH identities (`~/.ssh/config`):
- `github.com` (default, key `id_github2`) → `ssh -T git@github.com` = **Permission
  denied (publickey)**.
- `github-gss` (key `id_github-gss`) → `ssh -T github-gss` = authenticates as
  **hfutrell-gss**.
- `github-personal` (key `id_github-personal`) → `ssh -T github-personal` =
  authenticates as **henningfutrell** — the account the pack is published under.

Clone attempts, all via `/usr/bin/git`, from
`/tmp/.../scratchpad/pack-test/`:

```
$ /usr/bin/git clone git@github.com:henningfutrell/pack-code-craft.git ssh-default
git@github.com: Permission denied (publickey).
fatal: Could not read from remote repository.
EXIT=128   -- FAIL

$ /usr/bin/git clone github-gss:henningfutrell/pack-code-craft.git ssh-gss
ERROR: Repository not found.
fatal: Could not read from remote repository.
EXIT=128   -- FAIL (authenticates as hfutrell-gss, which has no access; repo is private)

$ /usr/bin/git clone https://github.com/henningfutrell/pack-code-craft.git https-clone
remote: Repository not found.
fatal: repository '.../pack-code-craft.git/' not found
EXIT=128   -- FAIL (unauthenticated HTTPS; repo is private, 404 confirmed via curl too)

$ /usr/bin/git clone github-personal:henningfutrell/pack-code-craft.git personal-clone
Cloning into 'personal-clone'...
EXIT=0     -- SUCCESS
```

**Working form:** `git clone github-personal:henningfutrell/pack-code-craft.git`
(SSH alias `github-personal`, key `id_github-personal`, account `henningfutrell`).
The journal's `github-gss` reference and the brief's account attribution for `gh` are
both wrong on this machine — `github-gss` auths as `hfutrell-gss`, and it is `gh` that
is actually on `hfutrell-gss`, not `henningfutrell`. Neither reaches the (private) repo.
Confirmed branch is `main` (`origin/HEAD -> origin/main`).

## 2. pack.yaml (full)

```yaml
name: code-craft
version: 2
requires_core: 30

provides:
  - .agents/skills/code-craft-tdd/**
  - .agents/skills/code-craft-quality/**
  - .agents/skills/code-craft-event-naming/**
  - .agents/skills/code-craft-ubiquitous-language/**
  - .claude/skills/code-craft-tdd/SKILL.md
  - .claude/skills/code-craft-quality/SKILL.md
  - .claude/skills/code-craft-event-naming/SKILL.md
  - .claude/skills/code-craft-ubiquitous-language/SKILL.md
```
Core here is at VERSION 37 — `requires_core: 30` is satisfied.

## 3. Shape compliance (AGENTS.CORE.md "Composition", allowed shapes)

All 8 claimed paths are one of the four allowed shapes:
- `.agents/skills/<name>/**` — 4 entries (code-craft-tdd, code-craft-quality,
  code-craft-event-naming, code-craft-ubiquitous-language)
- `.claude/skills/<name>/SKILL.md` — 4 matching discovery stubs

No `workflows/<name>/SKILL.md` or `workflows/<name>/references/**` claims. No overlay
paths (`.agents/code-craft/*`) claimed — correct, those are the derivation's own
overrides. **No violations found; every claimed path is compliant.**

## 4. `template-sync.sh scan` output (verbatim)

Run against the local clone
(`/tmp/.../scratchpad/pack-test/personal-clone`):

```
pack-scan: no findings. This is a heuristic pass, not a guarantee -- it does not
           detect a competent attacker. Install packs you wrote, or packs whose
           maintainer you already trust with this repo.
```
Exit 0. No shape findings, no content findings.

Manual cross-check of the tree: 27 tracked files, all markdown/config/asset (arch-test
snippets for dotnet/go/kotlin/python/typescript) under the four skill directories, plus
`pack.yaml`, `README.md`, `.gitignore`. **Zero executable files** (`find -perm -u+x`
empty); the only `.js` files are static lint-rule snippets
(`.dependency-cruiser.js`, `eslint-boundaries-snippet.js`), not run by anything in the
pack itself. Nothing pipes to shell, nothing reads credentials, no egress calls.

## 5. Skill names shipped (for collision check)

- `code-craft-tdd`
- `code-craft-quality`
- `code-craft-event-naming`
- `code-craft-ubiquitous-language`

## 6. Reasons NOT to install, if any

None found in the pack's own content — scan is clean, shapes are clean, `requires_core`
is satisfied by this core (37 ≥ 30). The only live issue is upstream-access hygiene, not
the pack: the repo is private and reachable from this machine only via the
`github-personal` SSH identity. Before repointing any derivation's `packs.yaml` upstream
at this URL, confirm that identity will be available wherever `update`/`add` runs next
(CI, another machine, etc.) — `github-gss` and default `gh` both fail here, and would
fail identically elsewhere unless `github-personal`'s key is provisioned there too.
