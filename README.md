# Hava

**"Know when to breathe, when to run, and when to stay in."**

Hava is a Flutter health and air-quality companion. It doesn't just show you "AQI 150". It turns
live air-quality and weather data into advice you can act on: *postpone your run until 6 PM*,
*close the windows now*, *wear an N95 if you go out*.

## Features

- **Breathability Index:** a 0-100 score combining AQI, temperature, humidity, UV and wind.
- **Best time to exercise:** finds the cleanest window in the next 24 hours, adjusted for your
  health profile (standard, sensitive/asthma, or athlete).
- **Health impact:** converts PM2.5 exposure into "cigarette equivalents" people can relate to.
- **Gear advisor:** suggests a mask, sunscreen, umbrella and so on, from live conditions.
- **Ventilation assistant:** tells you when to open or close the windows.
- **Activity timeline and AQI trend chart** for the day ahead.
- **Background alerts:** checks every few hours and de-duplicates notifications (rain reminders,
  pollution spikes).
- **Location:** GPS, or a city search for people who'd rather not share their location.
- **State-aware design:** colours shift from mint to mustard to salmon as air quality worsens.

## Tech stack

- Flutter + Dart, **Riverpod** for state, **go_router**
- **Dio** API clients for OpenWeatherMap, IQAir and Open-Meteo
- **Hive** local cache, **WorkManager** background sync, `flutter_local_notifications`
- `geolocator` + `geocoding`, `fl_chart`, `flutter_animate`, `google_fonts`

## Project structure

```
lib/
  core/        theme, constants, AQI utilities
  data/        API services, models, repositories, cache
  services/    breathability, recommendation, health-impact, gear, ventilation engines
               + location, notifications, background sync
  features/    dashboard, onboarding, settings
  routing/     go_router setup
  shared/      reusable widgets
```

## Getting started

API keys are not committed. Create `lib/core/constants/api_constants.dart` before you build:

```dart
class ApiConstants {
  static const openWeatherApiKey = 'YOUR_OPENWEATHER_KEY';
  static const openWeatherBaseUrl = 'https://api.openweathermap.org';
  static const openWeatherGeoPath = '/geo/1.0/direct';
  static const openWeatherOneCallPath = '/data/3.0/onecall';
  static const iqAirApiKey = 'YOUR_IQAIR_KEY';
  static const iqAirBaseUrl = 'https://api.airvisual.com/v2';
  static const iqAirNearestCityPath = '/nearest_city';
  static const defaultUnits = 'metric';
  static const requestTimeout = Duration(seconds: 15);
}
```

Then run:

```bash
flutter pub get
flutter run
```

## Docs

- [`APP.md`](APP.md): product vision and design philosophy
- [`APP_INFO.md`](APP_INFO.md): detailed feature and architecture reference
- [`DESIGN.md`](DESIGN.md), [`IMPROVEMENT_PLAN.md`](IMPROVEMENT_PLAN.md)
