---
name: Soft Liquid Glass
colors:
  surface: '#fcf8ff'
  surface-dim: '#dcd7ea'
  surface-bright: '#fcf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f1ff'
  surface-container: '#f0ebfe'
  surface-container-high: '#ebe5f8'
  surface-container-highest: '#e5e0f3'
  on-surface: '#1c1a27'
  on-surface-variant: '#3d4a44'
  inverse-surface: '#312f3d'
  inverse-on-surface: '#f3eeff'
  outline: '#6d7a74'
  outline-variant: '#bccac2'
  surface-tint: '#006c53'
  primary: '#006c53'
  on-primary: '#ffffff'
  primary-container: '#1faf8a'
  on-primary-container: '#003b2c'
  inverse-primary: '#5cdcb4'
  secondary: '#63539d'
  on-secondary: '#ffffff'
  secondary-container: '#bfadff'
  on-secondary-container: '#4d3d86'
  tertiary: '#9f4119'
  on-tertiary: '#ffffff'
  tertiary-container: '#ec7c4f'
  on-tertiary-container: '#5f1d00'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#7bf9cf'
  primary-fixed-dim: '#5cdcb4'
  on-primary-fixed: '#002117'
  on-primary-fixed-variant: '#00513e'
  secondary-fixed: '#e7deff'
  secondary-fixed-dim: '#ccbeff'
  on-secondary-fixed: '#1e0856'
  on-secondary-fixed-variant: '#4a3b83'
  tertiary-fixed: '#ffdbce'
  tertiary-fixed-dim: '#ffb59a'
  on-tertiary-fixed: '#380d00'
  on-tertiary-fixed-variant: '#7f2b02'
  background: '#fcf8ff'
  on-background: '#1c1a27'
  surface-variant: '#e5e0f3'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 42px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-lg:
    fontFamily: Inter
    fontSize: 17px
    fontWeight: '400'
    lineHeight: 26px
    letterSpacing: 0em
  body-md:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '400'
    lineHeight: 22px
    letterSpacing: 0.005em
  body-sm:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-lg:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.02em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1.5rem
  margin-mobile: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

This design system is tailored for an executive-function companion designed around adult ADHD and neurodivergence, grounded fundamentally in a "Zero Guilt" ethos. The visual architecture rejects punitive patterns—such as broken streak counters, urgent red badges, demanding overdue lists, and sensory-overload notifications. Instead, it creates an environment of organic calm, low cognitive friction, and sensory clarity.

The aesthetic direction merges **Soft Liquid Glass** with warm tactile minimalism. Translucent glass containers, gentle backdrop blurs, luminous perimeter highlights, and pillowy geometry evoke a sense of physical weightlessness and safety. The interface acts as an accommodating spatial buffer rather than a rigid tracker: it adapts to dysregulated energy states, forgives breaks in routine, scaffolds decision-making without judgment, and uses comforting organic depth to make task initiation feel inviting rather than paralyzing.

## Colors

The palette avoids aggressive primary hues in favor of biologically grounded, low-cortisol tones designed to balance dopamine seeking with nervous-system regulation:

- **Primary (`#1FAF8A` — Energetic Mint Teal):** The tone for affirmative forward momentum, momentum check-ins, micro-completions, and restorative health actions. It delivers rewarding dopamine clarity without visual aggression.
- **Secondary (`#8B7BC8` — Calming Lavender):** Used for cognitive bandwidth insights, State of Mind logs, quiet reflective routines, and neuro-rhythm charts. It acts as an ambient stabilizer.
- **Tertiary (`#FF8A5C` — Gentle Coral):** The "Unstick / Anti-Paralysis" activator. Replaces alarmist systemic reds with a compassionate, high-visibility nudge for refilling medication, breaking executive paralysis, or pausing over-focus.
- **Neutral (`#6E6B7B` — Warm Pebble Grey):** Grounded slate for calm structure, low-contrast subtitles, and unassertive borders.

### Surface Tones & Dynamic Mode Guidance

- **Light Mode (Default):** Canvas background is a warm, paper-soft off-white (`#FAF8F5`). Cards utilize pure white (`#FFFFFF`) with 75%–85% opacity, accompanied by soft liquid borders (`#E8E4DF` at 60% opacity) over dynamic pastel ambient orbs.
- **Dark Mode:** Canvas is a deep charcoal slate (`#16161A`). Cards sit at `#212127` with 65%–80% opacity, framed by inner specular edge highlights (`rgba(255, 255, 255, 0.08)`) and subdued depth fills (`#2E2D36`).
- **Support Greys:** Primary labels rest on `#2E2D36` in light mode; secondary metadata rests on `#9B98A6`.

## Typography

The type system prioritizes unhurried, comfortable parsing for neurodivergent eyes prone to visual crowding and scanning fatigue. Built on **Inter**, typography is configured with generous x-heights, relaxed vertical leading, and distinct glyph definitions.

- **Legibility & Comfort:** Headings use confident medium-to-bold weights with tight, humanized negative tracking, preventing overwhelming visual weight. Body text maintains open tracking and ample line heights (at least 1.45–1.55× font size) to prevent reading line loss during executive fatigue.
- **Hierarchical Anchors:** Every view utilizes a single prominent text anchor (`headline-lg` or `headline-md`). Subordinate micro-copy is concise, avoiding cognitive clutter and walls of instructional text.
- **Numbers & Data:** Tabular figures are enforced for med schedules, timers, and quantitative metrics to eliminate visual jitter during real-time countdowns.

## Layout & Spacing

The layout is built on a tactile, single-column fluid mobile stack scaling up to a max-width anchored 4-column canvas on tablets and compact devices. It enforces strict sensory breathing room:

- **Grid & Alignment:** Mobile screens adhere to a fluid single-track container with `margin-mobile` (`1.25rem` / 20px) preventing touch interactions from colliding with physical display edges. Component gaps default to `space-md` (16px) or `space-lg` (24px) to keep decision boundaries explicit.
- **Breathing Room:** Crowding triggers cognitive rejection. Dense lists are broken into segregated liquid glass islands separated by `space-md`. Vertical sequences never bunch interactive triggers without a minimum 48px hit area clearance.
- **Reflow & Responsiveness:** On wider mobile devices and foldables, cards do not stretch indefinitely; they cap at an ergonomic reading measure (max 540px width), centering dynamically with cushioned fluid margins.

## Elevation & Depth

Depth in this system avoids harsh mechanical drop-shadows or stark physical drop-offs. It relies on **Soft Liquid Glass**—multi-layered translucent optical refraction and gentle tinted illumination:

- **Translucent Grounding:** Surfaces sit on a backdrop blur between `16px` and `24px` (`backdrop-filter: blur(20px)`), allowing gentle ambient colored light to pool through from behind without disturbing text contrast.
- **Perimeter Light-Catching:** Cards feature a delicate 1px inset border mimicking light catching curved molded acrylic:
  - *Light Mode:* `border: 1px solid rgba(255, 255, 255, 0.65)` layered with an outer ring of `rgba(232, 228, 223, 0.45)`.
  - *Dark Mode:* `border: 1px solid rgba(255, 255, 255, 0.12)` layered with an ambient shadow ring.
- **Ambient Diffusion:** Shadows are diffuse, wide, and tinted by the underlying canvas:
  - *Resting Card:* `0 10px 30px -10px rgba(110, 107, 123, 0.08), 0 2px 8px -2px rgba(110, 107, 123, 0.04)`.
  - *Floating Focus / Active Modal:* `0 20px 40px -12px rgba(31, 175, 138, 0.18), 0 4px 16px -2px rgba(0, 0, 0, 0.04)`.

## Shapes

The shape system employs deeply rounded, organic geometry that feels soft and receptive in hand:

- **Cards & Primary Modules:** Standardized to a generous radius between `16px` (`rounded-lg`) and `24px` (`rounded-xl`), eliminating aggressive corners that signal urgency or tension.
- **Interactive Controls & Chips:** Fully pill-shaped or rounded with `12px` to `16px` curvature, matching the natural organic contours of fingertips.
- **Nested Proportionality:** When an element is placed inside a container, inner radii strictly scale down to maintain harmonious concentricity (e.g., a card with `rounded-xl` of 24px nests buttons and inner progress bars of 14px to 16px with `space-sm` padding).

## Components

### Buttons
- **Primary Momentum Button:** Filled with vibrant Mint (`#1FAF8A`), white text, `rounded-xl` (16px–24px), padded at `16px 24px`. Employs a subtle top inner reflection highlight (`rgba(255, 255, 255, 0.25)`) and a soft mint ambient glow. Tap feedback uses an elastic scale reduction (`scale(0.97)`) paired with visual haptic bounce.
- **Unstick (Anti-Paralysis) Action:** Styled with Gentle Coral (`#FF8A5C`), designed with an unhurried, reassuring presence. Used exclusively for micro-steps that dismantle task freezing.
- **Secondary Ghost Glass:** Backdrop blur with 1px liquid highlight border, resting quietly until interaction.

### Chips (State of Mind & Neuro-Energy)
- Tactile, pill-shaped sensory selectors (`padding: 10px 18px`).
- Inactive state: Soft glass surface with `#6E6B7B` typography.
- Active state: Infused with Calming Lavender (`#8B7BC8`) or Mint (`#1FAF8A`) at 15% opacity tint, 1.5px luminous border, and gently raised ambient elevation.

### Micro-Habit Rows (Zero-Guilt Architecture)
- Replaces rigid checkmarks and fire/streak icons with organic "completion pebbles" or soft liquid fills.
- When an action is completed, it transforms into a calm mint-tinted glass node with a comforting message ("Saved for later", "Done for today"). No "broken streaks" or negative red states appear when days are missed; missed days simply show open, judgment-free space.

### Medication Efficacy Window Cards
- Specialized timeline cards with horizontal glowing gradients mapping plasma half-life and focus windows.
- Liquid glass background layered with gentle coral or mint illumination along the active operational zone, giving users a tangible spatial forecast of their day's mental bandwidth.

### Input Fields
- Recessed frosted glass vessels (`rgba(255, 255, 255, 0.5)` light mode, `rgba(33, 33, 39, 0.6)` dark mode).
- Rounded to `16px`, using large placeholder text that scaffolds rather than tests the user, accompanied by soft clear buttons to reduce the effort of re-typing.