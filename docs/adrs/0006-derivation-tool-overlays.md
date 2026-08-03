# ADR-0006: Derivation-owned tool overlays for workflow-init

**Status:** Accepted
**Date:** 2026-07-30
**Authors:** henning
**Deciders:** henning

**Scope (repos affected):**

- `workflow-template` — the core itself
- every derivation — receives this through the managed set

---

Template v18 → v19. `workflow-init` VERSION 4 → 5.

## What prompted it

Setting up NDepend and its MCP server for .NET work. The first attempt put `ndepend`
straight into the template's `init.sh` and shipped a `craft-static-analysis` skill
alongside it. Wrong: NDepend is one area of work's tool, not something every derivation
needs. Reverted the template clean and moved the whole stack into a new
`workflow-monolith` derivation.

Which immediately exposed a real gap. **A derivation had no legitimate way to install a
tool.** `init.sh` is managed, so adding a tool there gets overwritten by `update`; and the
categorical rule forbids hand-rolling a parallel installer for a template concept, which
tool installation plainly is (tiers, per-machine decisions, `init.lock`). Both available
options violated doctrine. That is a missing shape, not a missing tool.

## The shape

`.agents/init/tools.local.d/<tool>.sh` — unmanaged, sourced by `init.sh` at startup. Each
file defines `check_<tool>()`, `install_<tool>()`, optionally
`unsupported_reason_<tool>()`, and calls `register_tool <tool>`. The same overlay bargain
already serving `.agents/craft/<skill>.local.md` and
`.agents/orchestrate/roster.local.yaml`: template owns the shape, derivation owns the
data. An annotated `example-tool.sh.example` ships next to it, mirroring the
`roster.local.yaml.example` precedent.

Three deliberate constraints:

- **Overlay tools are always RECOMMENDED.** A derivation cannot make its own tool
  mandatory — `--check` failing on a tool the template never heard of would make the
  constitution's own init mandate unsatisfiable for anyone lacking it.
- **A registered tool missing `check_`/`install_` is a hard error at startup**, so a
  half-written overlay fails loudly instead of mysteriously mid-install.
- **`register_tool` refuses a REQUIRED tool's name.** Silently shadowing `git` or `yq`
  would be a spectacular way for a derivation to break its own bootstrap.

`cmd_decide` now validates against the `RECOMMENDED` array instead of a hardcoded
`obsidian|codegraph|opencodex` case list, which is what makes overlay tools decidable.

Purely additive: with no overlay directory, v5 behaves exactly as v4 did. Verified.

## Platform-limited tools — a new carve-out

`init.lock` decisions travel between machines, but tool viability does not. NDepend is
Windows-only (a Developer license activates only on Windows), so without special handling
one `decide ndepend install` would make `--check` fail **forever** on every pure-Linux
machine sharing that decision.

So: a tool decided `install` on a machine that cannot host it is **not drift**. The
decision is honored as far as the machine allows and the shortfall prints as a `NOTE`, in
both a plain run and `--check`. Opt in per tool with `unsupported_reason_<tool>()`.
Surface, don't suppress — but don't manufacture failures either.

## Also added: MCP server doctrine

A short `AGENTS.CORE.md` section, because a derivation-owned `.mcp.json` has one
non-obvious failure mode worth writing down. Registrations must contain **no
machine-specific paths** — point `command` at a fixed `${HOME}/.local/bin/<name>` wrapper
that the tool's installer generates, and let the wrapper carry the variable parts,
including any working directory the server needs. Earned the hard way: a Windows MCP
server launched from a Linux working directory it could not express came up, printed its
startup banner, and then died without ever answering `initialize` — no error on either
side, just silence. And a server whose backing tool was never opted into showing as
unconnected in `/mcp` is the intended resting state, not an error to chase.

## Not managed, deliberately

Neither `.agents/init/tools.local.d/` nor `.mcp.json` is in `template-manifest.yaml`. Both
are derivation data. A derivation receives the `.example` at derive time and owns it from
there, exactly like the orchestrate roster example.

## Session binds

None. Template-only change; the NDepend work lives in `workflow-monolith`.
