# Hava — Comprehensive App Information

> **"Know when to breathe, when to run, and when to stay in."**

**Version**: 1.0.0+1
**Platform**: Flutter (Android / iOS)
**Language**: Dart
**Architecture**: Feature-based with clean separation (UI → Services → Data)
**State Management**: Riverpod (FutureProvider + StateProvider)
**Status**: Phase 1 — Core features complete

---

## 1. App Overview

### Purpose

Hava is a **proactive health assistant** for users in high-pollution or variable-weather environments. Instead of just showing AQI numbers, the app tells users **what to do** based on real-time and forecasted air quality, weather, and their personal health profile.

### Target Users

- People with respiratory conditions (asthma, allergies)
- Athletes and fitness enthusiasts concerned about air quality
- Urban residents in pollution-prone regions
- Health-conscious individuals wanting data-driven outdoor guidance

### Key Differentiators

| Feature | Description |
|---------|-------------|
| **Breathability Index™** | Proprietary 0–100 composite score combining AQI, temperature, humidity, UV, and wind |
| **Relative Minimum Algorithm** | Intelligently finds the best 24-hour window for outdoor exercise |
| **Health Impact Translation** | Converts PM2.5 into relatable "cigarette equivalents" |
| **Contextual Gear Advisor** | Suggests specific gear based on live conditions |
| **Smart Ventilation Logic** | Tells users when to open/close windows |
| **Background Intelligence** | Periodic sync (every 3 hours) with smart notification de-duplication |

---

## 2. Features Breakdown

### A. Onboarding (4-Page Flow)

| Page | Title | Content |
|------|-------|---------|
| 1 | **Welcome** | App logo with gradient, tagline, "Get Started" CTA |
| 2 | **Location Setup** | GPS detection with permission handling, manual city search with autocomplete, reverse geocoding |
| 3 | **Health Profile** | Three radio options — Standard (healthy adults), Sensitive (asthma/respiratory), Professional Athlete |
| 4 | **Notifications** | Lists three notification features, requests Android 13+ permissions, option to skip |

### B. Dashboard (Main Screen)

Single `CustomScrollView` with `RefreshIndicator`. Sections top-to-bottom:

1. **Top Bar** — Location name (tappable search), AQI badge (color-coded), settings icon, last-update timestamp
2. **Breathability Ring** — 200px animated circular arc, glow effect, 5 factor mini-chips (Air Quality, Temperature, Humidity, UV, Wind)
3. **Recommendation Card** — Dynamic guidance ("Best time to run: 6 PM", "Stay indoors", etc.), color-coded by severity
4. **Weather Row** — 4-column stat chips: Temperature (°C), Humidity (%), Wind (m/s), UV Index
5. **Safe Window** — Countdown to next safe outdoor window, or "Stay Indoors" if none available
6. **Gear Advisor** — Horizontal scrollable priority-sorted gear chips (N95 Mask, Sunscreen, Umbrella, etc.)
7. **Ventilation Card** — Open/Close windows advice based on current vs. forecast AQI
8. **Health Impact Card** — "≈ X.X cigarettes today" with severity badge and explanation
9. **AQI Trend Chart** — 24-hour line graph with gradient fill, mini stats (LOW / AVG / HIGH)
10. **Activity Timeline** — Hour-by-hour breathability color bars with "Now" label
11. **Hourly Forecast** — 6+ mini weather cards (time, icon, temperature, rain probability)

**Interactions**: Pull-to-refresh, location chip opens search, help icons (?) open contextual sheets, gear chips open detail bottom sheets.

### C. Settings Screen

| Section | Content |
|---------|---------|
| **Appearance** | Theme selector — System / Light / Dark (3 chips) |
| **Health** | Health Profile radios (same 3 options) |
| **Location** | Current location display, tappable to re-search |
| **About** | App name + version |

---

## 3. Architecture Overview

### Directory Structure

```
lib/
├── main.dart                     # Entry point, Hive init, background service setup
├── app.dart                      # Root MaterialApp with theme + routing
├── core/
│   ├── theme/                    # Colors, shapes, typography, Material 3 theme
│   ├── constants/                # App + API constants
│   ├── extensions/               # BuildContext extensions (isDark)
│   └── utils/                    # AQI utilities
├── data/
│   ├── models/                   # AQI, Weather, Forecast, Location, Recommendation
│   ├── repositories/             # WeatherRepositoryImpl, AqiRepositoryImpl (+ interfaces)
│   └── datasources/
│       ├── remote/               # Dio API clients (OpenWeatherMap, IQAir, Open-Meteo)
│       └── local/                # Hive cache service
├── services/
│   ├── breathability/            # Breathability Engine (0–100 scoring)
│   ├── recommendation/           # Recommendation Engine (relative minimum algorithm)
│   ├── gear/                     # Gear Advisor (contextual suggestions)
│   ├── health_impact/            # Health Impact Calculator (cigarette equivalents)
│   ├── ventilation/              # Ventilation Assistant (open/close logic)
│   ├── notification/             # Notification Service (3 channels)
│   ├── location/                 # Location Service (GPS + reverse geocoding)
│   └── background/               # Background Fetch Service (WorkManager)
├── features/
│   ├── onboarding/               # OnboardingScreen (4 pages)
│   ├── dashboard/                # DashboardScreen + 8 dashboard-specific widgets
│   └── settings/                 # SettingsScreen
├── shared/widgets/               # Reusable UI components (FocusBlock, StatChip, etc.)
├── providers/
│   └── app_providers.dart        # All Riverpod providers
└── routing/
    ├── app_router.dart           # GoRouter with onboarding redirect
    └── route_names.dart          # Route path constants
```

### Data Flow

```
API Calls (Dio)
    ↓
[WeatherApiService, AqiApiService]
    ↓
[WeatherRepositoryImpl, AqiRepositoryImpl]
    ↓
Local Cache (Hive) ←→ [FutureProviders]
    ↓
[Engines compute] → Recommendation, Breathability, Gear, Ventilation, HealthImpact
    ↓
[Dashboard Widgets render]
```

### Provider Hierarchy

```
Low-Level Infrastructure
├── openWeatherDioProvider, iqAirDioProvider
├── weatherApiServiceProvider, aqiApiServiceProvider
└── cacheServiceProvider

Repositories
├── weatherRepositoryProvider
└── aqiRepositoryProvider

User Preferences (persisted via Hive)
├── onboardingCompleteProvider
├── healthProfileProvider
├── themeModeProvider
└── locationProvider

Data Providers (auto-dispose)
├── currentWeatherProvider
├── hourlyForecastProvider
├── currentAqiProvider
├── hourlyAqiForecastProvider
└── citySearchResultsProvider

Engines (singletons)
├── breathabilityEngineProvider
├── recommendationEngineProvider
├── gearAdvisorProvider
├── ventilationAssistantProvider
└── healthImpactEngineProvider

Computed Outputs (auto-dispose)
├── recommendationProvider
├── breathabilityProvider
├── hourlyBreathabilityProvider
├── gearSuggestionsProvider
├── ventilationAdviceProvider
└── healthImpactProvider
```

---

## 4. Services & Business Logic

### 4.1 Breathability Engine

Computes a proprietary **Breathability Index™** (0–100) from five environmental factors.

**Weights** (sum to 100%):

| Factor | Weight | Ideal Range | Score at Ideal |
|--------|--------|-------------|----------------|
| Air Quality | 50% | AQI 0–25 | 100–85 |
| Temperature | 15% | 20–25 °C | 95 |
| Humidity | 12% | 40–55% | 90 |
| UV Index | 11% | 0–1 | 95 |
| Wind Speed | 12% | 2–4 m/s | 90 |

**Score Distribution**: Pristine conditions → 90+, typical city (AQI 40–80) → 40–65, uncomfortable → below 40.

**Health Profile Penalty**: Sensitive/Athlete profiles penalize high AQI earlier in the curve.

**Output**: `BreathabilityResult` — score, label (Excellent/Good/Moderate/Poor/Dangerous), color, per-factor breakdown.

### 4.2 Recommendation Engine

Analyzes 24-hour forecasts to produce actionable recommendations.

**Core Algorithm — Relative Minimum**:
1. Scan AQI forecast for contiguous windows where every hour ≤ user's threshold
2. Minimum window size: 2 hours
3. Among all qualifying windows, pick the one with the lowest average AQI
4. If no safe window → "Stay Indoors"
5. Overlay precipitation check for umbrella reminders

**Recommendation Types**: `safeNow`, `bestWindow`, `stayIndoors`, `umbrella`

### 4.3 Gear Advisor

Produces priority-sorted gear suggestions based on 15+ condition triggers:

| Condition | Gear | Priority |
|-----------|------|----------|
| AQI > 200 | N95 Mask | 100 |
| Feels-like > 40°C | Stay Hydrated! | 95 |
| UV ≥ 8 | SPF 50+ Sunscreen | 85 |
| Rain ≥ 70% | Carry Umbrella | 80 |
| UV 6–7 | Apply Sunscreen | 70 |
| Wind ≥ 15 m/s | Windbreaker | 65 |
| AQI > 100 | Consider a Mask | 60 |
| UV 3–5 | Sunglasses | 30 |
| *...and more* | | |

### 4.4 Health Impact Engine

Translates PM2.5 into relatable health metrics using the **Berkeley Earth Cigarette Equivalence** methodology.

**Formula**: `cigarettes = (PM2.5 / 22) × (hoursOutdoor / 24)`

- 1 cigarette ≈ 22 µg/m³ PM2.5 inhaled per 24 hours
- Default assumption: 2 hours outdoor exposure

**Severity Bands**:

| Cigarette Equivalent | Severity | Color |
|----------------------|----------|-------|
| < 0.1 | Clean | Green |
| 0.1–0.5 | Low | Teal |
| 0.5–2.0 | Moderate | Yellow |
| 2.0–5.0 | High | Orange |
| > 5.0 | Extreme | Red |

### 4.5 Ventilation Assistant

Advises when to open/close windows based on AQI and forecast trends.

| AQI | Action | Rationale |
|-----|--------|-----------|
| ≤ 50 | Open Windows | Excellent air, flush CO₂ |
| 51–100 | Open Cautiously | 15–20 min then reassess |
| > threshold | Keep Closed | Protect indoor air |
| > 200 | Seal All Windows | Hazardous, maximum seal |

Includes 6-hour trend analysis (improving / worsening / stable).

---

## 5. Data Sources & APIs

### OpenWeatherMap

| Endpoint | Usage | Tier |
|----------|-------|------|
| `/data/2.5/weather` | Current weather (temp, humidity, wind, clouds, visibility) | Free |
| `/data/2.5/forecast` | 5-day / 3-hour forecast | Free |
| `/data/2.5/air_pollution` | Current AQI + pollutant concentrations (fallback) | Free |
| `/data/2.5/air_pollution/forecast` | Hourly AQI predictions (24h) | Free |
| `/geo/1.0/direct` | City name → coordinates geocoding | Free |
| `/data/3.0/onecall` | One Call API (available but not primary) | Paid |

### IQAir (AirVisual)

| Endpoint | Usage |
|----------|-------|
| `/v2/nearest_city` | Primary AQI source — US AQI, dominant pollutant, PM2.5, PM10, O3, NO2, SO2, CO |

Fallback: If IQAir fails, uses OpenWeatherMap's air pollution endpoint with European → US AQI conversion.

### Open-Meteo

| Endpoint | Usage |
|----------|-------|
| `/v1/forecast` | UV Index (current + hourly forecast) — free, no API key required |

Used to supplement the free-tier OpenWeatherMap endpoints which don't include UV data.

### Data Models

| Model | Key Fields |
|-------|------------|
| `WeatherModel` | temperature, feelsLike, humidity, windSpeed, windDeg, uvIndex, description, iconCode, cloudiness, visibility |
| `ForecastHourModel` | dateTime, temperature, feelsLike, humidity, windSpeed, uvIndex, cloudiness, precipitationProbability, aqi |
| `AqiModel` | aqi (US scale), dominantPollutant, pm25, pm10, o3, no2, so2, co |
| `LocationModel` | latitude, longitude, city, state, country, displayName |
| `Recommendation` | type, severity, icon, title, headline, body, bestWindow times |

---

## 6. Dependencies

### Core

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_riverpod | ^2.6.1 | State management, dependency injection |
| go_router | ^14.8.1 | Declarative navigation & routing |
| dio | ^5.7.0 | HTTP client for API calls |
| intl | ^0.20.2 | Date/time formatting |

### Local Storage

| Package | Version | Purpose |
|---------|---------|---------|
| hive | ^2.2.3 | Fast NoSQL local database |
| hive_flutter | ^1.1.0 | Flutter integration for Hive |

### Location & Geocoding

| Package | Version | Purpose |
|---------|---------|---------|
| geolocator | ^13.0.2 | GPS location retrieval |
| geocoding | ^3.0.0 | Reverse/forward geocoding |

### Charts & UI

| Package | Version | Purpose |
|---------|---------|---------|
| fl_chart | ^0.70.2 | Line/bar charts (AQI trend) |
| flutter_animate | ^4.5.2 | Declarative animation framework |
| google_fonts | ^6.2.1 | Inter variable-weight font |

### Platform Services

| Package | Version | Purpose |
|---------|---------|---------|
| flutter_local_notifications | ^18.0.1 | Local push notifications |
| workmanager | ^0.9.0 | Android WorkManager for background sync |

---

## 7. Theme & Design System

### Design Philosophy

**Neo-Minimal Ambient Intelligence UI** — Dark-first, glass-morphism, AQI-responsive gradients.

### Color Palette

**Dark Mode (Primary)**:

| Token | Hex | Usage |
|-------|-----|-------|
| darkBackground | `#08090C` | App background |
| darkSurface | `#111318` | Cards, containers |
| darkSurfaceVariant | `#1A1D24` | Secondary surfaces |
| darkTextPrimary | `#F0F2F5` | Headlines, values |
| darkTextSecondary | `#8A919E` | Body, labels |

**AQI-Responsive Gradients**:

| AQI Band | Primary | Secondary | Range |
|----------|---------|-----------|-------|
| Good | `#34D399` | `#22D3EE` | 0–50 |
| Moderate | `#FBBF24` | `#F59E0B` | 51–100 |
| Sensitive | `#FB923C` | `#F97316` | 101–150 |
| Unhealthy | `#FB7185` | `#F43F5E` | 151–200 |
| Very Unhealthy | `#A78BFA` | `#8B5CF6` | 201–300 |
| Hazardous | `#E11D48` | `#BE123C` | 301+ |

### Typography

**Font**: Inter (variable weight, Google Fonts)

| Scale | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 52px | 800 | App title |
| Headline | 24–28px | 700 | Section titles |
| Title | 15–18px | 600 | Card titles |
| Body | 14–15px | 400 | Main text |
| Label | 11–12px | 600 | Badges, chips |

### Spacing & Radius

- Screen padding: 20dp horizontal
- Spacing tokens: xs (4), sm (8), md (12), lg (16), xl (20), xxl (28), xxxl (40)
- Border radius: sm (8), md (12–16), lg (20), xl (28), pill (999)

### Key Components

| Component | Description |
|-----------|-------------|
| **AuraBackground** | Ambient AQI-tinted blob animation (12% opacity, 10s pulse) |
| **BreathabilityRing** | Custom-painted arc with luminous glow |
| **FocusBlock** | Glass-morphism container with optional glow |
| **StatChip** | Compact icon + value + label chip |
| **SectionHeader** | Bold label + contextual help icon (?) |

### Motion

- Fast: 200ms (state changes), Normal: 350ms (transitions), Slow: 500ms
- Dashboard entrance: Staggered 50–200ms delays per card, fade + slideY
- Easing: `Curves.easeOutCubic`

---

## 8. Navigation & Routing

**Route Structure** (GoRouter):

| Route | Screen | Notes |
|-------|--------|-------|
| `/` | Dashboard | Default after onboarding |
| `/onboarding` | Onboarding | Redirected if not completed |
| `/settings` | Settings | Push from dashboard |

**Transitions**: Onboarding ↔ Dashboard: Fade (350ms). Dashboard → Settings: Slide from right (350ms).

---

## 9. Background Services

### WorkManager Integration

- **Interval**: Every 3 hours
- **Requires**: Network connectivity
- **Flow**: Init Hive in isolate → read cached location → fetch AQI + weather → compute recommendation → send de-duplicated notifications

### Notification Channels (Android)

| Channel | ID | Priority | Trigger |
|---------|-----|----------|---------|
| Daily Digest | `daily_digest` | Default | 7:30 AM, once/day |
| Umbrella Reminder | `umbrella_reminder` | High | 40%+ rain within 6h, max once/hour |
| AQI Alert | `aqi_alert` | High | AQI > 150, max once/hour |

---

## 10. Error Handling & Offline Behavior

- **API Failures**: Repositories catch Dio exceptions, return 24h-stale cached data if available
- **Missing Location**: All providers return null/empty; onboarding ensures location is set first
- **Permission Denials**: Location shows error with retry; notification skip is graceful
- **Background Failures**: WorkManager silently retries on next schedule; cached data persists

---

## 11. Initialization Flow

```
main.dart
├── WidgetsFlutterBinding.ensureInitialized()
├── SystemChrome.setPreferredOrientations(portraitUp)
├── initHive() → CacheService ready
├── NotificationService.init()
├── initBackgroundService() → WorkManager registered
└── runApp(ProviderScope(overrides: [cache], child: HavaApp()))
    └── HavaApp
        ├── theme: AppTheme.light / dark (Material 3)
        ├── routerConfig: GoRouter
        └── Routing: onboarding redirect → dashboard
```

---

## 12. Permissions

### Android

- `ACCESS_FINE_LOCATION` — GPS
- `POST_NOTIFICATIONS` — Android 13+ notifications
- `INTERNET` — API calls
- `SCHEDULE_EXACT_ALARM` — Background task scheduling

### iOS

- `NSLocationWhenInUseUsageDescription` — GPS access
- `NSLocationAlwaysAndWhenInUseUsageDescription` — Background location

---

## 13. Configuration & Build

### Environment Variables

- `OPENWEATHER_API_KEY` — OpenWeatherMap API key (injectable via `--dart-define`)
- `IQAIR_API_KEY` — IQAir/AirVisual API key (injectable via `--dart-define`)

### Build Commands

```bash
# Debug
flutter run

# Release
flutter build apk --release
flutter build ios --release

# With custom API keys
flutter run --dart-define OPENWEATHER_API_KEY=your_key --dart-define IQAIR_API_KEY=your_key
```

---

## 14. Future Roadmap

### Phase 2: Enhancement
- Multi-location bookmarks
- Activity history logging
- Personalized safe window predictions (ML)
- Home screen widget

### Phase 3: Social & Community
- Community AQI observations (crowdsourced)
- Social sharing of safe run routes
- Cleanest air location leaderboards

### Phase 4: Advanced
- Fitness app integration (Apple Health, Google Fit)
- Wearable app support
- Pro subscription tier
