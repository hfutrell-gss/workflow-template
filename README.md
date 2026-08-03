# workflow-template

The **core** that every workflow repo derives from and stays linked to for the life of its
project. It provides what a derivation gets on day one: managed law (`AGENTS.CORE.md`), the
operator's manual (`README.CORE.md`), a package of `workflow-*` machinery skills, and a live
link back upstream so improvements flow forward.

> **How a workflow repo works is documented in [`README.CORE.md`](README.CORE.md)** — layout,
> skills, packs, overlay slots, tooling, binds, orchestration, staying current. That file is
> managed, so every derivation receives it and none has to re-document it. This README covers
> only what is specific to *being the template*.

A workflow repo captures the techniques, tactics, procedures, and doctrine for one area of
work. Code repos are **substrate** — operated *on*, not *in*.

## The covenant

**The template facilitates, never constrains.** A derivation owns everything outside the
managed set (`template-manifest.yaml` is the exact list): its own doctrine, its `README.md`,
its `binds.yaml`, its workflows, its own skills, its `journal/`, anything it adds later.

It can pin its core (`pinned: true` in `.template.lock`) to freeze it, or eject entirely
(delete `.template.lock`). Either is supported for the full lifetime of the project it belongs
to.

## Deriving a new workflow

Clone from the remote, so the derivation carries a live link to the real upstream rather than
a local path:

```sh
git clone git@github-gss:GlobalShopSolutionsR-D/workflow-template.git ~/workflows/<new>
cd ~/workflows/<new>
.agents/skills/workflow-template-sync/template-sync.sh derive \
  --upstream git@github-gss:GlobalShopSolutionsR-D/workflow-template.git
```

`derive` asks nothing: it writes `.template.lock` (recording `template_version`, `upstream`,
`derived`, `pinned: false`), clears template-only example content, and drops the root
`VERSION` file — that describes the *template's* version, not a derivation's. It never touches
`AGENTS.md`; that skeleton is left for you on purpose.

Then, in order:

1. Write the area of work, responsibilities, and conditions into `AGENTS.md`.
2. Rewrite `README.md` as that repo's own front door — its area of work, not the mechanics
   (`README.CORE.md` already carries those).
3. Populate `binds.yaml` as real substrate appears. An empty registry is a complete repo.
4. Add `playbooks/` and start `journal/` as procedures and decisions stabilize.

Workflows come later, one per campaign, when a campaign is about to run.

## What is managed, and what that means here

`template-manifest.yaml` lists the paths the core owns in every derivation. Two consequences
that matter when working *in this repo*:

- **Editing a managed file here is a release**, not a local change: it lands in every
  derivation on its next `update`. Bump `VERSION` and the manifest's `version:` together, and
  write the reasoning into the commit body — that is the only place it is recorded.
- **Removing a path from `managed:` deletes it from every derivation** on the next update. A
  derivation's own copy of the manifest is the record of what the core previously owned, which
  is what makes the dropped-path diff computable.

`VERSION` is a plain integer; comparison is `sort -n`.

## Packs this system publishes

The core ships only mechanism. Engineering opinion is a pack, because a workflow repo that
wants none of it should be able to decline.

| Pack | What it carries |
|------|-----------------|
| `code-craft` | `/code-craft-tdd`, `/code-craft-quality`, `/code-craft-event-naming`, `/code-craft-ubiquitous-language` — engineering doctrine for work done *on* substrate |

`craft-*` was once 40% of the core by size and none of it was mechanism, which is why it left.
Pack mechanics, the four shapes a pack may claim, and the trust model: `README.CORE.md`.

## This repo's own workflows

The core is a workflow repo too, and it runs its own campaigns under `workflows/` — currently
`upstream-workflow-management`, which is also shipped to every derivation as a managed
workflow.
