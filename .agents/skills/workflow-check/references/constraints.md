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
| `LAYOUT-007` | No session that is exhausted **and** harvested remains on disk | The harvest law: `git log` is the archive. This is the graveyard rule, and the template itself broke it for ten versions before anything checked |

## TASK-* — `/workflow-orchestrate`

Task grammar and anti-cheat, inside each session. Reported by `orchestrate.sh check`
(aggregated) and `orchestrate.sh status <key>` (one session, in detail).

| ID | Constraint |
|----|------------|
| `TASK-001` | Every grammar and anti-cheat rule in `workflow-orchestrate/references/tasklist.md`: `accept:` on every task, `evidence:` for `[x]`, `agent:` for `[~]`, `blocked:` for `[!]`, `carried:` for `[^]`, `why:` **and** `signoff:` for `[-]`, no duplicate or malformed IDs, no dependency cycles, no task line outside `## Tasks`, a captured directive, and the harvest gate |

**An open session is not a violation.** Work in progress is the normal state. Only a
malformed or self-contradicting list is.

## TEMPLATE-* — `/workflow-template-sync`

The managed set against upstream. Reported by `template-sync.sh --check`.

| ID | Constraint |
|----|------------|
| `TEMPLATE-*` | `template_version` matches upstream `VERSION`, or the derivation is `pinned: true` and says so |

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
