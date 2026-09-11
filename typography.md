# GutGood — Typography Design System

> **Primary Font Family:** `Inter Tight`  
> **Fallback Stack:** `-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif`  
> **Source:** [Google Fonts — Inter Tight](https://fonts.google.com/specimen/Inter+Tight)

```html
@import url("https://fonts.googleapis.com/css2?family=Inter+Tight:wght@300;400;500;600;700;800&display=swap");
```

---

## 1. Type Scale & Hierarchy

| Level | Size | Weight | Line Height | Letter Spacing | Use Case | CSS Example |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Hero Score (Large)** | `68px` | `300` (Light) | `0.90` | `-0.06em` | Main standout GutGood Score figure | `font-size: 68px; font-weight: 300; letter-spacing: -0.06em; line-height: .9;` |
| **Hero Score (Medium)** | `48px` | `300` (Light) | `0.95` | `-0.05em` | Detail screen metrics & weekly averages | `font-size: 48px; font-weight: 300; letter-spacing: -0.05em; line-height: .95;` |
| **Ring Gauge Score** | `30px` | `300` (Light) | `0.92` | `-0.05em` | Circular scan result score (e.g. `65/100`) | `font-size: 30px; font-weight: 300; letter-spacing: -0.05em;` |
| **Screen Title (Display)** | `28px` | `300` (Light) | `1.00` | `-0.04em` | Main screen titles (`Insights.`, `Discover.`) | `font-size: 28px; font-weight: 300; letter-spacing: -0.04em;` |
| **Appbar Brand Title** | `18px` | `800` (ExtraBold)| `1.00` | `0.01em` | Standard navigation bar header (`GUTGOOD`) | `font-size: 18px; font-weight: 800; letter-spacing: .01em; text-transform: uppercase;` |
| **Food / Card Hero Title** | `19px` | `700` (Bold) | `1.20` | `-0.03em` | Food titles (`Fried Fish Meal`, `Pattern Title`) | `font-size: 19px; font-weight: 700; letter-spacing: -0.03em; line-height: 1.2;` |
| **Story / Bento Card Title**| `17px` | `600` (SemiBold)| `1.25` | `-0.03em` | Bento card headlines & discoveries | `font-size: 17px; font-weight: 600; letter-spacing: -0.03em; line-height: 1.25;` |
| **Section Header** | `16px` | `700` (Bold) | `1.20` | `-0.025em`| `What's Working`, `What to Watch`, `Better Swaps` | `font-size: 16px; font-weight: 700; letter-spacing: -0.025em;` |
| **Item / Row Title** | `14px` | `600` (SemiBold)| `1.30` | `-0.01em` | Nutrient titles (`Protein`, `Sodium`, `Fiber`) | `font-size: 14px; font-weight: 600; letter-spacing: -0.01em;` |
| **Metric Value (Tabular)** | `14px` | `600` (SemiBold)| `1.00` | `-0.02em` | Delta badges (`+18%`, `900mg`, `800 Cal`) | `font-size: 14px; font-weight: 600; font-variant-numeric: tabular-nums;` |
| **Body Copy** | `13px` | `400` (Regular) | `1.48` | `normal` | Explanations, microbiome insights | `font-size: 13px; font-weight: 400; line-height: 1.48;` |
| **Secondary Description** | `12px` | `400` (Regular) | `1.40` | `normal` | Sub-labels, ingredients list, swap subtext | `font-size: 12px; font-weight: 400; line-height: 1.4; color: #6B7280;` |
| **Action Link / Buttons** | `13.5px`| `600` (SemiBold)| `1.00` | `0.01em` | Primary buttons (`Add to Food Log`, `Scan`) | `font-size: 13.5px; font-weight: 600; letter-spacing: .01em;` |
| **Micro Tracker / Eyebrow**| `9.5px` | `700` (Bold) | `1.00` | `0.20em` | Uppercase category tags (`GUTGOOD`, `NOVA`) | `font-size: 9.5px; font-weight: 700; letter-spacing: .20em; text-transform: uppercase;` |
| **Bottom Tab Label** | `10px` | `500` / `700` | `1.00` | `0.02em` | Bottom navigation bar items (`Insights`) | `font-size: 10px; font-weight: 500; (700 when active);` |

---

## 2. Font Weights Guide

### `300 — Light`
- **Purpose:** Elegant, sculpted human figures and centerpiece data points.
- **Used for:** Large numerical scores (`50`, `65`, `68`), sparkline peaks, display headlines (`Insights.`, `Recap.`).
- **Styling note:** Pair with negative letter-spacing (`-0.05em`) and `font-variant-numeric: lining-nums tabular-nums`.

### `400 — Regular`
- **Purpose:** Maximum readability for body copy, food descriptions, and ingredient explanations.
- **Used for:** Body copy, biological impact notes, allergen lists, timestamps.

### `500 — Medium`
- **Purpose:** Secondary interactive elements and inactive tab states.
- **Used for:** Segment control tabs, inactive bottom navigation labels, subtle metadata.

### `600 — Semi-Bold`
- **Purpose:** Primary actionable content, card headlines, and nutrient values.
- **Used for:** Bento card headlines, nutrient names (`Protein`, `Sodium`), buttons, delta badges.

### `700 — Bold`
- **Purpose:** Strong structural hierarchy and section titles.
- **Used for:** Section headers (`What's Working`, `What to Watch`), category eyebrows, food titles.

### `800 — Extra-Bold`
- **Purpose:** Brand signatures and high-priority food platter headers.
- **Used for:** Top Appbar brand header (`GUTGOOD`), primary food item titles.

---

## 3. Letter-Spacing & Numerical Rules

### Micro-Tracking for Uppercase Labels
Always apply high tracking (spaced out letters) on small uppercase tags to ensure crisp legibility:
```css
.eyebrow-tag {
  font-size: 9.5px;
  font-weight: 700;
  letter-spacing: 0.20em; /* 20% to 24% letter-spacing */
  text-transform: uppercase;
}
```

### Negative Tracking for Large Figures
Large numerical display figures look sculpted and tight with negative letter-spacing:
```css
.score-hero-number {
  font-size: 68px;
  font-weight: 300;
  letter-spacing: -0.06em;
  line-height: 0.90;
  font-variant-numeric: lining-nums tabular-nums;
}
```

---

## 4. Color & Contrast System

```css
:root {
  /* Typography Colors */
  --t1: #111827; /* Primary Headline & Body: High-Contrast Charcoal/Black */
  --t2: #374151; /* Secondary Content: Deep Slate */
  --t3: #6B7280; /* Captions & Subtitles: Neutral Gray */
  --t4: #9CA3AF; /* Micro-Labels & Inactive Tabs: Muted Slate */

  /* Biological Accent Colors */
  --mint:   #10B981; /* Gut Boosters, High Fiber, Positive Impact */
  --coral:  #EF4444; /* High Sodium, Flare Triggers, Inflammatory */
  --gold:   #F59E0B; /* Moderate Impact, NOVA 3, Amber Warning */
  --orange: #EA580C; /* GutGood Brand Accent, Primary Eyebrows */
  --purple: #6366F1; /* AI Synergy, Circadian Sleep, Microbiome */
}
```

---

## 5. Ready-to-Use CSS Classes

```css
/* Font Family Root */
body {
  font-family: "Inter Tight", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  -webkit-font-smoothing: antialiased;
  text-rendering: optimizeLegibility;
}

/* Standout Score */
.score-number {
  font-size: 68px;
  font-weight: 300;
  letter-spacing: -0.06em;
  line-height: 0.9;
  color: var(--t1);
  font-variant-numeric: lining-nums tabular-nums;
}

/* Category Eyebrow */
.tag-eyebrow {
  font-size: 9.5px;
  font-weight: 700;
  letter-spacing: 0.2em;
  text-transform: uppercase;
  color: var(--orange);
}

/* Section Title */
.section-title {
  font-size: 16px;
  font-weight: 700;
  letter-spacing: -0.025em;
  color: var(--t1);
}

/* Body Copy */
.body-text {
  font-size: 13px;
  font-weight: 400;
  line-height: 1.48;
  color: var(--t2);
}

/* Tabular Metric Badge */
.metric-pill {
  font-size: 14px;
  font-weight: 600;
  letter-spacing: -0.02em;
  font-variant-numeric: tabular-nums;
}
```
