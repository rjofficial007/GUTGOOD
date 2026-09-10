# GutGood — Apple iOS Design System

> **Status:** Canonical design spec for all new UI. Port of the **Apple Human Interface Guidelines (HIG)** to GutGood's Flutter codebase.
> **Sources reviewed (market):** Apple HIG (typography, color, layout, liquid-glass 2025 update), Apple's official Figma design resources (`developer.apple.com/design/resources/`), Flutter `cupertino` library, and community iOS kits (Untitled UI iOS, Apple Design System Breakdown 2026).
> **Honesty note:** Apple does **not** publish guaranteed hex values — iOS colors are *adaptive semantic tokens* that shift with trait environment (light/dark, contrast, vibrancy). Every hex below is the **community-measured value at the default trait collection**, labeled as such. Always design to the semantic *role*, treat the hex as its light/dark default.

---

## 1. Principles

| Principle | Meaning | GutGood rule |
|---|---|---|
| **Clarity** | Legible at every size, precise, easy to understand | Body text never below 17pt equivalent for primary reading; icons always paired with meaning |
| **Deference** | UI serves content, never competes with it | No decorative borders/noise; whitespace does hierarchy work; one accent color per screen |
| **Depth** | Layers + motion convey hierarchy | Sheets overlay, cards sit above grouped backgrounds via subtle elevation, blur for chrome |
| **Consistency** | Same token = same meaning everywhere | **Never hardcode `fontSize`/`Color`/`EdgeInsets` literals — use the token classes below** |

---

## 2. Typography — SF Pro scale

**Primary reading scale is the ios Dynamic Type “Large” (default) scale.** These are the exact HIG values; every new text style must map to one of these rows.

| Token (iOS) | Size (pt) | Weight | Leading | GutGood API (`AppTextStyles` / context ext) |
|---|---|---|---|---|
| Large Title | 34 | Regular / **Bold** emphasized | 41 | `displaySm` |
| Title 1 | 28 | Regular / **Bold** | 34 | `headingLg` |
| Title 2 | 22 | Regular / **Bold** | 28 | `headingMd` |
| Title 3 | 20 | Regular / **Semibold** | 25 | `headingSm` |
| **Headline** | 17 | **Semibold** | 22 | `headline` *(alias → `title`)* |
| **Body** | 17 | Regular | 22 | `bodyLg` |
| Callout | 16 | Regular | 21 | `body` |
| Subhead | 15 | Regular | 20 | `bodySm` |
| Footnote | 13 | Regular | 18 | `label` |
| Caption 1 | 12 | Regular | 16 | `caption` |
| Caption 2 | 11 | Regular | 13 | `caption2` *(→ current `labelBold`, reweighted to w400/w600)* |

Rules:
- **17pt Body is the legibility floor.** Nothing a user *reads* goes below Footnote (13pt).
- One viewport = at most **one** Title-1-or-larger element.
- Eyebrow/kicker labels are **Caption 1 (12pt), w600, ALL-CAPS, letterSpacing +0.5** — replaces the current oversized `eyebrow` (10sp, ls 1.5). (Current `captionBold` 8.5sp / `captionTiny` 7sp pills are **non-HIG and retire over time** — new pills use Caption 2, 11pt.)

### 2.1 Font family

| Platform | Spec |
|---|---|
| iOS | SF Pro is the default — do nothing (or `fontFamily: '.SF UI Text'`). Optical size is automatic: **SF Pro Text ≤ 19pt, Display ≥ 20pt**. |
| Android (GutGood runs Flutter cross-platform) | Bundled as `SFProText` / `SFProDisplay` families in `assets/fonts/` (wired in `pubspec.yaml`). ⚠️ Apple's SF license covers Apple-platform use — for an Android release swap to a metric-compatible open font (e.g. Inter) or review terms; theme-level families make this a two-line change (see `assets/fonts/README_LICENSE.txt`). |
| Serifs (long-form insight text, optional) | **New York** — iOS native; do not bundle. |
| Monospace (scores/JSON debug) | SF Mono iOS; `RobotoMono` Android. |

Tracking at common sizes (iOS auto-applies; mockups only): 11pt +0.06em · 13pt -0.08em · 15pt -0.24em · 17pt -0.41em · 20pt -0.45em · 28pt -0.025em · 34pt -0.01em. **Flutter rule: set `letterSpacing: -0.4` only on 17–24pt, `-0.02px`-ish negative on titles, `+0.5` on all-caps captions.**

### 2.2 Dynamic Type (accessibility)

Text must scale with the OS text-size setting: wrap hard caps with `MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.35)` on dense screens (chat bubbles, sheets), full scaling elsewhere. No `overflow`-truncated primary content.

---

## 3. Color — semantic roles, not raw hex (Light / Dark measured defaults)

### 3.1 Surfaces & labels (system chrome)

| Semantic token | Light | Dark | GutGood `AppPalette` mapping |
|---|---|---|---|
| `systemBackground` | #FFFFFF | #000000 | `white` / `darkPrimary` |
| `secondarySystemBackground` | #F2F2F7 | #1C1C1E | `gray50` / `darkCard` *(adjust to exact #1C1C1E)* |
| `tertiarySystemBackground` | #FFFFFF | #2C2C2E | `white` cards / `darkElevated` |
| `groupedBackground` | #F2F2F7 | #000000 | settings sheets / lists |
| `label` (primary text) | #000000 | #FFFFFF | `black` / `darkTextPrimary` |
| `secondaryLabel` | rgba(60,60,67,.60) | rgba(235,235,245,.60) | `gray500` / `darkTextSecondary` |
| `tertiaryLabel` | rgba(60,60,67,.30) | rgba(235,235,245,.30) | `gray400` / `darkTextMuted` |
| `separator` | rgba(60,60,67,.12) — **0.5pt hairline** | rgba(84,84,88,.65) | `gray200` / `darkBorder` |
| `tealGrouped` nav/tab bars | #F7F7F8CC @80% blur | #161618CC @80% | chrome, frosted |

### 3.2 System colors (measured defaults — adaptive)

| Token | Light | Dark | Use |
|---|---|---|---|
| systemGreen | #34C759 | #30D158 | GutGood primary accent — positive, score-good, CTAs |
| systemRed | #FF3B30 | #FF453A | Critical score, destructive |
| systemOrange | #FF9500 | #FF9F0A | Caution / poor band |
| systemYellow | #FFCC00 | #FFD60A | Warning accents (never on white text) |
| systemTeal | #30B0C7 | #64D2FF | Secondary info accents |
| systemBlue | #007AFF | #0A84FF | Links, interactive tint |
| systemIndigo | #5856D6 | #5E5CE6 | AI/insight features |
| systemPurple | #AF52DE | #BF5AF2 | Premium/bento accents |
| systemPink | #FF2D55 | #FF375F | Reserved highlights |
| systemGray → gray6 | #8E8E93 / #AEAEB2 / #C7C7CC / #D1D1D6 / #E5E5EA / #F2F2F7 | #8E8E93 / #636366 / #48484A / #3A3A3C / #2C2C2E / #1C1C1E | Neutral chrome ramp |

**GutGood brand note →** keep current `green #1F7A3D` *only* as the brand mark/logo tint; **UI accent adopts systemGreen ramp** so light/dark auto-adapt. Score bands map: Excellent→systemGreen, Good→teal, Fair→orange, Poor→red (one-line change in `GutScoreBand` colors — token change only, no logic).

### 3.3 Accessibility

- 4.5:1 contrast for all text; 3:1 for non-text indicators (score ring arcs).
- Never encode meaning by color alone — pair with icon + word (already satisfied by band labels).

---

## 4. Spacing — 8pt grid, 4pt subdivisions

HIG-matching convention used by every market iOS kit:

| Token | Value | Use |
|---|---|---|
| `xxs` | 4 | icon↔label micro-gap |
| `xs` | 8 | inline element gap, chip padding-v |
| `sm` | 12 | card inner vertical rhythm |
| `md` | 16 | **screen edge padding** (standard), card padding |
| `lg` | 20 | between sibling cards |
| `xl` | 24 | section separation |
| `xxl` | 32 | major sections, sheet tops |
| `xxxl` | 40 | hero whitespace |

GutGood mapping: `AppSizes.p4…p40` **values stay**, keypads pad screens at **16 not 20**. Full-width content respects `SafeArea`; bottom content clears tab bar + home indicator (≥ 34).

**Tap targets: ≥ 44×44pt, always.** Sliders/checkboxes/toggles included.

---

## 5. Radius — continuous corners ("squircle" feel)

iOS uses *continuous* corners. Flutter: `SmoothBorderRadius`/approximate with `BorderRadius` + `smooth` packages, or accept standard radius (visually close at these sizes).

| Component | Radius |
|---|---|
| Small chips / pills | **capsule** (height/2) or 8 |
| Buttons (filled, 50pt) | 12–14 |
| Cards (bento, insights) | 12 (**iOS list cards**) → 16 for hero cards |
| Image thumbnails in rows | 8 |
| Score ring/gauge container | 16–20 |
| Sheets (detached modals) | 12 top corners (attached: 14) |
| Nav/tab bar | 0 (rectangular chrome) |
| Input fields | 10–12 |
| Alerts | 14 |

GutGood mapping: standardize on **`r8` thumbs, `r12` buttons/cards, `r16` hero cards + sheets**; retire `r28/r32` on cards (keep for pills/score dial).

---

## 6. Materials, blur & shadows

- **Chrome (nav/tab/sheet behind-content):** `BackdropFilter` blur σ=20–30 + background at 80–88% opacity (the 2025 *Liquid Glass* look needs `dart:ui ImageFilter` or `flutter_liquid_glass`-style package on custom chrome; start with standard blur).
- **Cards on grouped backgrounds:** **no shadow** — separation via fill contrast (white card on #F2F2F7) or 0.5pt hairline stroke.
- **Floating element (FAB, sticky CTA):** `shadow blur 16, y 4, alpha 0.08` max — iOS depth is subtle.
- Dark mode: **no drop shadows ever** — use lighter surface fills.

---

## 7. Components

| Component | Spec |
|---|---|
| **Nav bar** | 44pt content height (56 with large title 96pt collapse); title Headline 17 semibold; large-title variant 34pt left-aligned collapsing on scroll; trailing icons 24pt, touch 44 |
| **Tab bar** | 49pt + home indicator; 5 max; icons 24–25pt (selected filled), labels Caption 2 (10→11pt); blur + hairline |
| **Filled button** | height 50pt (compact 36–40), radius 12–14, label Headline 17 semibold, fill systemGreen; pressed opacity .85 |
| **List row** | ≥ 44pt, label Body 17, secondary Subhead 15 `secondaryLabel`, 8pt thumb corner, chevron `›` 14pt gray3; grouped style radius 12 container |
| **Toggle** | 51×31 capsule, green on-state (CupertinoSwitch) |
| **Sheet** | treated as attached modal: top radius 14, drag affordance 36×5 grabber @30% label, detents .5/.9; GutGood scan sheet keeps two-section layout, adopts chrome |
| **Alert** | radius 14, blur, title Headline 17 semibold, message Footnote 13, buttons horizontally split with 0.5pt separators |
| **Toast/snackbar** | dark pill bottom-floating: fill `label` color, text Background color, radius 24 capsule |
| **Score ring** | stroke 10–12pt, round caps, band color, Footnote label, Title-3 score inside |

---

## 8. Motion & haptics

- Durations: 250–350 ms, `Curves.easeOutCubic` (iOS-like); inline sheet/modal springs `withSpring` (damping 20, stiffness 180).
- Haptics: `selectionClick` on pickers/tabs, `lightImpact` on button press, `mediumImpact` on destructive, success/error `notification` after async resolve. (GutGood already routes through `HapticHelper` — map its levels to these.)

---

## 9. Do / Don't

- ✅ Token classes (`AppTextStyles`, `AppPalette`, `AppSizes`) everywhere.
- ✅ One accent color per screen; semantic bands only for status.
- ✅ 44pt targets, blur chrome, hairline separators, 12pt card radius.
- ❌ No glassmorphism *content* cards (that's chrome-only), no gradient text, no shadows in dark mode.
- ❌ No hardcoded `fontSize: x.sp`, `Color(0x…)`, or `EdgeInsets.all(…)` literals in feature code.
- ❌ No text styles outside the 11-row HIG table — extend by alias, never by new magic sizes.

---

## 10. Migration map (current GutGood → iOS tokens)

| Current | iOS target | Action |
|---|---|---|
| `displaySm 34` | Large Title 34 | keep, reweight w800→w700 |
| `headingLg 28 / Md 24→22 / Sm 20` | Title 1/2/3 | adjust Md 24→22 |
| `body 15`, `bodySm 13` | Callout 16 / Footnote 13 | `body` 15→16 long-term |
| `caption 10`, `captionBold 8.5`, tiny/micro | Caption 1 (12) / Caption 2 (11) | retire below-11pt styles |
| `eyebrow 10sp ls1.5` → | Caption 1 12 w600 ls0.5 caps | update settings + cards |
| Card r28–r32 | r12 (standard) / r16 (hero) | normalize via AppSizes |
| Brand green #1F7A3D everywhere | systemGreen #34C759/#30D158 UI; brand green = logo/mark only | token-swap in palette |
| Android shadows on cards | hairline or none | remove in AppTheme card theme |
| screen padding p20 | p16 | per-screen sweep |

*Breaking change policy: token-only edits ship in one sweep per screen; no screen mixes old + new radius/type.*
