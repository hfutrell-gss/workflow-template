# workflows

The org's methodology as one monorepo. Each top-level directory is a **workflow**: the
techniques, tactics, procedures, and doctrine for a whole area of work. Code repos are
substrate — workflows operate *on* them; you work *in* a workflow. See
[AGENTS.md](AGENTS.md) (the constitution) for the init mandate, checkout model, binding
law, journal discipline, and tiers. `AGENTS.md` files are canonical; `CLAUDE.md` files are
header bridges only (enforced by `/workflows-agents-sync`).

## Checkout
```sh
bin/wf --list                      # what workflows exist
bin/wf stewardship                 # doctrine-only session
bin/wf stewardship identity gitops # bind substrate targets (cloned if absent)
```
Put `bin` on PATH (or `ln -s ~/workbench/workflows/bin/wf ~/.local/bin/wf`) and it's just
`wf <workflow> [targets...]` from anywhere.

## Index
| Workflow | Tier | Area of work |
|----------|------|--------------|
| [stewardship](stewardship/AGENTS.md) | dev | The working environment itself: substrate assembly, manifest custody, agent-law distribution, drift watch |

## Baked-in skills
| Skill | Purpose |
|-------|---------|
| `/workflows-init` | Install/verify tooling (yq, Obsidian, codegraph); writes per-machine `init.lock` checked by the constitution's first mandate |
| `/workflows-agents-sync` | Enforce AGENTS-canonical format (CLAUDE.md = header bridge) across this repo and all substrate repos |

## Shared data
- [`manifest.yaml`](manifest.yaml) — substrate registry: every repo (url, tracked branch,
  description) + named groups. Custodian: stewardship.

## Adding a workflow
Copy [`_template/`](_template/CLAUDE.md) to a new top-level dir, write the doctrine, add a
row here.
