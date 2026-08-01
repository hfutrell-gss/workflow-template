# T013 — static-analysis SKILL.md: craft-* rename after v37

Target: `/home/henning/workflows/workflow-monolith/.agents/skills/static-analysis/SKILL.md`

## Grep before (stale references)

```
$ cd /home/henning/workflows/workflow-monolith && grep -n 'craft-code-quality\|craft-tdd\|\.agents/craft/' .agents/skills/static-analysis/SKILL.md
25:   `.agents/craft/static-analysis.local.md` exists, read it; where it conflicts with this
32:## Relationship to `/craft-code-quality`
36:| | `/craft-code-quality` | this skill |
43:`/craft-code-quality` owns the budgets and the ratchet — **do not redefine LOC limits,
45:[craft-code-quality's loc-budgets reference](../craft-code-quality/references/loc-budgets.md)
51:Same distinction, same reason as `/craft-code-quality`:
67:| TypeScript / JS | `dependency-cruiser`, `ts-prune`, `knip` | see `/craft-code-quality` `references/enforcement.md` |
112:   `/craft-code-quality` demands of every enforced rule.
122:  technique, and the same trap `/craft-code-quality`'s ratchet warns about.
127:  destination in `/craft-code-quality`. A ratchet nobody can see the position of is not a
139:- Separate ENFORCED from REVIEW findings, exactly as `/craft-code-quality` requires. If a
151:- The remaining gap to `/craft-code-quality`'s budgets is stated.
```

No bare `craft-tdd` reference was present in this file. No "reserved prefix" assertion
about `craft-*` was present in this file either (that claim, if it exists, lives
elsewhere — not touched here).

## Edits made

- `/craft-code-quality` -> `/code-craft-quality` (all 10 occurrences: lines 32, 36, 43,
  45 (prose + link text), 51, 67, 112, 122, 127, 139, 151)
- `.agents/craft/static-analysis.local.md` -> `.agents/code-craft/static-analysis.local.md`
  (line 25)
- Relative link target: `../craft-code-quality/references/loc-budgets.md` ->
  `../code-craft-quality/references/loc-budgets.md` (line 45)

Doctrine, structure, and prose otherwise unchanged — only names/paths.

## Grep after (zero stale references, exit 1 = no match)

```
$ grep -n 'craft-code-quality\|craft-tdd\|\.agents/craft/' .agents/skills/static-analysis/SKILL.md
exit: 1
```

## Link resolution proof

```
$ cd .agents/skills/static-analysis && ls -l ../code-craft-quality/references/loc-budgets.md
-rw-r--r-- 1 henning henning 6883 Aug  1 16:39 ../code-craft-quality/references/loc-budgets.md
```

Resolves. No other relative link in the file was changed (the `references/ndepend.md`
link is internal to this skill's own `references/` dir, unaffected by the rename).

## Journal untouched

`journal/2026-07-30-derived-and-ndepend.md` was not read for editing purposes beyond
this task's scope, and is absent from the diff:

```
$ /usr/bin/git status --porcelain
 M .agents/skills/static-analysis/SKILL.md
```

Only the target file changed.

## Commit

```
$ /usr/bin/git add .agents/skills/static-analysis/SKILL.md
$ /usr/bin/git commit -m "static-analysis: fix stale craft-* references after v37 rename ..."
[main d563ce6] static-analysis: fix stale craft-* references after v37 rename
 1 file changed, 12 insertions(+), 12 deletions(-)
```

**Commit SHA:** `d563ce63852fbd34f16c45422acbfcd01ff301d6`

Not pushed.

## Found but not rewritten

Nothing factually wrong beyond the renamed names was found in this file. No
"`craft-*` is a reserved prefix" claim appears in `static-analysis/SKILL.md` — that
assertion, if present anywhere in this derivation, lives outside this file's scope and
was not touched.
