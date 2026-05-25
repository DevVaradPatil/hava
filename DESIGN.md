# Hava — Design System

## Design Identity

**Neo-Minimal Ambient Intelligence UI**

Dark-first, glass-morphism, ambient AQI-responsive gradients.
The interface communicates air quality through color, motion, and atmosphere
rather than dense data tables.

Core principles:
- Calm, breathable, recommendation-first
- Data through feeling — color & motion over numbers
- Professional minimalism with generous whitespace
- Ambient intelligence — the UI adapts to air quality state

---

## Color System

### Neutrals — Dark Mode (Primary)

| Token              | Hex       | Usage                     |
|--------------------|-----------|---------------------------|
| darkBackground     | `#08090C` | App background            |
| darkSurface        | `#111318` | Cards, containers         |
| darkSurfaceVariant | `#1A1D24` | Secondary surfaces        |
| darkTextPrimary    | `#F0F2F5` | Headlines, values         |
| darkTextSecondary  | `#8A919E` | Body text, labels         |
| darkTextTertiary   | `#565C68` | Hints, disabled           |
| darkGlassBorder    | `#FFFFFF` @ 6% | Glass card borders   |

### Neutrals — Light Mode

| Token              | Hex       | Usage                     |
|--------------------|-----------|---------------------------|
| lightBackground    | `#F8F9FB` | App background            |
| lightSurface       | `#FFFFFF` | Cards, containers         |
| lightTextPrimary   | `#0F1419` | Headlines, values         |
| lightTextSecondary | `#5B6170` | Body text, labels         |

### AQI State Gradients

Each AQI band has a primary + secondary color for gradients:

| Band                    | Primary   | Secondary |
|-------------------------|-----------|-----------|
| Good (0-50)             | `#34D399` | `#22D3EE` |
| Moderate (51-100)       | `#FBBF24` | `#F59E0B` |
| USG (101-150)           | `#FB923C` | `#F97316` |
| Unhealthy (151-200)     | `#FB7185` | `#F43F5E` |
| Very Unhealthy (201-300)| `#A78BFA` | `#8B5CF6` |
| Hazardous (301+)        | `#E11D48` | `#BE123C` |

### Accent

- Primary accent: `#3B82F6` (blue) — interactive elements, indicators

---

## Typography

- Font: Inter (Google Fonts, variable weight)
- Display: 52px / w800 / tight tracking (-1.5)
- Headline: 28-24px / w800 / negative tracking
- Title: 18-15px / w600
- Body: 15-13px / w400 / relaxed line height (1.5)
- Label: 11px / w600 / uppercase tracking (0.5-1.2)
- Mono: 13px / tabular figures for data display

---

## Spacing

| Token  | Value |
|--------|-------|
| xs     | 4     |
| sm     | 8     |
| md     | 12    |
| lg     | 16    |
| xl     | 20    |
| xxl    | 28    |
| xxxl   | 40    |

- Screen padding: 20dp horizontal
- Section gap: 28dp (xxl)

---

## Shapes

- Small: 12dp radius
- Medium: 16dp
- Large: 20dp
- Extra large: 28dp
- Full: 999dp (pill)
- Glass border: 1px at 6% white (dark) / 3% black (light)
- Glow shadow: AQI-tinted BoxShadow with MaskFilter.blur

---

## Components

### AuraBackground
Ambient generative gradient background. AQI drives blob colors via
`AppColors.aqiGradient()`. Lower opacity (12% dark / 7% light), slower
animation for a premium feel.

### BreathabilityRing
200px custom-painted arc with glow effect (MaskFilter.blur behind stroke).
Factor chips below with outlined borders. Uppercase label with 1.5 tracking.

### CountdownTimer
Displays countdown to safe outdoor window. Icon in 40x40 badge container.
Glass border with accent tint.

### AqiTrendChart
fl_chart line chart with gradient fill. Mini stats row (LOW / AVG / HIGH)
above chart. No dot markers for clean look.

### ActivityTimeline
Horizontal bar-fill visualization. First item labeled "Now" with highlighted
border. Bar height proportional to breathability score.

### GearAdvisorRow
Pill-shaped chips (borderRadiusFull) with priority-colored borders.
Tapping opens bottom sheet detail view.

### HealthImpactCard
Cigarette-equivalent PM2.5 translation. Severity badge (pill shape).
Icon changes based on cigarette count.

### VentilationCard
Open/close windows guidance. Action badge + trend indicator.

### FocusBlock
Glass-morphism container. Optional `glowColor` for AQI-tinted shadows.

### StatChip
Compact icon + value + label chip with glass border.

---

## Motion

- Entrance animations: 600ms, staggered 50-100ms between cards
- Fade + slideY(0.05) for vertical cards
- Scale(0.95) + fade for hero ring
- Easing: easeOutCubic
- Aura background: 10s base animation cycle

---

## Screen Layout

### Dashboard (single scroll)
1. Top bar — location + settings icon
2. BreathabilityRing (hero)
3. Weather stats row
4. CountdownTimer (if safe window exists)
5. GearAdvisorRow
6. VentilationCard
7. HealthImpactCard
8. AqiTrendChart
9. ActivityTimeline
10. HourlyForecastRow

### Onboarding (3-page PageView)
1. Welcome — app icon, tagline, "Get Started"
2. Location — GPS detect or city search
3. Health Profile — radio selection

### Settings
- Theme selector (System / Light / Dark chips)
- Health profile radios
- Location display
- About section

---

## UX Writing

- Human, actionable, minimal
- Replace "AQI: 152" with "Air is unhealthy right now"
- Labels: uppercase + tracking for section headers
- Data values: mono/tabular for alignment
# 🌬️ Hava — Design System

## 🧭 Theme Philosophy
**Ambient Intelligence UI**

The interface should feel:
- Calm, breathable, and responsive
- Guidance-focused (not data-heavy)
- Minimal yet emotionally expressive

---

## 🎨 Color System

### 🌑 Base Colors
- Background: `#0B0F14`
- Surface: `#121821`
- Divider: `rgba(255,255,255,0.06)`

---

### 🌈 State-Based Accent Gradients

#### 🟢 Good Air (AQI 0–50)
- `#3EE8A5 → #4FD1FF`

#### 🟡 Moderate (AQI 51–100)
- `#FFC857 → #FF8C42`

#### 🔴 Unhealthy (AQI 100+)
- `#FF5F6D → #FF2E63`

---

### 💡 Usage Rules
- Keep background always dark
- Apply gradients ONLY to:
  - Recommendation cards
  - Highlights
  - Graph accents
- Avoid full-screen color fills

---

## 🧱 Layout & Components

### 🟦 Cards
- Shape: Squircle (border radius ~24px)
- Background: `rgba(255,255,255,0.04)`
- Border: `1px solid rgba(255,255,255,0.06)`
- Blur: 16–20 (Glass effect)

---

### 🧩 Elevation
- Subtle shadow:
  - `0 8px 24px rgba(0,0,0,0.3)`
- Optional inner glow for active state

---

## 🔤 Typography

### Font Family
- Primary: Inter (Variable)

### Scale
- Headline: 20–24px / SemiBold
- Subheading: 16px / Medium
- Body: 14px / Regular
- Labels: 12px / Regular + letter-spacing (0.5–1px)

---

## ⚡ Motion & Animation

### Principles
- Smooth, soft, non-distracting
- Slow-in, fast-out easing
- No abrupt transitions

---

### 🌬️ Signature Animation: “Breathing UI”
- AQI Good → slow expanding glow
- AQI Bad → tighter, subtle pulse

---

### Micro-interactions
- Cards: fade + slide-up + slight scale
- Graph: progressive line draw
- Icons: 1–2px floating motion

---

## 📊 Core UI Sections

### 🟩 Recommendation Card (Hero)
- Large, top-focused
- Gradient border/glow based on AQI
- Minimal text

Example:
- “Best time to go outside”
- “Avoid outdoor activity”

---

### 📉 AQI Trend Graph
- Smooth curved line
- Gradient fill (low opacity)
- Highlight best time window

---

### 📦 Stats Row
- Horizontal scroll
- Minimal icons + values
- No heavy labels

---

## 🧠 UX Writing Style

### Tone
- Human
- Actionable
- Minimal

### Replace:
- ❌ “AQI: 152”
- ✅ “Air is unhealthy right now”

---

## 🌟 Unique UI Ideas

### 1. Time Aura
Highlight best outdoor time as glowing band in graph

### 2. Health Score Ring
Combine AQI + weather into a single visual score

### 3. Mood-Based UI
- Good AQI → airy spacing
- Bad AQI → slightly tighter layout

---

## 🚀 Design Identity Summary

**Neo-Minimal Ambient Health UI**

- Dark base + glowing gradients
- Glassmorphism + depth
- Emotion through motion
- Recommendation-first UX