---
name: SQL Practice System
colors:
  surface: '#0b141c'
  surface-dim: '#0b141c'
  surface-bright: '#313a43'
  surface-container-lowest: '#060f16'
  surface-container-low: '#141c24'
  surface-container: '#182028'
  surface-container-high: '#222b33'
  surface-container-highest: '#2d363e'
  on-surface: '#dae3ee'
  on-surface-variant: '#bdc8d1'
  inverse-surface: '#dae3ee'
  inverse-on-surface: '#29313a'
  outline: '#87929a'
  outline-variant: '#3e484f'
  surface-tint: '#7bd0ff'
  primary: '#8ed5ff'
  on-primary: '#00354a'
  primary-container: '#38bdf8'
  on-primary-container: '#004965'
  inverse-primary: '#00668a'
  secondary: '#74dd7e'
  on-secondary: '#003910'
  secondary-container: '#007f2d'
  on-secondary-container: '#c4ffc2'
  tertiary: '#ffbcb5'
  on-tertiary: '#690007'
  tertiary-container: '#ff9389'
  on-tertiary-container: '#8d000c'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c4e7ff'
  primary-fixed-dim: '#7bd0ff'
  on-primary-fixed: '#001e2c'
  on-primary-fixed-variant: '#004c69'
  secondary-fixed: '#90fa97'
  secondary-fixed-dim: '#74dd7e'
  on-secondary-fixed: '#002106'
  on-secondary-fixed-variant: '#00531b'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#ffb4ac'
  on-tertiary-fixed: '#410002'
  on-tertiary-fixed-variant: '#93000d'
  background: '#0b141c'
  on-background: '#dae3ee'
  surface-variant: '#2d363e'
typography:
  display-sm:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  code-md:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 20px
  code-sm:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 18px
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  unit: 4px
  container-padding: 16px
  element-gap: 8px
  toolbar-height: 40px
  sidebar-width: 260px
---

## Brand & Style

This design system is engineered for high-productivity technical environments where information density and clarity are paramount. The aesthetic is rooted in **Minimalism** with a **Functional/Developer** focus. It prioritizes content over decoration, using structured borders and a restricted color palette to define hierarchy.

The brand personality is precise, reliable, and unobtrusive. It seeks to evoke a state of "flow" by reducing visual noise and maximizing the "above-the-fold" data visibility. The interface favors a flat, utility-first approach, using distinct monochromatic layers to separate navigation, code editors, and result grids.

## Colors

The palette is optimized for long-duration coding sessions. The primary mode is **Dark**, utilizing a deep obsidian base to minimize eye strain.

- **Primary (#38BDF8):** Used exclusively for active states, focus indicators, and primary action buttons.
- **Success (#7EE787):** A muted green for query execution confirmations and successful data migrations.
- **Error (#F85149):** A soft but high-visibility red for syntax errors and connection failures.
- **Neutrals:** Grayscale tones are derived from cool-blue tints to maintain a cohesive technical feel. 
  - `Base`: Background of the main workspace.
  - `Surface`: Background for sidebars, tabs, and input areas.
  - `Border`: The primary tool for structural separation.

## Typography

The typography system relies on a functional split between UI chrome and data content.

- **Inter** is used for all navigational elements, settings, and modal text. It is chosen for its exceptional legibility at small sizes.
- **JetBrains Mono** is the workhorse for the SQL Editor and Data Grids. It provides a consistent rhythmic baseline for scanning rows of tabular data and complex JOIN statements.

To maintain high density, the default body size is set to **14px**, with **12px** used for secondary metadata. Letter spacing is slightly tightened on headings to maintain a compact, "pro" appearance.

## Layout & Spacing

The layout utilizes a **fluid grid** within functional panes. It mimics an IDE structure: a fixed-width left sidebar for schema exploration and a flexible main workspace for code and results.

- **Rhythm:** A 4px baseline grid governs all padding and margins. 
- **Density:** Padding inside components (like table cells or list items) is kept to a minimum (8px horizontal, 4px vertical) to ensure maximal data is visible.
- **Panes:** Use 1px borders to separate workspace areas rather than shadows. Resizable handles should be subtle but discoverable.
- **Mobile:** On small screens, the sidebar collapses into a bottom-sheet or a full-screen overlay, and the data grid enables horizontal scrolling with pinned index columns.

## Elevation & Depth

This system avoids traditional depth markers like heavy drop shadows. Instead, it uses **Tonal Layering** and **Border Contours**:

1.  **Level 0 (Base):** `#0D1117` — The main background behind all panels.
2.  **Level 1 (Surface):** `#161B22` — Sidebars, toolbars, and editor gutters.
3.  **Level 2 (Active/Pop-over):** `#1C2128` — Modals, dropdown menus, and tooltips.

**Borders:** Use `#30363D` for all structural divisions. When an element is focused (like an input or an active tab), the border transitions to the primary accent color (`#38BDF8`).

## Shapes

The shape language is strictly professional. 

- **Components:** Buttons, inputs, and cards use a **4px (0.25rem)** radius. This provides just enough softness to distinguish the UI from the browser chrome without losing the "technical" precision.
- **Selection States:** Row highlights in data tables and schema browsers use 0px radius to ensure a continuous block of color across the full width of the container.

## Components

- **Buttons:** Use a solid primary background for the main "Run Query" action. Secondary buttons use a ghost style (border and text only). All buttons have a fixed height of 32px for high density.
- **Data Tables:** High-density rows with `code-sm` typography. Header cells use `surface_primary` background with a slightly thicker bottom border. Hovering over a row should apply a subtle `1px` inner border or a 5% lighter background tint.
- **SQL Editor:** Use a dark theme matching the `background_base`. Syntax highlighting should use the primary teal for keywords and the success green for strings.
- **Tabs:** "Underline" style. Active tabs feature a 2px bottom border in the primary teal color. Inactive tabs use the neutral gray.
- **Input Fields:** Dark background (`#0D1117`) with a 1px border. On focus, the border glows with the primary teal color at 50% opacity.
- **Chips/Badges:** Small, pill-shaped markers for data types (e.g., `INT`, `VARCHAR`). Use a subtle background tint and 11px mono text.
- **Status Indicators:** Small 8px circles for connection status. Pulsing animation for "Query Running" states.