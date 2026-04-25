# Style Guide — LaChispa

LaChispa ships a **token-driven** design system with **three themes**:

| Theme    | Identity                                | State        |
| -------- | --------------------------------------- | ------------ |
| LaChispa | Cypherpunk · electric blue · sparks     | Implemented  |
| Light    | Quiet trust · minimal fintech           | Spec only    |
| Dark     | Sovereign tool · terminal-elegant       | Spec only    |

`accentSolid` (`#4C63F7`, the **Chispa blue**) is shared across all three themes
to preserve brand identity. Themes vary in backgrounds, surfaces, text, and the
behavior of the Spark/glass system — never in the primary accent.

Tokens live in `lib/theme/app_tokens.dart` (the `AppTokens` extension) and are
applied to a theme through `lib/theme/themes.dart`. This document is the
human-readable spec; the code is the source of truth.

---

## Typography

**Font family:** `Manrope` (variable, bundled at `assets/fonts/Manrope-Variable.ttf`).
The same family is used across all three themes.

| Role          | Size | Weight        | Notes                                  |
| ------------- | ---- | ------------- | -------------------------------------- |
| Display title | 48px | Bold (700)    | Hero balances, splash                  |
| Section title | 24px | SemiBold (600)| Screen headers                         |
| Subtitle      | 18px | Medium (500)  | Sub-headers, list group titles         |
| Body          | 16px | Medium (500)  | Default copy                           |
| Body small    | 14px | Regular (400) | Secondary copy, captions               |
| Numeric       | —    | Medium (500)  | Balances; prefer tabular figures       |
| Button        | 16px | SemiBold (600)| All CTAs                               |

Numeric balances should use Manrope Medium with `FontFeature.tabularFigures()`
so digits don't wobble during animation. Bitcoin convention: leading zeros and
non-significant digits render at `textTertiary`; significant digits at
`textPrimary`.

---

## Token Reference

The 21 tokens defined in `AppTokens`. Use these names — never hard-code colors.

| Token                | LaChispa (current)           | Light (spec)             | Dark (spec)              |
| -------------------- | ---------------------------- | ------------------------ | ------------------------ |
| `scaffoldBase`       | `#0F1419`                    | `#F7F7F5`                | `#0B0B0C`                |
| `backgroundGradient` | `#0F1419 → #1A1D47 → #2D3FE7` (diagonal) | solid `#F7F7F5` (no gradient) | solid `#0B0B0C` (no gradient) |
| `surface`            | `#FFFFFF` @ 5% (glass)       | `#FFFFFF`                | `#141416`                |
| `dialogBackground`   | `#1A1D47`                    | `#FFFFFF`                | `#1C1C1F`                |
| `inputFill`          | `#FFFFFF` @ 5%               | `#FFFFFF`                | `#1C1C1F`                |
| `outline`            | `#FFFFFF` @ 10%              | `#E5E5E0`                | `#2A2A2E`                |
| `outlineStrong`      | `#FFFFFF` @ 18%              | `#D1D1CC`                | `#3A3A3E`                |
| `textPrimary`        | `#FFFFFF`                    | `#0D0D0D`                | `#F5F5F5`                |
| `textSecondary`      | `#FFFFFF` @ 55%              | `#6B6B6B`                | `#9A9A9A`                |
| `textTertiary`       | `#FFFFFF` @ 45%              | `#9A9A9A`                | `#6B6B6E`                |
| `textAccent`         | `#6B7FFF`                    | `#3B4FE0`                | `#7E92FF`                |
| `accentSolid`        | `#4C63F7`                    | `#4C63F7`                | `#4C63F7`                |
| `accentBright`       | `#5B73FF`                    | `#6B7FFF`                | `#7E92FF`                |
| `accentForeground`   | `#FFFFFF`                    | `#FFFFFF`                | `#FFFFFF`                |
| `accentGradient`     | `#2D3FE7 → #4C63F7`          | `#3B4FE0 → #4C63F7`      | `#2D3FE7 → #5B73FF`      |
| `statusHealthy`      | `#4ADE80`                    | `#10B981`                | `#3BD671`                |
| `statusUnhealthy`    | `#EF4444`                    | `#DC2626`                | `#FF5C5C`                |
| `statusWarning`      | `#FFA726`                    | `#D97706`                | `#FFB454`                |
| `statusWarningSoft`  | `#FFCC80`                    | `#FED7AA`                | `#7A5A2E`                |
| `statusChecking`     | `#FFFFFF` @ 25%              | `#0D0D0D` @ 20%          | `#FFFFFF` @ 20%          |
| `ctaShadow`          | `#000000` @ 35%              | `#0D0D0D` @ 8%           | `#000000` @ 60%          |

Status colors are tuned per theme so that contrast against `surface` stays
≥ 4.5:1 for text and ≥ 3:1 for non-text UI. Hue stays semantically constant
(green=ok, red=fail, orange=warn).

---

## Themes

### LaChispa (Original) — “electric · cypherpunk · sovereign”

**Identity:** energy, underground, unmistakable. The visual fingerprint of
the brand. Glassmorphism over a deep gradient, ambient sparks, blue glow.

- Background is the 3-stop diagonal gradient `#0F1419 → #1A1D47 → #2D3FE7`.
- Surfaces are **glass**: `Colors.white.withValues(alpha: 0.08)` over the
  gradient, with a 1px white-@-10% border and a black-@-10% drop shadow.
- The **Spark particle system** is on (see § Spark System).
- CTAs use `accentGradient` with a Chispa-blue glow shadow.
- Border radius: **16px** everywhere (12px on small icon buttons).

### Light — “quiet trust”

**Identity:** clean, calm, unmistakably *not a bank*. Minimalism that doesn't
intimidate. White space does the heavy lifting.

- Background is **flat** `#F7F7F5` — no gradient.
- Surfaces are **opaque** `#FFFFFF` with a 1px `outline` border. No glass.
- Shadows: barely visible (`ctaShadow` @ 8%), only on elevated CTAs.
- Spark system is **disabled** in Light. (White-on-white sparks are noise,
  not signal.) Reintroduce only as a brief one-shot during success states.
- CTAs are solid `accentSolid` with white text. No glow.
- Border radius: **16px** (consistent with LaChispa).

### Dark — “sovereign tool”

**Identity:** serious instrument, terminal-elegant. Not a generic dark mode —
a deliberate flat-layered system with high typographic contrast.

- Background is **flat** `#0B0B0C` — no gradient. Layering is achieved with
  surface elevation (`surface` < `dialogBackground` < CTA), not shadows.
- Surfaces are opaque (`#141416`, `#1C1C1F`) with a visible 1px `outline`
  (`#2A2A2E`).
- Spark system is **muted**: half the spawn rate of LaChispa, 50% opacity,
  reuses `accentBright`. Off by default; opt-in via settings.
- CTAs use `accentSolid` with a soft `accentBright` outer glow on press.
- Border radius: **16px**.

---

## Components

All components use the **same structure** across themes. Only token values
change. Never branch on theme name in widget code — read tokens.

### Balance widget

- Display: numeric Manrope Medium, 48px (mobile) / 64px (tablet+).
- Color: `textPrimary` for significant digits, `textTertiary` for leading
  zeros and the unit suffix (`sats` / `BTC`).
- Surface: glass card on LaChispa; opaque card on Light/Dark.
- Animation: digit changes use a 220ms cross-fade (no slot-machine roll —
  too noisy for monetary data).

### Send / Receive

- Primary action: full-width 56px button using `accentGradient` (LaChispa) or
  `accentSolid` (Light, Dark). 16px radius. Shadow per theme.
- Secondary action: outlined or glass-style button using `outline` and
  `surface`. Same height, same radius, lighter weight.
- QR display: always rendered with a **white frame** for scanner reliability.
  In LaChispa and Dark, the frame includes a 12px white inset around the QR.
  In Light, the frame is the surface itself.

### Transaction history

- Row: 64px tall, `surface` background, 1px `outline` divider between rows.
- Status indicator (left edge, 4px wide):
  - confirmed → `statusHealthy`
  - pending   → `statusChecking` with a subtle pulse
  - failed    → `statusUnhealthy`
- Amount: right-aligned, `textPrimary` for incoming (with `+` prefix in
  `statusHealthy`) and `textPrimary` for outgoing (no special color).
- Timestamp: `textTertiary`, body small.

### Text fields

- Background: `inputFill`.
- Border: 1px `outline`, becomes `accentSolid` on focus.
- Border radius: 16px.
- Padding: 24px horizontal, 22px vertical.
- Icons: `textTertiary`, 20px.
- Placeholder: `textTertiary`.

### Dialogs

- Background: `dialogBackground`.
- Border radius: 16px.
- 1px `outline` border in Dark and Light; no border in LaChispa (the surface
  contrast is sufficient).

---

## UI States

| State    | Effect                                                                  |
| -------- | ----------------------------------------------------------------------- |
| Default  | Token defaults                                                          |
| Hover    | Surface +5% lightness; outline → `outlineStrong`                        |
| Pressed  | Surface −8% lightness (Light) / +8% lightness (LaChispa, Dark)          |
| Focus    | Outline → `accentSolid`, 1.5px                                          |
| Disabled | Opacity 0.4, no shadow, no glow                                         |
| Loading  | `statusChecking` indeterminate progress; CTA label hidden               |
| Error    | `statusUnhealthy` 1px outline + helper text in `statusUnhealthy`        |
| Success  | `statusHealthy` outline pulse 220ms, then return to default             |

Hover applies on web/desktop only. On mobile, ripple uses
`accentSolid` @ 12% on Light and `accentBright` @ 14% on LaChispa/Dark.

---

## Spark System

The Spark particle system is part of LaChispa's identity. Specs:

- **Cycle:** every 3 seconds. 2–4 sparks per cycle. 10–30 particles per spark.
- **Position:** uniform random across the screen.
- **Lifespan:** 100 frames, with `Curves.easeOutQuart` opacity decay.
- **Particle:** 1–4px radius, organic radial dispersion (intensity 2–6),
  deceleration 0.99/frame.
- **Layers:** outer glow (2× radius, blur 2.0) + inner glow (1.5×, blur 2.0)
  + solid core (1×).
- **Colors (LaChispa):** outer `#5B73FF` @ 40%, inner `#4C63F7` @ 80%,
  core `#5B73FF` @ 90%.
- **Implementation:** `AnimationController` at 16ms (60fps), 3s spawn timer,
  `SparkPainter` with auto-removal of dead particles.

### Per-theme behavior

| Theme    | Default state | Spawn rate | Opacity |
| -------- | ------------- | ---------- | ------- |
| LaChispa | On            | 100%       | 100%    |
| Dark     | Off (opt-in)  | 50%        | 50%     |
| Light    | Off           | n/a        | n/a     |

In Light, sparks are reserved for **discrete success moments** (e.g., a payment
confirmation): a single one-shot burst near the action point, ~400ms total,
using `accentSolid` instead of `accentBright`.

---

## Animations

### Entrance (staggered)

- Total duration: **1600–2000ms**.
- Curve: `Curves.easeOutCubic`.
- Stagger:
  - Header: `0.0–0.4` (immediate)
  - Content: `0.3–0.7` (overlapping)
  - Footer: `0.6–1.0` (final)
- Offset: 30–50px from bottom.
- Opacity: 0 → 1.

### Glow (LaChispa, Dark)

- Duration: 2000ms, ping-pong (`reverse: true`).
- Curve: `Curves.easeInOut`.
- Range: 0.3 → 1.0.
- Application: title shadows, primary CTA glow on press.

### Microinteractions

| Action               | LaChispa                          | Dark                          | Light                       |
| -------------------- | --------------------------------- | ----------------------------- | --------------------------- |
| Receive sats         | Spark burst (orange-tinted) + balance pulse | Soft glow pulse on balance card | Single spark burst at amount |
| Send confirmed       | Quick fade-out → checkmark        | Same as LaChispa              | Checkmark + 220ms scale-in  |
| Balance changes      | Cross-fade 220ms                  | Cross-fade 220ms              | Cross-fade 220ms            |
| QR appears           | Scan-line sweep 600ms             | Scan-line sweep 600ms         | Fade-in 300ms               |
| Copy address         | Inline “Copied” snackbar 1.5s     | Same                          | Same                        |
| Tap CTA              | Glow flash 180ms                  | Glow flash 180ms              | Subtle scale 0.98 → 1.0     |

Respect `MediaQuery.disableAnimations`. When animations are disabled, all
microinteractions become instantaneous state changes — never silent failures.

---

## Spacing & Layout

- Horizontal padding: **24px**.
- Element spacing: 16–24px.
- Section spacing: 32–48px.
- Bottom safe-area padding: ≥ 32px.
- Grid: 8px multiples for all spacing.

### Responsive

- Mobile (`< 600px`): vertical column, full-width CTAs.
- Tablet/desktop (`≥ 600px`): horizontal row for paired CTAs; balance card
  centered with `Spacer(flex: 2)` above and below.

---

## Accessibility

- **Contrast:** body text ≥ 4.5:1 against its surface; large text and UI
  elements ≥ 3:1. Run a contrast check whenever a token value changes.
- **Tap targets:** ≥ 44×44 logical pixels.
- **Motion:** all animations have an instantaneous fallback under
  `MediaQuery.disableAnimations`. Spark system is fully suppressed.
- **Color is never the only signal:** transaction status uses both color and
  iconography; errors use color, icon, and helper text.
- **Localization:** string lengths can grow ~30% in Spanish. CTAs and labels
  must reflow without truncation.

---

## Implementation Notes

### Reading tokens

```dart
final tokens = context.tokens;          // AppTokensContext extension
final color  = tokens.accentSolid;
```

Never read raw `Color` constants in widget code — go through `context.tokens`.

### Defining a new theme

1. Add an `AppTokens` constant in `lib/theme/themes.dart` (e.g.
   `lightTokens`, `darkTokens`).
2. Add a `ThemeData` builder that wires the token set to a
   `ColorScheme` (`Brightness.light` for Light, `Brightness.dark` for Dark
   and LaChispa).
3. Register both via `extensions: [<tokens>]` on the `ThemeData`.
4. Switch them at the `MaterialApp` level via a `ThemeProvider`
   (`ChangeNotifier` + `SharedPreferences`), following the same pattern as
   `LanguageProvider`.

### Compatibility

- Flutter 3.x: use `withValues(alpha: x)`, not `withOpacity(x)`.
- 60fps target: `AnimationController(duration: Duration(milliseconds: 16))`
  for particle ticks.
- Particle cleanup is mandatory — leaks compound on long sessions.

### Hardcoded color audit

These files still hard-code colors and must migrate to tokens before the
multi-theme rollout:

- `lib/screens/8settings_screen.dart:613-615` (internal gradient)
- `lib/screens/3server_settings_screen.dart:578-579` (direct refs)
- `lib/screens/9receive_screen.dart:1046` (`#1A1D47` → `dialogBackground`)

---

## Rollout Strategy

When introducing Light or Dark, apply the new tokens to **one screen first**
(home / balance is the canonical pilot), validate visually against this spec,
then propagate. Don't ship a half-themed app — every screen reads tokens, so
the only thing gating a clean switch is the three hard-coded files above.
