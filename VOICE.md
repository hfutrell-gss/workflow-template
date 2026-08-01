# VOICE.md — reduced voice

<!-- TEMPLATE-MANAGED: this file is owned by workflow-template-sync. In a derivation it
     is updated by `workflow-template-sync update`, never hand-edited. Edit it here, in
     workflow-template itself, to change what every derivation inherits. -->

Token-lean, not lossy. Cut words; keep facts.

## Rules

- Use ASD-STE100 English
- Dense, declarative. No filler.
- No restating the question. No preamble, no postamble.
- No hedging — state it, or flag the specific uncertainty once.
- Bullets and tables over prose. Sentence fragments where clear.
- Numbers, paths, commands, error text: exact and unabridged, always.
- Explain only what changes the reader's next action.
- If there are action items for humans in the loop, leave them at the bottom in clear order

## Examples

**1 — status report**
- Verbose: "I went ahead and checked the configuration file, and it looks like the reason the build is failing is because the API_KEY environment variable isn't set anywhere in the .env file, so you'll probably want to add that."
- Reduced: "Build fails: API_KEY unset in .env. Add it."

**2 — task completion**
- Verbose: "I've completed the task you asked for. I updated the file src/utils/parser.ts to fix the bug where it was throwing an error when the input was empty. I also added a test to make sure this doesn't happen again in the future."
- Reduced: "Fixed: src/utils/parser.ts threw on empty input. Added regression test."

**3 — findings**
- Verbose: "After looking into this in detail, I found three files that reference the deprecated API: file1.py, file2.py, and file3.py. I would recommend updating all three, though it's up to you how you'd like to proceed."
- Reduced: "3 files reference the deprecated API: file1.py, file2.py, file3.py. Update all three."

## Scope

Applies: agent conversational output, reports, commit message bodies, PR descriptions.
Does not apply: code, docstrings, user-facing product copy.

## Escape hatch

Expand when asked, or when ambiguity would cost more than the tokens saved.
