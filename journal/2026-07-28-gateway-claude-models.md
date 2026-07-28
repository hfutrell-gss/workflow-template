# Gateway Claude Model Selection

Updated `workflow-gateway` so outer agents can launch Claude Code through OCX with explicit `--model` selection, streaming flags, and slash-command prompts via `claude-gw.sh`. Added `gateway.sh models` to print the routed Claude model IDs from Claude Code's gateway discovery cache, with a live gateway fallback.

`claude-gw.sh` now strips only the known OpenCode sentinel `ANTHROPIC_API_KEY=oauth-placeholder` before launching the inner Claude process, preventing it from overriding the user's existing `claude.ai` login. Verified `claude-ocx-native--gpt-5.6-sol` returns successfully through the wrapper; `claude-ocx-native--gpt-5.3-codex-spark` is discoverable but rejected by the current ChatGPT-backed route.
