# 4. Frontend & Integration Specification

> **Design System Basis:** Apple Human Interface Guidelines (HIG) adapted to Flutter
> **Theme Engine:** `AppPalette` + `AppColorScheme` (`ThemeExtension`)
> **Bento Typography:** Bundled `InterTight` Variable Font Family
> **Current source alignment:** 2026-10-03
> **Document Purpose:** Complete frontend design tokens, component ownership, layout specifications, and external integration contracts.

---

## 1. Color Palette & Adaptive Semantic Tokens

GutGood uses a centralized atomic color palette (`AppPalette`) mapped to a reactive `AppColorScheme` `ThemeExtension` accessible via `context.appColorScheme`. It automatically adapts across Light and Dark theme modes.

### 1.1 Atomic Palette (`AppPalette`)

| Token Name | Hex Value | Usage Context |
|---|---|---|
| `white` | `#FFFFFF` | Light cards, primary background, dark text |
| `black` | `#0A0A0A` | Light text primary, dark primary surface |
| `gray25` / `gray50` | `#FCFCFD` / `#F7F7F8` | Light secondary background, input fills |
| `gray100` / `gray200` | `#F0F0F2` / `#E4E4E8` | Light list dividers, borders, shimmer base |
| `gray400` / `gray500` | `#9CA0AB` / `#6E7280` | Muted text, disabled icons |
| `gray600` / `gray700` | `#4A4E5A` / `#2D3039` | Subtitles, dark borders |
| `gray800` | `#1A1C22` | Dark shimmer base, elevated dark fills |
| `darkPrimary` | `#000000` | Dark theme main background |
| `darkCard` | `#0D0D0D` | Dark card fill |
| `darkElevated` | `#1A1A1A` | Dark AI response bubble & floating container |
| `darkBorder` | `#1F1F1F` | Dark theme subtle hairline borders |

---

### 1.2 Reactive Theme Scheme (`AppColorScheme`)

Accessible via `context.appColorScheme`:

| Semantic Token | Light Mode Value | Dark Mode Value | Application |
|---|---|---|---|
| **`screenBackground`** | `#F4F5F7` | `#000000` | Full-screen canvas background |
| **`cardBackground`** | `#FFFFFF` | `#000000` | Primary list cards & grouped containers |
| **`elevatedSurface`** | `#FFFFFF` | `#0D0D0D` | Floating sheets, modals, hero cards |
| **`aiResponseBackground`** | `#F7F7F7` | `#1A1A1A` | AI Chat response bubble background |
| **`textPrimary`** | `#0A0A0A` | `#F5F7FA` | Primary headings, body copy |
| **`textSecondary`** | `#4A4E5A` | `#B8C0CC` | Subtitles, section headers, timestamps |
| **`textMuted`** | `#6E7280` | `#8D96A5` | Placeholder text, secondary details |
| **`border`** | `#E4E4E8` | `#1F1F1F` | 0.5pt hairline dividers and card borders |
| **`borderSubtle`** | `rgba(228,228,232, 0.50)` | `rgba(31,31,31, 0.50)` | Subtle inner card dividers |
| **`success`** | `#1F7A3D` | `#22C55E` | Positive status, excellent score band, primary CTA |
| **`softSuccess`** | `#E7F6E7` | `#1E3A1E` | Light green badge fill |
| **`error`** | `#C4302B` | `#C4302B` | Poor health band, high risk additives, delete actions |
| **`softError`** | `#FFF1F0` | `#3A1E1E` | Light red badge fill |
| **`warning`** | `#FFAB40` | `#FFAB40` | Fair health band, moderate risk additives |
| **`softWarning`** | `#FFF4E5` | `#3A2A1E` | Light orange badge fill |
| **`info`** | `#1D4ED8` | `#1D4ED8` | Educational links, informational badges |
| **`lavender`** | `#F1F0FF` | `#2A2E3A` | AI highlight cards, feature callouts |

---

## 2. Typography Specification

### 2.1 Standard UI Typography (`AppTextStyles`)
Primary UI adheres to the iOS Dynamic Type scale:

| Style Name | Size (pt) | Weight | Line Height | Application |
|---|---|---|---|---|
| `displaySm` | 34pt | Bold (w700) | 41pt | Large Screen Titles |
| `headingLg` | 28pt | Bold (w700) | 34pt | Primary Section Headers |
| `headingMd` | 22pt | Bold (w700) | 28pt | Card Titles, Sheet Headers |
| `headingSm` | 20pt | Semibold (w600) | 25pt | Sub-headers, Dialog Titles |
| `headline` | 17pt | Semibold (w600) | 22pt | List Row Titles, Button Labels |
| `bodyLg` | 17pt | Regular (w400) | 22pt | **Primary Reading Floor** |
| `body` | 16pt | Regular (w400) | 21pt | Callouts, Input Text |
| `bodySm` | 15pt | Regular (w400) | 20pt | Subhead Info, Secondary Lists |
| `label` | 13pt | Regular (w400) | 18pt | Footnotes, Meta Information |
| `caption` | 12pt | Regular (w400) | 16pt | Eyebrow Labels, Badges |
| `caption2` | 11pt | Regular (w400) | 13pt | Micro Badges, Timestamps |

### 2.2 Bento Insights Typography (`InterTight`)
For the dynamic Insights bento grid, GutGood uses bundled `InterTight` variable font weights (`assets/fonts/InterTight-*.ttf`):
* `InterTight-Light` (300)
* `InterTight-Regular` (400)
* `InterTight-Medium` (500)
* `InterTight-SemiBold` (600)
* `InterTight-Bold` (700)
* `InterTight-ExtraBold` (800)

### 2.3 Dynamic Type Guardrails
To prevent UI clipping while honoring accessibility settings:
```dart
MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.35)
```

---

## 3. Core Component Architecture

```
                                    [GutGood UI System]
                                             │
      ┌────────────────────┬─────────────────┼─────────────────┬───────────────────┐
      ▼                    ▼                 ▼                 ▼                   ▼
 [GutAppBar]         [GutTextField]   [GutSectionCard]   [InsightsFeed]     [OfflineBanner]
 • Frosted Glass     • Focus Border   • 12pt Radius       • Modular Grid    • Non-blocking
 • Dynamic Title     • Clear Button   • Hairline Stroke   • InterTight Type • Connection Alert
```

### 3.1 `GutAppBar`
* **Style:** iOS-native frosted glass top bar utilizing `BackdropFilter` with blur σ=25 and 85% background opacity.
* **Behavior:** Seamless title collapse when scrolled under a large title header.

### 3.2 `GutTextField` & `GutSearchField`
* **Border States:** 1pt `gray200` default border; 2pt `success` border on active focus; 1.5pt `error` border on validation error.
* **Affordances:** Integrated trailing clear button (`X`) and prefix icon slot.

### 3.3 `GutSection` & `GutSectionCard`
* **Card Radius:** Standardized `12pt` continuous rounded border (`BorderRadius.circular(12)`).
* **Border Stroke:** 0.5pt hairline border (`borderSubtle`).
* **Padding:** 16pt horizontal, 12pt vertical inner padding.

### 3.4 `InsightsFeed`, Bento cards, and semantic feed widgets
* **Feed shell:** `lib/features/insights/presentation/widgets/insight_feed/insights_feed.dart` and `insights_feed_shell.dart` own the current semantic Insights feed.
* **Deterministic view models:** `InsightFeedDerivations` builds improving/watch data and applies deterministic fallbacks before widgets render.
* **Bento surfaces:** `lib/features/insights/presentation/widgets/bento/` owns the separate Bento cards, charts, recap, history, and pattern screens.
* **Grid spans:** Supports compact metrics, horizontal patterns, and hero Gut Score/experiment blocks.
* **Theme styling:** Uses `InterTight` typography and shared `InsightTheme` / `InsightBentoTheme` extensions. No standalone legacy-version widget path is retained.

### 3.5 `ScannerOverlay`
* **Visuals:** Camera viewfinder with rounded corner target guides, active scanning laser line animation, and flash toggle button.

### 3.6 `OfflineBanner` & `VerificationOverlay`
* **OfflineBanner:** Top floating banner indicating lost internet connectivity without obstructing app usage.
* **VerificationOverlay:** Full-screen translucent blur modal indicating guest account migration or secure operation processing.

### 3.7 Ownership and import rules

- App-wide tokens and reusable core widgets live under `lib/core/`.
- Insights-only cards, feed derivations, pages, and presentation parts live under `lib/features/insights/presentation/`.
- The app theme is registered from `lib/app/theme/app_theme.dart`, which is the canonical theme composition path.
- Import semantic canonical paths directly. Do not add export-only compatibility files when moving a widget or model.

---

## 4. Spacing & Layout Architecture

### 4.1 8pt Grid System (`AppSizes`)

| Token | Size | Application |
|---|---|---|
| `p4` / `xxs` | 4pt | Icon-to-text micro gap |
| `p8` / `xs` | 8pt | Inline chip spacing, small gaps |
| `p12` / `sm` | 12pt | Card vertical inner rhythm |
| `p16` / `md` | 16pt | **Standard screen margin** & primary padding |
| `p20` / `lg` | 20pt | Section separation margin |
| `p24` / `xl` | 24pt | Hero section padding |
| `p32` / `xxl` | 32pt | Modal sheet top margin |

### 4.2 Minimum Touch Targets
* **Rule:** All interactive buttons, switches, checkboxes, and chips must maintain a minimum touch target area of **44×44pt**.

---

## 5. API & Integration Contracts

### 5.1 Cloud Function `aiProxy` Contract

#### HTTPS Endpoint:
`POST https://[region]-[project].cloudfunctions.net/aiProxy`

#### Headers:
```http
Authorization: Bearer <Firebase_ID_Token>
Content-Type: application/json
```

#### Request Payload:
```json
{
  "mode": "stream",
  "systemInstruction": "You are GutGood AI...",
  "messages": [
    { "role": "user", "content": "Logged lunch: grilled salmon salad." }
  ],
  "userText": "What should I know about it?",
  "images": [],
  "model": "gpt-4o-mini",
  "usageType": "chat",
  "idempotencyKey": "uuid",
  "timezoneOffset": 330,
  "promptVersion": 1
}
```

#### Response Stream (Server-Sent Events):
```text
data: {"d":"Grilled salmon is rich in Omega-3..."}

data: {"promptVersion":1,"model":"gpt-4o-mini"}

data: [DONE]
```

The Flutter implementation for this contract is `AiProxyClient` in `lib/infrastructure/ai/ai_proxy_client.dart`. It resets truncation/version metadata per request, retries safe transient failures, maps quota/auth errors to typed exceptions, and records the proxy's `promptVersion` and serving model echoes.

---

### 5.2 Open Food Facts API Contract

#### Endpoint:
`GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json`

#### Response Field Mapping:
```json
{
  "status": 1,
  "product": {
    "product_name": "Organic Almond Milk",
    "brands": "Clean Brand",
    "image_front_url": "https://images.openfoodfacts.org/...",
    "nova_group": 1,
    "additives_tags": ["en:e322", "en:e415"],
    "ingredients_text": "Filtered water, organic almonds, sea salt."
  }
}
```

---

### 5.3 RevenueCat Entitlements Integration Contract

```
[User Selects Plan on Paywall]
            │
            ▼
[RevenueCat SDK Purchases Offering]
            │
            ├── SUCCESS ──> Entitlement "gutgood_premium" Active
            │                     │
            │                     ├── Update `PurchaseProvider`
            │                     └── Sync `isPremium: true` to `user_profiles/{uid}`
            │
            └── CANCEL / FAIL ──> Display User Friendly Error Message
```
