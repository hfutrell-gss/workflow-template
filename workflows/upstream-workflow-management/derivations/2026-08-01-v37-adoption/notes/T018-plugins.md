# T018 — plugin marketplace survey (`claude-plugins-official`)

Read-only. No `plugins.yaml` written, no `.claude/settings.json` touched, nothing
installed. Source read at
`/home/henning/.claude/plugins/marketplaces/claude-plugins-official`,
`.claude-plugin/marketplace.json`, lastUpdated 2026-08-01T21:29:23Z.

## 1. Inventory

Marketplace lists **276 plugins** total (`marketplace.json`, `.plugins[]`).

Only a subset is actually vendored on this disk — code present, readable, reviewable:

| Where | Count | What |
|---|---|---|
| `./plugins/*` | 38 | Anthropic first-party — skills, agents, commands, hooks, LSP configs |
| `./external_plugins/*` | 15 | community/vendor bridges Anthropic vendors in-repo — mostly MCP-only |
| **On disk, reviewable** | **53** | |
| Everything else | **223** | `source` is a `url`/`git-subdir` pointing at a third-party repo. **Not fetched into this checkout.** No code to read until `/plugin install` clones it. |

**Finding, not reassurance:** 223 of 276 marketplace entries (81%) cannot be reviewed
from this machine's disk at all — Airtable, Auth0, every `aws-*`, Atlassian, Cloudflare,
Databricks, and so on. Their `sha` is pinned in the manifest but the tree it points to
is unfetched. "Read what it executes before installing" is not optional for these —
it is currently *impossible* without installing, which is the exact moment the skill
says review must already be done. Anyone declaring one of these 223 must `git clone`
the pinned ref out-of-band and read it before writing a `reviewed:` block; this survey
did not do that for any of them.

One further oddity: `plugins/example-plugin` exists on disk (skills, commands, an
`.mcp.json` pointing at `https://mcp.example.com/api`) but is **absent from
`marketplace.json`'s plugin list** — not something `/plugin install` can reach. Dev
scaffold left in the tree, not a real offering.

### The 53 on-disk, by what they provide

**First-party, `./plugins/*` (38):**

| Plugin | Version | Provides |
|---|---|---|
| agent-sdk-dev | - | agents, commands |
| clangd-lsp | 1.0.0 | LSP server config (clangd, C/C++) |
| claude-code-setup | 1.0.0 | skills |
| claude-md-management | 1.0.0 | commands, skills |
| claude-security | 0.10.0 | agents, skills, **hooks** |
| code-modernization | - | agents, commands, workflow scripts (.js) |
| code-review | - | commands |
| code-simplifier | 1.0.0 | agents |
| commit-commands | - | commands |
| csharp-lsp | 1.0.0 | LSP server config (csharp-ls) |
| cwc-makers | 1.0.0 | commands, skills |
| explanatory-output-style | 1.0.0 | **hooks** (output-style installer) |
| feature-dev | - | agents, commands |
| frontend-design | - | skills |
| gopls-lsp | 1.0.0 | LSP server config (gopls, Go) |
| hookify | - | skills, agents, commands, **hooks** (user-authored hook framework) |
| jdtls-lsp | 1.0.0 | LSP server config (jdtls, Java) |
| kotlin-lsp | 1.0.0 | LSP server config |
| learning-output-style | 1.0.0 | **hooks** (output-style installer) |
| lua-lsp | 1.0.0 | LSP server config |
| math-olympiad | - | skills, scripts |
| mcp-server-dev | - | skills |
| mcp-tunnels | - | commands (Docker/Cloudflare tunnel setup walkthrough) |
| php-lsp | 1.0.0 | LSP server config |
| playground | - | skills |
| plugin-dev | - | skills, agents, commands (example hook scripts, not live hooks) |
| project-artifact | - | skills |
| pr-review-toolkit | - | agents, commands |
| pyright-lsp | 1.0.0 | LSP server config (Python) |
| ralph-loop | 1.0.0 | commands, **hooks** |
| receipts | - | skills |
| ruby-lsp | 1.0.0 | LSP server config |
| rust-analyzer-lsp | 1.0.0 | LSP server config |
| security-guidance | 2.0.6 | **hooks** (pattern + agentic LLM review) |
| session-report | - | skills |
| skill-creator | - | skills, scripts (eval/benchmark tooling) |
| swift-lsp | 1.0.0 | LSP server config |
| typescript-lsp | 1.0.0 | LSP server config |

**Vendored bridges/integrations, `./external_plugins/*` (15), all MCP:**

asana, context7, discord, fakechat, firebase, github, gitlab, greptile, imessage,
laravel-boost, linear, playwright, serena, telegram, terraform — versions mostly
unstated in `plugin.json` except discord 0.0.4, fakechat 0.0.1, imessage 0.1.0,
telegram 0.0.6.

## 2. Review — hooks first, then egress, then credentials

Per the skill's order. `none` written explicitly wherever there is none.

### Plugins that register a hook (6 of 53 — the only ones that run unasked)

**`security-guidance` v2.0.6 — the deepest hook footprint of anything on this disk**
- hooks: `SessionStart` (bash, **180s** timeout, bootstraps a Python venv for an
  "agent SDK"), `UserPromptSubmit` (pattern-based reminder, no declared timeout),
  `PostToolUse` matcher `Edit|Write|MultiEdit|NotebookEdit` (same reminder) **and**
  matcher `Bash` conditioned on `git commit:*` / `git push:*` / `gt create:*` /
  `gt submit:*` (async-rewake agentic review), `Stop` (async-rewake background review).
- egress: talks directly to `https://api.anthropic.com` (overridable via
  `ANTHROPIC_BASE_URL`) via `urllib.request` in `hooks/llm.py`, and separately spawns
  an inner `claude` CLI subprocess for the agentic two-stage (investigate →
  self-refute) commit review. Real, unprompted network calls on `git commit`/`git
  push`.
- credentials: `ANTHROPIC_API_KEY` or `ANTHROPIC_AUTH_TOKEN` (falls back between
  them), `CLAUDE_CODE_EXECPATH`, `CLAUDE_CONFIG_DIR`, plus tuning env vars
  (`SG_AGENTIC_*`, `SECURITY_REVIEW_MODEL`, `DIFF_PER_FILE_BYTES`,
  `DIFF_TOTAL_BYTES`, `SG_DUAL_OR`). All read from the ambient environment, none
  logged to disk that this review found.

**`hookify` — a hook-authoring framework, not just a hook**
- hooks: `PreToolUse`, `PostToolUse`, `Stop`, `UserPromptSubmit`, each `python3
  <script>` at **10s** timeout.
- What it actually does: reads user-authored `.local.md` rule files and dynamically
  wires *their* matchers and commands into these four events. The plugin's own code
  is a dispatcher; the executable surface is whatever the user (or a repo they
  didn't fully read) puts in a `.local.md` file. Installing this plugin means every
  future `.local.md` anyone adds runs unreviewed by this process, on every matching
  tool call, in every project where it's active — install it once and the review
  burden becomes permanent and delegated to whoever writes the next rule file.
- egress: `none` found in the plugin's own code.
- credentials: `none` found; reads `CLAUDE_PLUGIN_ROOT` only.

**`claude-security` v0.10.0**
- hooks: `UserPromptExpansion`, matcher `^claude-security:claude-security$` only —
  a display-only banner (prints a systemMessage), no permission decision, no
  timeout declared.
- egress: `none` in the hook itself. The actual scan (its stated purpose) runs as
  agents/commands *inside the calling session* — it rides the session's own model
  calls rather than opening a separate connection. Its own docs recommend running
  the whole session inside `sandbox-runtime` when scanning code you don't trust.
- credentials: `none` beyond what the ambient Claude Code session already has.

**`explanatory-output-style` v1.0.0 / `learning-output-style` v1.0.0**
- hooks: `SessionStart`, `bash hooks-handlers/session-start.sh`, no declared
  timeout, in both.
- egress: `none`. credentials: `none`. Installs an output-style instruction set at
  session start; no code executes beyond writing that instruction.

**`ralph-loop` v1.0.0**
- hooks: `Stop`, no declared timeout.
- What it does: reads `.claude/ralph-loop.local.md` (project-scoped state), parses
  the transcript for a `<promise>` tag, and blocks session exit to re-feed the same
  prompt if the promise isn't met — self-contained loop control, no external calls.
- egress: `none`. credentials: `none`.

### The other 47 on-disk plugins

- **12 LSP plugins** (clangd, csharp, gopls, jdtls, kotlin, lua, php, pyright, ruby,
  rust-analyzer, swift, typescript): hooks: none. egress: none beyond spawning the
  named local language-server binary the user already has on `PATH`. credentials:
  none.
- **Remaining first-party skill/agent/command plugins** (agent-sdk-dev,
  claude-code-setup, claude-md-management, code-modernization, code-review,
  code-simplifier, commit-commands, cwc-makers, feature-dev, frontend-design,
  math-olympiad, mcp-server-dev, mcp-tunnels, plugin-dev, playground,
  project-artifact, pr-review-toolkit, receipts, session-report, skill-creator):
  hooks: none. egress: none found in their scripts (`code-modernization`'s
  `workflows/*.js` and `skill-creator`'s eval scripts run locally, invoked only by
  an explicit slash command, never automatically). credentials: none found.
  `mcp-tunnels` is a guided walkthrough for standing up your *own* tunnel — it does
  not itself open one.

### MCP-only bridges (`external_plugins/*`, 15) — egress and credentials, no hooks

None of these register a hook. Grouped by what the manifest exposes:

| Plugin | Egress | Credentials |
|---|---|---|
| github | `https://api.githubcopilot.com/mcp/` | `GITHUB_PERSONAL_ACCESS_TOKEN` in `Authorization: Bearer` header |
| greptile | `https://api.greptile.com/mcp` | `GREPTILE_API_KEY` in `Authorization: Bearer` header |
| terraform | Docker container -> HashiCorp's `terraform-mcp-server` | `TFE_TOKEN` passed into container env |
| asana | `https://mcp.asana.com/sse` | none in manifest — OAuth presumed at connect time, not visible on disk |
| gitlab | `https://gitlab.com/api/v4/mcp` | none in manifest — same caveat |
| linear | `https://mcp.linear.app/mcp` | none in manifest — same caveat |
| discord | local `bun` process -> Discord API | `DISCORD_BOT_TOKEN` (read from `~/.claude/channels/discord/.env`); server.ts confirmed reading it directly |
| telegram | local `bun` process -> `api.telegram.org` | `TELEGRAM_BOT_TOKEN` (same `.env` pattern); server.ts confirmed |
| imessage | **none** — local only, `spawnSync('osascript', ...)` drives Messages.app | none; reads the local `~/Library/Messages/chat.db` directly — a sensitive local file, not a network credential |
| fakechat | local-only HTTP test server (`localhost:8787`) | none |
| context7 | `npx @upstash/context7-mcp` — reaches npm registry to fetch the package, then whatever that package calls (not vendored here) | not determined — package not on disk |
| firebase | `npx firebase-tools@latest mcp` — same npm-fetch-at-runtime pattern | Firebase auth, handled by `firebase-tools` itself, not visible here |
| laravel-boost | `php artisan boost:mcp` — runs inside the user's own Laravel app | none beyond that app's own config |
| playwright | `npx @playwright/mcp@latest` — npm-fetch-at-runtime | none |
| serena | `uvx --from git+https://github.com/oraios/serena serena start-mcp-server` — pulls and runs code straight from a GitHub ref at every invocation | none in the manifest |

**Finding:** five of these (context7, firebase, laravel-boost, playwright, serena)
resolve to code that is fetched fresh over the network at run time and never lands
in this checkout — `npx`/`uvx` pull current `@latest` or a live git ref on every
launch. Their manifest is reviewable; their actual behavior is not fixed at any
`reviewed:` date, because the package resolved by `@latest` (or `serena`'s tracked
git branch) can change between two sessions without this repo's knowledge. A
`reviewed:` block naming a version for these is only true at the moment it's
written.

## 3. Recommendation per workflow repo

- **workflow-template** (core itself): **none.** The template's job is composing
  packs and shapes for every derivation; a plugin declared here would be inherited
  by every derivation whether or not their area of work wants it, which is exactly
  the guess-on-behalf-of-someone-else the skill exists to avoid. No plugin surveyed
  answers a need specific to *maintaining the core*.
- **stewardship** (GSS substrate stewardship): none of the 53 reviewed fit cleanly.
  `github`/`gitlab` MCP bridges are plausible *if* stewardship's actual PR/issue
  workflow already lives on GitHub/GitLab — but that's a fact about the specific
  substrate repos bound here, not established by this survey, and both carry
  standing credentials (`GITHUB_PERSONAL_ACCESS_TOKEN`) with no expiry/scope visible
  from the manifest. Worth a follow-up question to whoever binds stewardship's
  substrate, not a default-on recommendation from this survey.
- **workflow-monolith** (.NET codebase understanding/measurement/safe change):
  `csharp-lsp` is a direct, low-risk fit — no hooks, no egress, no credentials,
  just a local language-server spawn for the exact language this repo's substrate
  is written in. `code-modernization` is closer to interesting than clearly
  warranted: its stated scope (COBOL, legacy Java/C++, monolith web apps, .NET
  Framework -> .NET 8/10 via the separate `aws-transform` entry) overlaps the area
  of work, but it ships six workflow scripts this survey read only for
  hooks/egress/credentials, not for whether its opinions match this repo's own —
  that's a design read, not a security read, and belongs to whoever owns this
  workflow's doctrine, not this task.
- **sandbox** (scratch derivation): **none.** A scratch repo has no standing area
  of work a plugin default should track; anything installed here is by definition
  a one-off, better done with `/plugin install` for the session than declared as a
  repo default nobody else inherits.

## 4. The pack-vs-plugin boundary, by the "would we send a PR" test

- **`csharp-lsp` / any LSP plugin**: no — these are vendor language servers wrapping
  a third-party binary already on `PATH`. We'd never PR clangd or gopls. **Plugin**,
  cleanly.
- **`security-guidance`, `claude-security`, `hookify`**: no — each is somebody else's
  product on its own release cadence (Anthropic's own, in the first two cases, but
  still not this repo's opinion to correct via PR against *this* codebase).
  **Plugin.**
- **`github`/`gitlab`/`linear`/`asana` MCP bridges**: no — thin wrappers around a
  SaaS API contract this repo doesn't control. **Plugin.**
- **The workflow-plugins skill's own machinery** (`plugins.sh`, the `plugins.yaml`
  schema, the render/check logic): **yes** — this repo would send a PR to change how
  its own plugin registry works. That's why it lives in `.agents/skills/` as a
  **pack**-owned shape (core machinery), never as a plugin. The line the skill draws
  is exactly this one: the registry that governs plugins is a pack; nothing a
  marketplace lists is ever eligible to *be* the registry.

None of the 53 reviewed plugins sit ambiguously on this line — every one is clearly
someone else's product on their own cadence, and none proposes to change this
system's own behavior.

## 5. Closing

Whether any of these gets declared is the user's call, not this survey's. Nothing
here was installed and no `plugins.yaml` was written — an empty or premature
registry is worse than no registry, because `plugins.sh check` and every derivation
that reads `plugins.yaml` would treat a hastily-declared, thin `reviewed:` block as
settled fact. A repo with no `plugins.yaml` is a complete state, not a degraded one,
and stays that way until someone with an actual need reads one of the entries above
in full and writes what they found.
