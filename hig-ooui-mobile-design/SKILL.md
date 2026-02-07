---
name: hig-ooui-mobile-design
description: >-
  Design mobile apps using HIG-informed OOUI modeling and UI specification.
  Use when asked to create initial app designs, object models, task flows,
  navigation structures, wireframe instructions, or SwiftUI/Android component
  guidance for iOS, iPadOS, watchOS, or Android.
---

# HIG OOUI Mobile Design

## Overview
Use this skill to design mobile apps with OOUI modeling and Apple HIG constraints, then translate the model into screens, navigation, and component guidance. Produce a design doc, Figma wireframe instructions, and SwiftUI component notes, with Android deltas when requested.

## Workflow

### 1. Gather context and design direction
- Ask for target platforms, user types, core jobs, and constraints.
- If details are missing, assume a consumer app, iPhone-first, and a single primary job.
- If the user asks for "all platforms," treat iOS (iPhone) as the baseline and add platform deltas using `references/platform-variants.md`.
- **Design direction**: Clarify the app's tone and aesthetic intent (refined, playful, utilitarian, editorial, geometric, etc.). Commit to a clear direction early—see `references/visual-aesthetics.md` for guidance.

### 2. Build the OOUI model
- Identify primary objects, supporting objects, and system objects.
- Define attributes, actions, states, and relationships.
- Use `references/ooui-model.md` for templates and mapping guidance.

### 3. Derive tasks and flows
- Convert objects and actions into primary and secondary task flows.
- Add edge cases: empty state, errors, first-run.
- Use the task-flow template in `references/ooui-model.md`.

### 4. Define navigation and information architecture
- Group objects into logical sections and entry points.
- Choose navigation patterns per platform, then note any cross-platform conflicts.
- Validate choices against `references/hig-checklist.md` and `references/platform-variants.md`.

### 5. Compose screens with HIG constraints and visual aesthetics
- Design screens around object views and actions.
- Apply layout, typography, touch-target, and accessibility checks from `references/hig-checklist.md`.
- Apply visual aesthetics from `references/visual-aesthetics.md` to create distinctive, memorable interfaces that match the design direction.

### 6. Produce deliverables
- Use `references/output-templates.md` to output:
  - Design document
  - Figma wireframe instructions
  - SwiftUI component mapping
  - Android deltas (only when Android is included)

---

## Visual Aesthetics
Create interfaces that feel intentionally designed, not generically styled. Refer to `references/visual-aesthetics.md` for:

- **Typography**: Use platform fonts (SF Pro, New York) with character; pair with custom display fonts when brand calls for it.
- **Color**: Commit to a cohesive palette using HIG dynamic colors as a foundation. Dominant colors with sharp accents outperform timid palettes.
- **Motion**: Use animation for hierarchy and delight, always respecting Reduce Motion settings.
- **Spatial composition**: Use generous spacing or controlled density; allow intentional grid-breaking for emphasis.
- **Anti-patterns**: Avoid generic gradients, overused fonts (Inter, Roboto for everything), and cookie-cutter component patterns that signal "AI slop."

---

## Quality Gates
- Ensure every primary object has a clear home, detail view, and primary actions.
- Confirm navigation is consistent with platform HIG guidance.
- Verify accessibility, empty states, and error handling exist for each flow.
- Validate visual design matches the committed aesthetic direction and avoids anti-patterns.

## 他スキルとの連携

- **ios-development**: 本スキルで設計 → 実装パターン適用
- **appium-simulator-test**: デザイン検証テスト

## Resources
- `references/ooui-model.md`
- `references/hig-checklist.md`
- `references/platform-variants.md`
- `references/output-templates.md`
- `references/visual-aesthetics.md`
- `references/liquid-glass.md` ← iOS 26 Liquid Glass対応

