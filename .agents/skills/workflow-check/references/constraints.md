# The constraint registry

Every organizational constraint this system enforces, with a stable ID. Cite the ID —
in a commit, a report, a task list — and the reader can look up exactly what was broken.

**Each constraint is owned by the skill that owns the shape it constrains.** That is the
categorical rule applied to enforcement. `/workflow-check` runs them all and returns one
verdict; it implements none of them. A constraint implemented in the aggregator instead
of its owner is the fragmentation this registry exists to end.

An unmet constraint is an ordinary result (exit 2), not a failure. Only a checker that
cannot run is a failure (exit 1).

## TOOL-* — `/workflow-init`

Per-machine tooling and `init.lock`. Reported by `init.sh --check`.

| ID | Constraint |
|----|------------|
| `TOOL-*` | Required tools present; recommended tools decided, not silently skipped; `init.lock` matches the current init `VERSION`; no `git` alias shadowing native git |

## AGENTS-* — `/workflow-agents-sync`

Canonical file format. Reported by `agents-sync.sh`; `--fix` repairs what is safe.

| ID | Constraint |
|----|------------|
| `AGENTS-001` | Every directory with an `AGENTS.md` has a `CLAUDE.md` bridge |
| `AGENTS-002` | `CLAUDE.md` imports `@AGENTS.md` and holds no content of its own |
| `AGENTS-003` | `CLAUDE.md` never composes — importing `@AGENTS.CORE.md` or `@VOICE.md` there is drift, because that decision belongs to the AGENTS chain |
| `AGENTS-004` | Root `AGENTS.md` imports `@AGENTS.CORE.md`; `AGENTS.CORE.md` imports `@VOICE.md` |
| `AGENTS-005` | Every `.claude/skills/<name>/SKILL.md` is a stub: discovery frontmatter plus a pointer to its canonical body |
| `AGENTS-006` | Nothing executable and no non-`SKILL.md` file under `.claude/skills/` |
| `AGENTS-007` | A derivation has a `GLOSSARY.local.md` — its own ubiquitous language, distinct from the managed `GLOSSARY.md` |

## LAYOUT-* — `/workflow-orchestrate`

Directory shape for workflow, application, and session. Reported by `orchestrate.sh check`.

| ID | Constraint | Why it matters |
|----|------------|----------------|
| `LAYOUT-001` | No `.workflow/` directory | The legacy flat layout has no application or session level, so carried work has nowhere to live |
| `LAYOUT-002` | Every workflow has a `SKILL.md` | A workflow with no TTPs is a directory, not a workflow |
| `LAYOUT-003` | Every workflow has a `.claude/skills/<name>/` stub | Without it the workflow is unreachable by the Skill tool and will never be found at the moment of need |
| `LAYOUT-004` | Every application has `tasks.md` | Carried work has nowhere to land when a session closes |
| `LAYOUT-005` | Every application has `profile.md` | The operational picture is otherwise unrecorded and gets re-derived every session |
| `LAYOUT-006` | Every session is named `<date>-<slug>` | A bare date says nothing about what the session was, and two in one day collide |
| `LAYOUT-007` | No session that is exhausted **and** harvested remains on disk | The harvest law: `git log` is the archive. A session kept after harvest is a graveyard directory nothing will ever prune |
| `LAYOUT-008` | Every application `tasks.md` has both `## Open` and `## History` | The two things that outlive a session need a home before the session ends. `close` creates `## History` if it must; nothing creates `## Open`, so carried work promoted at the last moment is lost silently |

## TASK-* — `/workflow-orchestrate`

Task grammar and anti-cheat, inside each session. Reported by `orchestrate.sh check`
(aggregated) and `orchestrate.sh status <key>` (one session, in detail).

| ID | Constraint |
|----|------------|
| `TASK-001` | Every grammar and anti-cheat rule in `workflow-orchestrate/references/tasklist.md`: `accept:` on every task, `evidence:` for `[x]`, `agent:` for `[~]`, `blocked:` for `[!]`, `carried:` for `[^]`, `why:` **and** `signoff:` for `[-]`, no duplicate or malformed IDs, no dependency cycles, no task line outside `## Tasks`, a captured directive, and the harvest gate |
| `TASK-002` | At harvest, every `[-]` and `[^]` carries `landed:` — where the decision's rationale went. A refusal with a sign-off is a fact about the application; without a destination it dies with the session directory and the next session re-opens a settled question |

**An open session is not a violation.** Work in progress is the normal state. Only a
malformed or self-contradicting list is.

## SUBSTRATE-* — `/workflow-orchestrate`

Session identifiers escaping into bound substrate. Reported by `orchestrate.sh check`,
which scans standing binds whose `kind:` is `stewarded` or `co-change` and that are
present on disk under `binds.yaml`'s `base`. Skipped silently when `binds.yaml` or `yq` is
absent — a repo with no binds is complete, not degraded.

| ID | Constraint | Why it matters |
|----|------------|----------------|
| `SUBSTRATE-001` | A bound repo cites no session identifier: no task ID (`T` + 3 or more digits, word-bounded) and no workflow-repo session path (`.workflow/`, or `workflows/<workflow>/<app>/<session>/`) | The session directory is deleted at close, so every such citation is a dead reference by construction. Substrate cites its own repo's paths and facts. Reported as a summarized count with the worst files, never one line per hit; the count is textual and unverified, so a hash or a fixture can match — read each site before editing |

## TEMPLATE-* — `/workflow-template-sync`

Version drift against each upstream. Reported by `template-sync.sh --check`, which
contacts every upstream (core and packs) and exits 1 when anything is behind.

| ID | Constraint |
|----|------------|
| `TEMPLATE-*` | The core's `template_version` matches upstream `VERSION`, and every pack's installed version matches its upstream `pack.yaml` — or the thing is `pinned: true` and says so |

## PACK-* — `/workflow-template-sync`

Composition integrity. Reported by `template-sync.sh --audit`, which is **offline**: it
reads `.template.lock`, `packs.yaml`, `packs.lock`, and the disk. No upstream is
contacted, so it stays cheap and works with no network.

| ID | Constraint |
|----|------------|
| `PACK-001` | One owner per path. No path is claimed by both the core and a pack, or by two packs |
| `PACK-002` | Every path a pack's `packs.lock` entry claims is present in the repo |
| `PACK-003` | Declaration and installation agree: nothing installed that `packs.yaml` does not declare, nothing declared that was never installed |
| `PACK-004` | Every installed pack's `requires_core:` is still satisfied by this repo's core version |
| `PACK-005` | Every pack declared in `packs.yaml` has its overlay directory `.agents/<pack-name>/` |

**Why these five.** A collision (`PACK-001`) makes the winner depend on copy order,
which nobody can see or predict — it is the failure mode that sinks plugin systems, so it
is refused at install time *and* re-checked here in case a manifest changed under a repo.
`PACK-002` catches a half-applied update. `PACK-003` catches a hand-edited `packs.yaml`,
where files sit in the repo that nothing claims and nothing will ever update. `PACK-004`
catches the case `add` cannot: the requirement held at install time and stopped holding
afterwards, because the core was pinned or rolled back. A pack whose core requirement is
unmet does not fail loudly — it half-works, which is worse. `PACK-005` catches a pack
installed with no overlay directory: an overlay is the derivation's only answer to a
pack, and with nowhere to write one, the opinion that should have been overridden is
instead worked around inside a bound repo's own `AGENTS.md` — legal under bind law,
invisible to every other application, and never seen again.

**What is checked at install and not here.** `add` also runs
`/workflow-template-sync scan`, which refuses a pack claiming paths outside the four
allowed shapes, or containing credential reads, egress, pipe-to-shell, destructive
writes, or obfuscation. That is a gate, not a constraint: it runs once, on a pack that is
not yet part of the repo, and `--reviewed` waives it deliberately. Re-run it any time
with `scan <pack>`.

## Adding a constraint

1. **Find its owner.** The skill that defines the shape owns the check. If no skill owns
   the shape, the constraint is not ready — decide where the shape lives first.
2. **Implement it in the owner**, with a stable ID and a message that says what was
   broken *and why it matters*. A message that only names a missing file teaches nothing
   the next time it fires.
3. **Register it here.**
4. **Do not add it to `check.sh`.** The aggregator dispatches; it never checks.

Ask before adding: *if this constraint were violated right now, would anything notice?*
If the answer is no, that is the reason to add it. If the answer is "a person would spot
it in review", that is also no.
