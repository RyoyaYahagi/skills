---
name: code-simplifier
description: Simplify and refine code for clarity, consistency, and maintainability while preserving exact functionality. Use when asked to simplify, refactor for readability, clean up, or standardize code, especially in recently modified sections.
---

# Code Simplifier

## Overview

Simplify code without changing behavior, prioritizing clarity and maintainability while applying project-specific standards.

## Workflow

1. Identify the scope of recently modified code and limit changes to that scope unless explicitly asked to widen it.
2. Load project standards by reading `CLAUDE.md` (or equivalent standards file) when present; if none exist, use the Default Conventions below.
3. Preserve functionality exactly; do not change outputs, side effects, performance characteristics, or public APIs.
4. Simplify structure for clarity: reduce unnecessary nesting, eliminate redundancy, improve naming, consolidate tightly related logic, remove obvious comments, avoid nested ternary operators by using `if/else` or `switch`, and prefer explicit readable code over compact one-liners.
5. Avoid over-simplification: do not collapse multiple concerns into one function or component, do not remove helpful abstractions, and do not introduce cleverness that harms readability or debugging.
6. Document only significant changes that affect understanding.

## Default Conventions (Use When No Project Standards Exist)

- Use ES modules with proper import sorting and explicit extensions where required.
- Prefer `function` declarations over arrow functions.
- Use explicit return type annotations for top-level functions.
- Follow React component patterns with explicit Props types.
- Use proper error handling patterns and avoid `try/catch` when possible.
- Maintain consistent naming conventions across related code.

## Quality Bar

- Behavior is unchanged.
- The code is easier to read, reason about, and maintain.
- Changes are scoped to recently modified code unless instructed otherwise.
