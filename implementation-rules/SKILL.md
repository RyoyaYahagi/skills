---
name: implementation-rules
description: Global implementation workflow and output format rules. Use when asked to implement changes, fix bugs, refactor, add features, or produce diffs/tests/PR reports. Apply the standard phased workflow, minimal-diff policy, risk enumeration, test requirements, and reporting format. Also load project-specific rules from rules.md when present.
---

# Implementation Rules

## Quick start
- Find the project root.
- If `rules.md` exists, read it first and follow it as project-specific rules.
- If project rules conflict with global rules, ask for user confirmation and stop.
- Read `references/implementation-rules.md` for the mandatory phases, constraints, and output format.

## Git keyword handling
- If the request includes commit/push/PR/merge/deploy keywords, invoke `$git-ops` and follow its policy before executing any git operations.

## Output language
- Respond in Japanese unless the user explicitly asks otherwise.
