# GutGood — Design System & UX Transformation Review

**Role:** Staff Flutter Engineer · Product Designer · Motion Designer · Product Strategist
**Date:** 2026-08-02
**Approach:** Evolve, don't fragment. The existing architecture (Clean Architecture, Provider+GetIt, race-free chat, server-side merge) is genuinely strong. The gaps are at the **design-language foundation** and in **per-screen craft**. This turn ships the foundation + motion + core components + a runnable showcase, and lays out the per-screen plan.

---

## 0. What shipped in this pass (runnable today)

| File | What it is |
|---|---|
| `core/theme/app_palette.dart` | **+** Botanical "wellness" brand scale (brand50–950), semantic container tints, skeleton, scrim/shadow |
| `core/theme/app_color_scheme.dart` | Rewritten: +16 semantic tokens (brand, containers, skeleton, shadow, scrim) with correct `lerp` for light/dark |
| `core/theme/app_design_tokens.dart` | **New** — `AppSpacing` (4-pt grid), `AppRadii`, `AppElevation` (theme-aware 0–5), `AppInsets` |
| `core/theme/app_motion.dart` | **New** — `AppDurations`/`AppCurves` + `Pressable`, `FadeSlideIn`, `AnimatedCount`, `GutSkeleton`, `PulseDot`, `AnimatedBar` |
| `core/theme/app_text_styles.dart` | **Fixed** — dropped `.sp` so OS text-scaling works (was an a11y defect) |
| `core/widgets/gut_button.dart` | Refactored: press-scale, variant/size system, real states, semantics (+ `GutIconButton`) |
| `core/widgets/gut_card.dart` | **New** — unified premium card w/ elevation tokens + interactive variant |
| `core/widgets/gut_chip.dart` | Upgraded: animated selection, semantics, sizes |
| `core/widgets/empty_state_widget.dart` | Upgraded: tinted badge, hierarchy, entrance animation, CTA |
| `core/widgets/design_system_showcase.dart` | **New** — live gallery at `/design-system` (debug) |
| `core/router/*` | Wired the debug showcase route |

**Verify it:** `flutter run` → navigate to `/design-system` (debug builds). Toggle light/dark to see the whole system adapt.
**Tidy lints:** run `dart fix --apply && flutter analyze` — the new debug gallery will pick up trivial `const` suggestions; all production files are already const-clean.

---

## 1. The systemic problems (root causes of every "inconsistency")

These four foundation issues are why the app feels "good but not premium." Fixing them propagates quality to every screen.

### 1.1 The `.w/.h/.sp` scaler fights accessibility *and* tablets · **critical a11y bug**
`Responsive` scales every dimension by `screenWidth/393` (and `.sp` by `min(W,H)`). Consequences:
- **Text scaling is overridden.** `.sp` ignores `MediaQuery.textScaler`, so the user's OS "Larger Text" setting does nothing. The app claims to respect Dynamic Type — it doesn't.
- **Text is *shrunk* on small/short phones.** On an iPhone SE (375×667) `.sp = min(0.954, 0.782) = 0.78` → **22% smaller text**. Captions become unreadable.
- **Tablets get a stretched phone**, not a reflow. Everything scales up 1.6–2× instead of gaining columns/content.

**Fix (done for the type scale; rest is migration):** use logical dp. Flutter's `Text` already multiplies `fontSize` by the system scaler — so plain dp "just works" for a11y. I migrated `AppTextStyles` off `.sp`. Next: migrate `AppSizes` consumers to `AppSpacing`/`AppRadii` and remove `.w/.h` from layout, reserving `MediaQuery` + `LayoutBuilder` for genuine breakpoints (see §6).

### 1.2 No elevation/shadow system
Shadows were hand-rolled ad-hoc (`BoxShadow(black @ 0.02, blur 10)`). Premium UI = soft, low, intentional depth + hairline borders, never Material's heavy default drops. **Added:** `AppElevation.of(ctx, 0..5)` — theme-aware (shadows tuned stronger in dark where surfaces still register depth; pairs with borders).

### 1.3 No motion system
Durations/curves were hardcoded everywhere (200, 300, 60 ms; various curves). Inconsistent timing reads as "cheap." **Added:** `AppDurations`/`AppCurves` + reusable primitives so every entrance, press, and transition shares one hand.

### 1.4 Thin brand identity for a *wellness* product
The monochrome black/white + green reads "fintech/Linear," not "calm gut-health companion." It's actually good and modern — so I kept it as the structural system and layered a **Botanical Wellness** green tonal scale + semantic containers on top, used for health scores, success, identity moments and highlights. Adopting it is a one-line theme change; existing screens keep working.

---

## 2. The Design System (spec)

**Spacing** — strict 4-pt grid: `2 · 4 · 6 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64`. Page gutter = 20.
**Radii** — `4 · 8 · 12 · 16 · 20 · 24 · 32 · pill`. Semantic: input/button=16, chip=12, card=20, sheet/dialog=32.
**Elevation** — 0 flat · 1 sticky · 2 card · 3 raised · 4 FAB · 5 modal. Always pair a card with its hairline border.
**Motion** — instant 100 · quick 160 · standard 250 · smooth 380 · slow 520 ms. `easeOutCubic` for entrances; `easeInCubic` for exits; reserved spring for playful moments.
**Type** — display 34–56 / heading 20–28 / title 17 / body 13–16 / label 13 / caption 12 / eyebrow 11. Tight negative tracking on display (premium optical). System text-scaler respected.
**Color** — neutral surfaces + 10-step brand green + 4 semantic pairs (fg + tinted container) + skeleton pair. Every color is theme-aware; never hardcode hex in a widget.

---

## 3. Screen-by-screen review (issues → fixes)

> Priority order = user exposure × cost to fix. Each ties back to the new system.

### 3.1 Chat (`features/chat/presentation/pages/chat_screen.dart`) — the hero screen
**Good:** ChatGPT composer, race-free optimistic merge, coalesced streaming, draft persistence, stop/regenerate. This is genuinely well-built.
**Issues:**
- **Composer lacks press-feedback.** Send/stop/camera are bare `GestureDetector`s with no tactile response. → Wrap in `Pressable` (and adopt `GutIconButton`). Biggest perceived-quality win on the most-used screen.
- **Typing indicator is a text hint ("Thinking…").** → 3-dot `PulseDot` row; feels alive.
- **Suggestion chips are static containers** (`_Chip`). → Use `GutChip` (animated, haptic, consistent).
- **Empty state is a mascot image + two lines.** → Use the upgraded `EmptyStateWidget` with a starter CTA ("Ask about bloating").
- **Snackbars are raw** for errors/offline. → Add a themed toast/snackbar helper (see §4).
- **`.w/.h`-scaled paddings** → migrate to `AppSpacing`.

### 3.2 Insights / Dashboard (`insights_screen.dart`)
**Good:** dashboard-card pattern, shimmer loaders, staggered entrances (`DashboardEntrance`), rich data model.
**Issues:**
- **`DashboardVisualizationBar` is static** with hardcoded ratios (0.65, 0.8, 0.4…). These aren't real metrics → misleading + flat. → Replace with `AnimatedBar(progress:)` bound to *actual* data; if a ratio is meaningful, compute it.
- **Section titles are oversized display words** ("FOCUS", "HEAL", "TRENDS" at `s28` w900). Striking but low information density and hard to scan. → Keep the editorial word as an accent but pair with a clear label.
- **Big "GOT IT, THANKS" button** in every detail sheet repeats. → Standardize via a sheet footer helper.
- **Hardcoded `letterSpacing: -1`/`-1.0`** all over → use the type scale.
- **Score gauge/sparkline** (gut_score_gauge, gut_trend_sparkline): wrap the score in `AnimatedCount` so it counts up on load; animate the sparkline draw-on.

### 3.3 Profile (`profile_screen.dart`) + settings sub-screens
- **Group settings into `GutCard` sections** with consistent dividers; today they're a mix of tiles and raw rows.
- **Add toggles with animated thumbs** (cycle sync, notifications) — replace plain `Switch` with a styled `GutSwitchTile` (pressable row + animated switch).
- **Account actions (delete/sign out)** need a **confirmation dialog** with clear destructive styling (`GutButton` danger variant) — currently fire-and-forget.

### 3.4 Onboarding & Welcome (`onboarding_screen.dart`, `welcome_screen.dart`)
- Onboarding is the **highest-leverage "premium feel" moment** and the first impression. → Page transitions with shared-element/FadeSlideIn, a progress indicator that animates, selection chips via `GutChip`, and a final "success" celebration.
- Auth bottom sheets → upgrade to the new sheet tokens (radius 32, scrim, spring entry).

### 3.5 Scanner (`super_scanner_screen.dart`, `scanning_animation_screen.dart`, `manual_barcode_screen.dart`)
- The **scanning animation** is the product's "magic" moment — make it feel premium: a custom-painted targeting reticle, animated gradient overlay, and a satisfying success lottie/rive when a product resolves.
- Manual barcode entry → `GutTextField` with focus glow + numeric keyboard + live validation.
- Result screen (`scan_result_screen.dart`) → hero `AnimatedCount` for the gut score, color-coded ingredient chips via semantic containers, animated swap cards.

### 3.6 History & Saved Foods (`scan_history_screen.dart`, `saved_foods_screen.dart`)
- Use `SliverAnimatedList` for insert/remove animations (premium list feel).
- Empty states → upgraded `EmptyStateWidget` with a "Scan your first product" CTA.
- Add **pull-to-refresh** with the brand color.

---

## 4. Cross-cutting upgrades to build next (small, high-impact)

1. **Toast/Snackbar system** — themed, with success/error/info variants + icons + swipe-to-dismiss. Replaces ~10 raw `SnackBar` calls.
2. **Confirmation dialog** helper — title/body/destructive vs. confirm, animated scale-in.
3. **`GutBottomSheet` refresh** — spring entry, drag handle, rounded 32 top, scrim fade, safe-area padding. (Existing sheet works; this raises the bar.)
4. **`GutSwitchTile`** — animated toggle row for all settings.
5. **Page transition theme** — add a `FadeSlidePage` to `GoRouter` (`pageBuilder`) so every route push feels intentional.
6. **Shimmer migration** — replace the `shimmer` package usages with `GutSkeleton` (theme-aware, no dependency).

---

## 5. Accessibility checklist (target state)

- ✅ Type now respects system scaler (`.sp` removed from the scale).
- ⬜ Touch targets ≥ 44×44 everywhere (audit `IconButton`s — many are 22–28 px).
- ⬜ `Semantics` labels on all icon-only actions (chat send/stop have them; scanner/profile actions don't).
- ⬜ Contrast: eyebrow/caption on `textMuted` needs checking vs. AA on light surfaces (the type-size bump to 12 helps).
- ⬜ Focus traversal order on forms (login, manual barcode, goals/sensitivities selection).
- ⬜ Reduce-motion: gate the new motion behind `MediaQuery.disableAnimations` (add to `FadeSlideIn`/`Pressable`).

---

## 6. Performance notes

- **Tablet/landscape:** replace `.w/.h` scaling with `LayoutBuilder` breakpoints → multi-column grids (history, insights) on width ≥ 700. Today a tablet is a stretched phone.
- **`const` everything:** the new components are const-constructible; keep call sites const where args allow (cuts rebuilds).
- **Skeleton count:** `GutSkeleton` runs an always-on ticker — cap concurrent skeletons (~6) to avoid GPU overdraw on long lists.
- **Streaming rebuilds:** already coalesced at 16 fps in `ChatNotifier` (good). Keep `findChildIndexCallback` on the message sliver (present).
- **Image caching:** `cached_network_image` is wired; ensure scan/food thumbnails use it (not raw `Image.network`).

---

## 7. Migration roadmap (phased, non-breaking)

- **Phase 1 ✅ (this pass):** tokens, motion kit, core components, showcase, type-a11y fix.
- **Phase 2 (next):** Chat composer (`Pressable`/`GutIconButton`/`GutChip`, animated typing), Insights (`AnimatedBar`, `AnimatedCount`), toasts + confirmation dialogs, sheet refresh.
- **Phase 3:** Onboarding redesign (transitions, success), Scanner "magic" moment, Profile grouping + `GutSwitchTile`.
- **Phase 4:** Tablet/landscape breakpoints, full `AppSizes → AppSpacing` migration, remove `.w/.h`, a11y pass, reduce-motion gates.

Each phase is independently shippable and touches only the files in scope — no big-bang rewrite.

---

*All additions are additive and backward-compatible: existing call sites of `GutButton`, `GutChip`, `EmptyStateWidget`, and the type/color extensions compile unchanged. Run `dart fix --apply && flutter analyze` to normalize style, then open `/design-system` to see the system live.*
