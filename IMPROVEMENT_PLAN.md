# Hava — Comprehensive Improvement Plan

> Status snapshot (Phase 1 complete): All core engines (Breathability, Recommendation, Gear, Health Impact, Ventilation), background sync via WorkManager, 3 notification channels, dashboard with 11 sections, onboarding (4 pages), and Settings screen are shipping. APIs: OpenWeatherMap + IQAir + Open-Meteo. State: Riverpod. Caching: Hive.

This document is a structured roadmap to evolve Hava from a feature-complete v1 into a polished, performant, and delightful daily-driver app — with a particular focus on a **Samsung Weather–inspired card system** that retains our gradient + glass identity but reduces cognitive load.

---

## Table of Contents
1. [What We Have Today (Audit)](#1-what-we-have-today-audit)
2. [Key Problems Observed](#2-key-problems-observed)
3. [UI/UX Redesign — "Calm Cards" System](#3-uiux-redesign--calm-cards-system)
4. [Feature Enhancements](#4-feature-enhancements)
5. [Notification System Overhaul](#5-notification-system-overhaul)
6. [Performance Improvements](#6-performance-improvements)
7. [Security & Privacy Hardening](#7-security--privacy-hardening)
8. [Code Quality, Architecture & Testing](#8-code-quality-architecture--testing)
9. [Accessibility & Internationalization](#9-accessibility--internationalization)
10. [Platform / Native Integrations](#10-platform--native-integrations)
11. [Analytics, Telemetry & Crash Reporting](#11-analytics-telemetry--crash-reporting)
12. [Proposed Release Roadmap](#12-proposed-release-roadmap)

---

## 1. What We Have Today (Audit)

### 1.1 Implemented Features
| Area | Status |
|------|--------|
| 4-page onboarding (Welcome, Location, Health Profile, Notifications) | ✅ |
| GPS + manual city search with reverse geocoding | ✅ |
| Dashboard with 11 vertical sections | ✅ |
| Breathability Index™ (5-factor 0–100 score) | ✅ |
| Recommendation Engine (Relative Minimum algorithm) | ✅ |
| Gear Advisor (15+ rules, priority sorted) | ✅ |
| Health Impact (cigarette equivalents, Berkeley methodology) | ✅ |
| Ventilation Assistant (open/close windows) | ✅ |
| 3 notification channels (Daily Digest, Umbrella, AQI Alert) | ✅ |
| WorkManager background sync (every 3h) | ✅ |
| AQI trend chart (fl_chart, 24h) | ✅ |
| Hourly forecast row | ✅ |
| Settings (Theme / Health Profile / Location / About) | ✅ |
| Hive caching with 24h stale fallback | ✅ |
| Material 3 dark/light themes with AQI-responsive gradients | ✅ |

### 1.2 Dashboard Inventory (11 sections, top-to-bottom)
1. Top Bar (location + AQI badge + settings)
2. Breathability Ring (320 px hero)
3. Recommendation Headline
4. Weather Row (4 chips)
5. Safe Window Countdown
6. Gear Advisor (horizontal scroll)
7. Ventilation Card
8. Health Impact Card
9. AQI Trend Chart (220 px)
10. Activity Timeline
11. Hourly Forecast

### 1.3 Tech Stack Summary
- Flutter, Dart, Riverpod, GoRouter
- Dio + Retrofit-style services, Hive, Geolocator, fl_chart, flutter_animate, Google Fonts (Inter)
- flutter_local_notifications, workmanager

---

## 2. Key Problems Observed

### 2.1 UI / Information Density
- **Card overload**: 11 vertical sections means user scrolls through ~3500 px of content. The hero Breathability Ring + Recommendation + Weather + Safe Window all compete for the "first impression".
- **Heavy glass cards**: Every card uses a similar glass-morphism container at full width, producing visual monotony — nothing stands out except by color.
- **Information dumping**: Cards like Health Impact, Ventilation and Breathability each contain 3–5 micro-stats, an icon, a headline and a body — too much per card.
- **No hierarchy of attention**: Recommendation headline (the *most actionable* part) is small compared to the Ring.
- **No "Today vs. Forecast" tabbing** — everything is collapsed onto a single screen.

### 2.2 UX
- No multi-location support (one of the most-requested features in this app category).
- No "what changed since you last opened the app" delta.
- No favoriting / pinning of cards based on user preference.
- Onboarding cannot be revisited.
- Settings is sparse (no notification toggles, no unit preferences, no data refresh interval).

### 2.3 Notifications
- 3 channels are static rules. No quiet hours, no per-channel toggles, no sound/vibration customization.
- No "morning ritual" smart scheduling (e.g., notification arrives 30 min before user's typical wake time).
- AQI alert threshold is fixed at 150 — should be user-configurable per health profile.
- No actionable buttons on notifications (e.g., "View Safe Window", "Open Map").

### 2.4 Performance
- All 11 providers fire on dashboard build → 7 `ref.watch` calls + several derived providers recompute on every refresh.
- `flutter_animate` staggered entrances run on *every* rebuild (incl. provider invalidations), not just first paint.
- No image caching for weather icons.
- AuraBackground runs a continuous 10s pulse animation even when app is backgrounded or scrolled off-screen.
- Hive reads/writes are synchronous on UI thread for `setSavedLocation`.

### 2.5 Security
- API keys (`OPENWEATHER_API_KEY`, `IQAIR_API_KEY`) injectable via `--dart-define`, but no proof they aren't hard-coded as defaults — needs audit.
- Hive boxes are unencrypted — cached location, user profile and history are at rest in plaintext.
- No certificate pinning on Dio clients.
- Permissions are requested in onboarding without granular rationale UI ("Why we need this" is a static string, no link to privacy policy).
- `SCHEDULE_EXACT_ALARM` (Android 13+) requires special handling — currently broadly requested.

### 2.6 Code / Architecture
- Repository layer mixes contract + impl in same folder; no DI boundary for swapping data sources.
- No unit tests for engines (Breathability, Recommendation, GearAdvisor, HealthImpact, Ventilation are pure functions — high-leverage test targets).
- No widget tests for dashboard sections.
- `dashboard_screen.dart` is a single 800+ line file — sections should be extracted.

---

## 3. UI/UX Redesign — "Calm Cards" System

> **North star**: Samsung Weather app — large readable hero, condensed secondary tiles, contextual depth (not info-dumping), and a sense of *air* between elements. Keep our gradient backdrop and glass identity.

### 3.1 Design Principles (revised)
1. **One question per card.** A card answers exactly one thing: "Is it safe to go out?", "What should I wear?", "Should I open the window?" — no sub-stats unless the user taps in.
2. **Progressive disclosure.** Compact summary on the dashboard → tap to open a detail sheet/screen with deep stats.
3. **Asymmetric grid.** Mix full-width hero cards with 2-up tile pairs (Samsung style) to break visual monotony.
4. **Restrained glass.** Use *single* glass elevation level on dashboard; reserve heavy blur for hero + bottom sheets.
5. **Typography over icons.** Lead each card with a single short sentence in large weight, not an icon+label.

### 3.2 New Dashboard Layout

```
┌──────────────────────────────────────────────┐
│  [Location ▾]                  [⚙]           │   ← Slim top bar (44 px)
├──────────────────────────────────────────────┤
│                                              │
│             32°C  •  Light Haze              │   ← HERO (Samsung-style)
│                                              │
│         Breathability  72 / 100              │   ← single line, huge weight
│                                              │
│   "Good time for a 30-min walk before 5 PM"  │   ← actionable headline
│                                              │
├──────────────────────────────────────────────┤
│  [ Safe Window  ]    [  AQI 84  ]            │   ← 2-up tile row
│   2:30 → 4:00         Moderate ↗             │
├──────────────────────────────────────────────┤
│  [ Wear: Mask + Hat ]    [ Windows: Closed ] │   ← 2-up tile row
├──────────────────────────────────────────────┤
│  Hourly                                      │
│  (compact horizontal scroller, 56 px tall)   │
├──────────────────────────────────────────────┤
│  AQI Next 24h                                │
│  (gradient line chart, ~140 px)              │
├──────────────────────────────────────────────┤
│  More details ▾                              │   ← collapsed: Health Impact,
└──────────────────────────────────────────────┘     Activity Timeline, etc.
```

Above-the-fold delivers: Where, What, How safe, What to do. Everything else is **progressive**.

### 3.3 Component Catalog (new)

| Component | Purpose | Notes |
|-----------|---------|-------|
| `HeroSummaryCard` | Full-width, ~280 px. Temp, condition, Breathability, recommendation. | Subtle gradient tint by AQI band. |
| `MetricTile` | 2-up tile, square-ish. One stat + one label + tap-to-expand. | Replaces dense cards. |
| `CompactHourlyStrip` | 56 px scroller. Hour + icon + temp; no rain dot until > 30 %. | Replaces 100-px row. |
| `MiniTrendChart` | 140-px AQI sparkline, no gridlines, no labels — caption shows peak. | Lighter than current. |
| `DetailSheet` | Modal bottom sheet for any tile/card tap. Contains the dense stats. | Where Health Impact, Ventilation depth, Gear list live. |
| `LocationHeader` | Replaces top bar. Slim, swipeable horizontally between saved locations. | Sets up multi-location. |

### 3.4 Glass + Gradient Identity (refined)
- Reduce blur sigma from current full-glass to **two tiers**:
  - **Tier A (Hero only)**: backdrop blur 24, surface alpha 14 %, gradient ring 1 px.
  - **Tier B (Tiles)**: no blur, flat translucent surface alpha 6 %, 1 px hairline border.
- Background `AuraBackground`:
  - Keep AQI-responsive blob but reduce opacity to **8 %**, slow pulse to **20 s**.
  - **Pause animation** when route is not visible or app is in background.

### 3.5 Motion
- Reduce staggered entrance delays from 220 ms cascade to a single 250 ms group fade — feels less "loading-y".
- Replace per-card `slideY` with a single subtle scroll-linked parallax on the Hero card.
- Reduced-motion support: detect `MediaQuery.disableAnimations` and skip all entrance animations.

### 3.6 Color & Typography Tweaks
- Introduce a **neutral surface alt** color (`#13161C`) for tiles, distinct from hero `#1A1D24` — adds depth without heavy shadows.
- Bump body copy from 14 px → **15 px** with line-height 1.45 — Samsung-level readability.
- Reduce label-small from 11 px → use **12 px / weight 500** only; eliminate 9 px "last updated" pill (move into top-bar dropdown).

---

## 4. Feature Enhancements

### 4.1 Multi-Location (P1)
- Persist a `List<LocationModel>` in Hive (current is a single).
- Horizontal swipe between locations on dashboard (page indicator dots).
- "Manage locations" screen with reorder + delete.
- One designated **home location** drives notifications.

### 4.2 Pollutant Detail Screen (P1)
- Today dashboard shows only US AQI + Breathability.
- Tap → detail screen with PM2.5, PM10, O₃, NO₂, SO₂, CO with per-pollutant explanation, source (e.g., "PM2.5 mostly from vehicle exhaust"), and WHO vs. EPA thresholds.

### 4.3 Pollen, Wildfire & Lightning Layers (P2)
- Add Google Pollen API or `open-meteo` air quality module.
- Wildfire smoke overlay via NASA FIRMS or Purpleair fire layer (where available).
- Lightning proximity alerts for outdoor athletes.

### 4.4 Activity Planner (P2)
- "Plan a run" CTA — user picks duration & intensity → engine finds best window in next 72 h.
- Calendar export (.ics) + Google/Apple Calendar deep link.

### 4.5 History & Insights (P2)
- Hourly snapshots persisted (Hive box, 7-day rolling).
- "This Week" screen with average AQI, hours-outdoor-safe, cigarette-equivalent total.
- Streaks ("3 days under 50 AQI").

### 4.6 Home Screen Widgets (P2)
- Android `home_widget` package — small (Breathability score), medium (Breathability + Safe Window), large (full Hero card).
- iOS WidgetKit equivalent via `home_widget`.

### 4.7 Wear OS / Apple Watch Companion (P3)
- Glanceable Breathability score + safe-window countdown complication.

### 4.8 Onboarding Improvements
- Add page for **notification preferences** (channel toggles, AQI alert threshold slider).
- Add re-onboarding entry from Settings.
- Add explicit consent + privacy policy link.

### 4.9 Settings Expansion
- Notification preferences: per-channel toggle, quiet hours, AQI alert threshold, sound/vibration.
- Unit preferences: temperature (°C/°F), wind (m/s, km/h, mph), distance.
- Data refresh interval (1h / 3h / 6h / manual).
- Cache management: size + clear button.
- About: licenses (LicensePage), changelog, GitHub link.

### 4.10 In-App Help / Glossary
- A single "Air Quality 101" screen consolidating all `HelpSheet` content.
- Linked from every detail sheet.

---

## 5. Notification System Overhaul

### 5.1 Channel Redesign
| Channel | Improvement |
|---------|-------------|
| Daily Digest | Scheduled by user (default 7:30 AM), with quiet hours respect. |
| Umbrella Reminder | Snooze action, "Don't remind me today" action. |
| AQI Alert | User-configurable threshold (default by health profile). Snooze actions. |
| **NEW: Safe Window Soon** | 30 min before next safe outdoor window opens. |
| **NEW: Pollutant Spike** | Sudden ≥30 % rise in PM2.5 in 1 hour. |
| **NEW: Sunrise/Sunset UV** | UV-protection reminder. |

### 5.2 Smart De-duplication
- Persist per-channel `lastFiredAt` + payload hash; suppress identical notifications within 6 h.
- Combine adjacent triggers (umbrella + AQI alert in same hour → single grouped notification).

### 5.3 Actionable Notifications
- `flutter_local_notifications` action buttons: "View", "Snooze 1h", "Mute today".
- Deep-link routes via GoRouter (e.g., `/safe-window`, `/aqi-detail`).

### 5.4 Rich Notifications
- BigPicture / BigText style with chart preview or pollutant list.
- Inbox-style "Daily Digest" with bullet list.

### 5.5 Quiet Hours & Do Not Disturb
- User-defined quiet window (e.g., 10 PM–7 AM).
- Respect system DND for non-critical channels.

### 5.6 Permission UX
- Re-prompt path in Settings if user previously denied.
- Detect `POST_NOTIFICATIONS` denial state and show in-app banner.

---

## 6. Performance Improvements

### 6.1 Render Optimization
- Convert `dashboard_screen.dart` from one giant `CustomScrollView` into smaller `Consumer` widgets — narrow rebuild scope per section.
- Memoize `flutter_animate` chains with `Animate(controller: ...)` and run only on first build (not on provider invalidation).
- Use `const` constructors everywhere; audit current widget tree.

### 6.2 Background & Animation
- Pause `AuraBackground` animation on `WidgetsBindingObserver.didChangeAppLifecycleState != resumed`.
- Stop animation when widget is scrolled out of viewport using `VisibilityDetector`.

### 6.3 Networking
- Add Dio cache interceptor (`dio_cache_interceptor`) with 10-min TTL on weather/AQI endpoints to avoid duplicate calls within a session.
- Coalesce parallel calls — single combined refresh provider instead of 4 independent providers each retriggered on pull-to-refresh.
- Switch icon URLs to a self-hosted CDN with `cached_network_image`.

### 6.4 Storage
- Move Hive writes off the UI thread via `compute()` or `Future.microtask`.
- Use Hive type adapters for `LocationModel`, `WeatherModel`, `AqiModel` — avoid JSON encode/decode round-trip on every read.

### 6.5 Build & Bundle
- Run `flutter build apk --analyze-size` and trim unused Lottie assets, font subsets (use Inter Latin-only or subset to user locale).
- Enable Android R8 full mode; verify Proguard rules for `workmanager` + `flutter_local_notifications`.

### 6.6 Startup
- Move `NotificationService.init()` and `initBackgroundService()` to post-`runApp` (microtask) so first frame lands faster.
- Show a splash with theme-tinted gradient (native splash via `flutter_native_splash`) — currently default white flash.

---

## 7. Security & Privacy Hardening

### 7.1 API Key Handling
- Audit codebase for any hard-coded API keys; enforce `--dart-define` only.
- Move secret build args to a CI-managed secrets store (GitHub Actions OIDC / GH Encrypted Secrets).
- For production, route API calls through a thin Cloud Functions / Cloudflare Worker proxy — keys never ship in the APK.

### 7.2 Local Data Encryption
- Encrypt Hive boxes containing PII (location, health profile) using `flutter_secure_storage` to hold the AES key.

### 7.3 Network
- Enable **certificate pinning** on Dio for OpenWeatherMap, IQAir, Open-Meteo (or proxy).
- Enforce HTTPS only; reject HTTP via Dio interceptor.
- Set strict `connectTimeout` / `receiveTimeout` (5 s) to prevent hangs.

### 7.4 Permissions
- Move from `ACCESS_FINE_LOCATION` to `ACCESS_COARSE_LOCATION` as default; request fine only when user explicitly chooses "Precise".
- Drop `SCHEDULE_EXACT_ALARM` unless a precise alarm is genuinely needed; use inexact alarms via WorkManager periodic tasks.

### 7.5 Privacy Posture
- Add a **Privacy Policy** screen (required for Play Store).
- Add **Data Deletion** flow — user-triggered clear of all Hive boxes + secure storage.
- No third-party analytics SDKs that share data without consent (see §11).

### 7.6 Dependency Hygiene
- Add `dart_code_metrics` or `pana` to CI to flag risky packages.
- Pin transitive dependencies; review `pubspec.lock` diffs in PRs.
- Audit packages with native code (`workmanager`, `geolocator`) for known CVEs quarterly.

---

## 8. Code Quality, Architecture & Testing

### 8.1 Refactors
- Extract `dashboard_screen.dart` sections into individual widget files (`_TopBar`, `_WeatherRow`, `_HourlyForecastRow`, `_RecommendationHeadline`) under `features/dashboard/presentation/widgets/`.
- Split repositories into `domain/repositories/` (interfaces) and `data/repositories/` (implementations) to enforce dependency inversion.
- Introduce a `Result<T>` / `Either<Failure, T>` wrapper (or `freezed` unions) instead of bare exceptions for predictable error UI.

### 8.2 Testing
- **Unit tests** for each engine (pure functions): Breathability, Recommendation (relative-minimum window finder), GearAdvisor, HealthImpact, Ventilation — target ≥90 % line coverage.
- **Golden tests** for HeroSummaryCard, MetricTile, AqiTrendChart across themes & AQI bands.
- **Widget tests** for Dashboard rendering AsyncValue.loading / .error / .data states.
- **Integration test** for onboarding → dashboard flow.

### 8.3 CI/CD
- GitHub Actions: `flutter analyze`, `flutter test`, build APK + IPA on every PR.
- Codecov integration; fail PR on coverage drop.
- Release workflow: signed APK + Play Store upload on tag.

### 8.4 Tooling
- Add `very_good_analysis` lint set or strengthen existing `analysis_options.yaml`.
- Pre-commit: `dart format` + `flutter analyze`.
- Codegen for Hive adapters + freezed models.

---

## 9. Accessibility & Internationalization

### 9.1 Accessibility
- Audit color contrast — current `darkTextSecondary` `#8A919E` on `#08090C` is ≈ 5.8 (passes AA) but verify all gradient overlay variants.
- Add `Semantics` labels to Breathability ring, chart points and tile chips ("Air quality index 84, moderate").
- Support **dynamic font scaling** (`textScaler`) without overflow — wrap hero text in `FittedBox` where needed.
- Support **reduced motion** (`MediaQuery.disableAnimations`).
- Color-blind palette mode: switch AQI bands from red/green to a deuteranopia-safe palette + add iconography.

### 9.2 Internationalization
- Externalize all strings to ARB files; switch from raw `String` literals to `flutter gen-l10n`.
- Initial locales: en, hi, es, ar (RTL), zh-CN.
- Localize date/time via `intl`.

---

## 10. Platform / Native Integrations

### 10.1 Android
- Adopt Android 14 foreground service types for background sync.
- Use `WorkManager` constraints: requires network, battery not low.
- Add app shortcut: "Today's safe window".

### 10.2 iOS
- Background fetch via `BGAppRefreshTask` (currently relies on workmanager which is Android-only).
- Live Activity for "Safe Window" countdown.
- Critical alerts for hazardous AQI (requires Apple entitlement).

### 10.3 Cross-Platform
- Adaptive icons (Android 13+ themed icons).
- App link / universal link for `hava://aqi?lat=&lng=`.

---

## 11. Analytics, Telemetry & Crash Reporting

### 11.1 Crash Reporting
- Sentry (`sentry_flutter`) or Firebase Crashlytics — capture uncaught exceptions and ANRs.
- Strip PII (no location, no health profile) from crash payloads.

### 11.2 Privacy-First Analytics
- Add a minimal analytics layer with explicit opt-in (off by default).
- Use Plausible / PostHog (self-hostable) — avoid Google Analytics.
- Track aggregate-only events: app open, refresh, notification tap, screen visit.

### 11.3 Performance Telemetry
- Firebase Performance or Sentry Performance to track API latencies, frame builds, jank.

---

## 12. Proposed Release Roadmap

### v1.1 — "Calm Cards" (UI Polish)
- Hero summary card + MetricTile system
- Glass refinement (Tier A/B)
- Animation pause on background
- Settings expansion (units, notification toggles, quiet hours)
- Unit + widget tests for engines

### v1.2 — "Smarter Notifications"
- 3 new notification channels (Safe Window Soon, Pollutant Spike, UV)
- Actionable + grouped notifications
- AQI alert threshold slider
- Hive encryption + secure storage

### v1.3 — "Multi-Location & History"
- Saved locations + horizontal swipe
- 7-day history insights screen
- Pollutant detail screen
- App proxy for API keys

### v1.4 — "Widgets & Watch"
- Home screen widgets (Android + iOS)
- iOS Live Activity for safe-window countdown
- Wear OS / watchOS companion

### v1.5 — "Plan & Share"
- Activity planner with calendar export
- Share safe-window card as image
- Pollen + wildfire layers

### v2.0 — "Community"
- Crowdsourced AQI observations
- Cleanest-air leaderboards
- ML-personalized safe windows

---

## Appendix A — Quick Wins (can ship in a week)

1. Pause `AuraBackground` when app is backgrounded.
2. Extract dashboard sub-widgets out of `dashboard_screen.dart`.
3. Settings: add notification on/off + AQI threshold slider.
4. Add `flutter_native_splash` with gradient.
5. Run `flutter build apk --analyze-size` and remove unused assets.
6. Add unit tests for `BreathabilityEngine` + `RecommendationEngine`.
7. Replace 11-section dump with the **Hero + 2-up MetricTile** layout for above-the-fold (single screen change, no API impact).
8. Move all dense stat blocks into bottom-sheet `DetailSheet` (progressive disclosure).
9. Add per-channel `NotificationService` toggle wired to Settings.
10. Add `Semantics` labels to all interactive widgets.

---

## Appendix B — Files Likely to Change

| Area | Files |
|------|-------|
| Layout refactor | [lib/features/dashboard/presentation/screens/dashboard_screen.dart](lib/features/dashboard/presentation/screens/dashboard_screen.dart), new files under [lib/features/dashboard/presentation/widgets/](lib/features/dashboard/presentation/widgets/) |
| Theme/glass tiers | [lib/core/theme/](lib/core/theme/), [lib/shared/widgets/focus_block.dart](lib/shared/widgets/focus_block.dart) |
| Settings expansion | [lib/features/settings/](lib/features/settings/), [lib/providers/app_providers.dart](lib/providers/app_providers.dart) |
| Notifications | [lib/services/notification/](lib/services/notification/), [lib/services/background/](lib/services/background/) |
| Multi-location | [lib/data/models/](lib/data/models/), [lib/data/datasources/](lib/data/datasources/), [lib/providers/app_providers.dart](lib/providers/app_providers.dart) |
| Security | [lib/data/datasources/](lib/data/datasources/), [lib/main.dart](lib/main.dart), [android/app/src/main/AndroidManifest.xml](android/app/) |
| Tests (new) | `test/services/`, `test/features/dashboard/` |

---

*End of plan — review, prioritize, and convert sections to GitHub issues.*
