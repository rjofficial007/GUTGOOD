# Insights v2 — "Real Tokens" Redesign

Implements the `uploads/v2.html` design language across every insights-related
screen, with the AI pipeline extended to feed the new cards.

## What changed

### Design language (`lib/features/insights/presentation/widgets/v2/`)

The v2 language is quiet and editorial, replacing the v4 pastel-bento on the
Insights surfaces only (the rest of the app is untouched):

| Token | Value | Source |
|---|---|---|
| Scaffold | `#FCFCFD` | `:root --scaffold` |
| Card | `#FFFFFF` + hairline `#E4E4E8` (50%) + `0 1px 2px rgba(23,23,27,.04)` | `.card` |
| Ink | `#0A0A0A` / `#4A4E5A` / `#6E7280` | `--t1..t3` |
| Success | `#1F7A3D` on `#E7F6E7` | `--success` |
| Error | `#C4302B` on `#FFF1F0` | `--error` |
| Warning | `#FFAB40` on `#FFF4E5` | `--warning` |
| Purple / Lime | `#7C3AED` / `#D9FF30` | `--purple`, `--lime` |
| Radii | cards r20 · chips/tiles r14 · buttons r12 | mock system |
| Type | Inter Tight (body) + **Instrument Serif** (display) | `font-family:'Instrument Serif'` |

Files:
- `insight_v2_theme.dart` — `InsightV2Theme` ThemeExtension (light + derived dark), registered in `app_theme.dart`.
- `v2_kit.dart` — the component library: `V2Card`, `V2Badge`, `V2Pill`, `V2IconCircle`, `V2Stat`, `V2SectionLabel`, `V2RecCard`, `V2Timeline`, `V2PatternPill`, `V2FoodGrid`, `V2SwapRow`, `V2WhyList`, `V2DotPager`, `V2ScoreRing`, `V2TrendChart`, `V2StreakTicks`, `V2Button`.
- `v2_data.dart` — deterministic view-model derivations (AI blocks win, legacy-doc fallbacks always render).
- `insight_v2_strings.dart` — screen copy.
- `v2_feed.dart` — the feed (score hero, top-insight pager, What's Improving, Something to Watch, learning state).

### Screens rewired (same routes, new presentation)

| Screen | Route | New body |
|---|---|---|
| Insights tab | `/home/insights` | v2 header (serif *Insights*) + `V2InsightsFeed`; pre-threshold `V2InsightsLearning` |
| Insight detail (history) | `/insight-detail` | Same `V2InsightsFeed` fed a stored `AIInsight`, score window truncated at its date |
| Pattern details | `/pattern-detail` | Badge, "Trigger → Reaction" headline, frequency/confidence/window stats, common factors, occurrences timeline, recommendation |
| Top Healing / Trigger | `/highlight-detail` | "Your Gut Hero" / "Your Gut Saboteur" badge, food tile, timeframe/frequency stats, why-checklist, trend, alternatives CTA |
| Top Insight | `/smart-insight-detail` | Evidence row (frequency/match/symptomatic), observation, action plan, related patterns |
| Patterns / What's Working | `/patterns` | Working-food carousel, Top Foods grid, Patterns We Noticed pills |
| Weekly recap | `/weekly-recap` | Date range, ring + mini chart, best-day/logging stats, highlights, Your Actions, full-report CTA |
| Insight history | `/insight-history` | Quiet v2 history cards (serif score, hairline, real sparkline) |

### Flow changes

- Score hero → weekly recap (unchanged).
- Top-insight pager: swipe between the AI top pick and the strongest patterns; dots + tap-through to their detail screens.
- What's Improving card → **Healing Trend** detail (previously unreachable as its own flow).
- Something to Watch card → pattern pill/timeline/swap tap → **Pattern Details**.
- What's Working screen keeps healing-food → highlight-detail and adds pattern pills → pattern details.

### Data & AI (`schema v3`, all reads tolerant)

New optional blocks in `AIInsight` (`lib/core/models/insights/insight_v2_blocks.dart`):

- `improving` — headline/description/streak/key foods for the What's Improving card.
- `watch` — reactionTime / riskLevel / windowDays for the Something to Watch stats.
- `smartSwap` — the Before → After swap + tip.
- `topHealing/topTrigger.whyPoints` — the why-checklists.

`InsightsPrompt` (bumped to **v3**, `AiVersions.insightPromptVersion`) emits them
under strict evidence rules: reaction time must be the median of the pattern's
occurrences, risk bands off `evidenceRatio`, no invented percentages, streak ≤ 30.

**Nothing blocks on regeneration**: every AI value has a deterministic Dart
fallback (`V2Data`) computed from `healingFoods`, `detectedPatterns`,
occurrences and score history — legacy docs render the same UI immediately.

## Verification

`flutter analyze` clean at time of writing; prompt version stamped `3` on new
insights, legacy docs (`v2` and older) parse untouched.
