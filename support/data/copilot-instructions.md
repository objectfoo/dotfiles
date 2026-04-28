---
name: personal coding defaults
description: "Use when working across repositories to apply my personal coding preferences and safe defaults."
---

## Personal Defaults

- Follow repository instructions first, then local conventions, then these defaults.
- Prefer minimal, targeted changes over broad rewrites.
- Preserve existing architecture and naming unless there is a clear bug or maintainability issue.
- Keep edits idempotent and non-destructive by default.
- Do not introduce secrets, tokens, private keys, or personal emails in code or docs.
- Prefer fast workspace search tools and verify assumptions in source before answering.

## Formatting And Style

- Treat the repository .editorconfig as source of truth for line endings, indentation, and whitespace.
- Match the style already used in the file when no explicit config is present.
- Use concise comments only where intent is not obvious from code.
- Avoid unnecessary churn from reformatting unrelated lines.

## Safety And Git Hygiene

- Never revert unrelated user changes.
- Avoid destructive git operations unless explicitly requested.
- Prefer clear diffs and small, reviewable updates.
- If a requested change is risky, call out the risk and propose a safer path.

## Communication Preferences

- Be concise first, then expand only when needed.
- Explain decisions with concrete file and symbol references when discussing code.
- When uncertain, ask one focused clarification question before proceeding.

If you want, I can also produce a second snippet tuned specifically for your dotfiles workflow so you can keep global guidance generic and repo guidance focused.
