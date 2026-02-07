# Visual Aesthetics Guide (Mobile)

Create interfaces that feel intentionally designed—distinctive and memorable while respecting platform conventions.

## Design Direction
Before visual work begins, commit to a clear aesthetic intent:
- **Purpose**: What problem does this interface solve? Who uses it?
- **Tone**: Choose a direction—refined minimal, playful, utilitarian, editorial, organic, geometric, soft/pastel, industrial, etc.
- **Differentiation**: What makes this app unforgettable? What's the one element users will remember?

**Key principle**: Bold maximalism and refined minimalism both work. The key is intentionality, not intensity.

---

## Typography
- **System fonts first**: SF Pro, SF Compact (watchOS), New York provide excellent readability and dynamic type support.
- **Display accents**: Pair system fonts with a distinctive display font for headers when brand expression calls for it.
- **Hierarchy**: Use weight and size to create clear visual hierarchy. Avoid more than 3 type sizes per screen.
- **Dynamic type**: Always support dynamic type scaling for accessibility.

### Avoid
- Generic cross-platform fonts (Arial, Helvetica) that ignore platform identity.
- Too many font families—stick to 1–2 maximum.

---

## Color & Theme
- **Dynamic colors**: Build on HIG dynamic colors (system backgrounds, labels, fills) for automatic light/dark adaptation.
- **Palette commitment**: Choose a dominant brand color with sharp accents. Avoid timid, evenly-distributed palettes.
- **Semantic colors**: Use system semantic colors (destructive, success, warning) for consistent meaning.
- **Contrast**: Maintain WCAG AA contrast ratios (4.5:1 for text, 3:1 for UI components).

### Avoid
- Overused gradients (purple-to-blue on white) that signal generic AI-generated design.
- Colors that clash with platform system UI.

---

## Motion & Animation
- **Purpose-driven**: Use motion to clarify hierarchy, state changes, and spatial relationships.
- **Reduce Motion**: Always respect `UIAccessibility.isReduceMotionEnabled`. Provide static alternatives.
- **Platform conventions**: Use system transitions (push, modal, sheet) as the baseline; customize only with purpose.
- **High-impact moments**: One well-orchestrated entrance animation creates more delight than scattered micro-interactions.

### Avoid
- Gratuitous animation that slows task completion.
- Motion that ignores Reduce Motion settings.

---

## Spatial Composition
- **Safe Areas**: Always respect device safe areas and notches.
- **Grid alignment**: Establish a clear grid but allow intentional grid-breaking for emphasis.
- **Generous spacing**: White space conveys hierarchy and reduces cognitive load.
- **Touch targets**: Maintain minimum 44×44 pt (iOS) / 48×48 dp (Android) touch targets.

### Avoid
- Cluttered layouts that ignore safe areas.
- Uniform spacing that creates visual monotony.

---

## Visual Details & Atmosphere
- **Backgrounds**: Create depth with subtle gradients, blurs, or materials (vibrancy, blur effects) rather than flat solid colors.
- **Shadows & elevation**: Use system-appropriate shadow styles for depth hierarchy.
- **Textures**: Apply subtle textures (noise, grain) sparingly for brand character.
- **SF Symbols**: Leverage SF Symbols for consistent, scalable iconography with automatic weight matching.

### Avoid
- Web-centric effects (dramatic grain overlays, extreme glassmorphism) that feel out of place on mobile.
- Custom icons that clash with platform symbol style.

---

## Anti-Patterns (AI Slop)
NEVER fall into generic AI-generated aesthetics:
- ❌ Overused fonts: Inter, Roboto, Space Grotesk for everything
- ❌ Cliché color schemes: Purple gradients on white backgrounds
- ❌ Cookie-cutter layouts: Identical card grids with no visual hierarchy
- ❌ Predictable component patterns: Every app looking the same
- ❌ Ignoring platform identity: iOS apps that look like Material, or vice versa

**Commitment**: Each design should feel uniquely suited to its context, users, and platform—never interchangeable with any other app.
