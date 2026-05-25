# 🌬️ Hava: Smart Health & AQI Companion  
**“Know when to breathe, when to run, and when to stay in.”**

---

## 1. Product Vision
To provide users in high-pollution or variable-weather environments with a **proactive health assistant**.  
Instead of just showing numbers (e.g., *AQI 150*), the app tells the user **what to do** based on those numbers  
(e.g., *“Postpone your run until 7:00 PM”*).

---

## 2. Design Philosophy (Samsung / Google Health Style)

- **Minimalism**  
  No unnecessary buttons or clutter. Only the most vital information is shown at a glance.

- **Squircles & Soft Shadows**  
  All UI containers use *Squircle* shapes (continuous curvature corners) with subtle elevations.

- **Micro-Animations**  
  - Lottie for weather icons  
  - `flutter_animate` for smooth *slide-up* card entrances

- **State-Aware Color Palette**
  - **Good (AQI 0–50):** Calm Mint / Green shades  
  - **Moderate (AQI 51–100):** Soft Mustard / Yellow shades  
  - **Unhealthy (AQI 100+):** Soft Salmon / Deep Red shades  

- **Typography**  
  Clean, high-readability sans-serif (e.g., **Inter** or **Product Sans**).

---

## 3. Core Features & User Journey

### A. Seamless Onboarding
- **Permissions**  
  Requesting location (GPS) and notification access with *“Why it matters”* context.
- **Manual Fallback**  
  Search-and-select city picker for users who prefer not to share precise GPS.
- **Health Profile**  
  Basic selection:
  - Standard  
  - Sensitive / Asthma  
  - Professional Athlete  
  Used to adjust the *“Safe to Exercise”* threshold.

---

### B. The Proactive Dashboard

- **Recommendation Block**  
  A large, high-contrast card at the top.  
  - *🟢 Best time for your run: Today at 6:00 PM (AQI: 45)*  
  - *🔴 Stay Indoors: High PM2.5 levels detected. Wear an N95 if you must go out.*

- **Current Stats**  
  Minimal horizontal scroll:
  - Temperature  
  - Humidity  
  - UV Index  
  - Wind Speed  

- **AQI 24h Trend**  
  Sleek, gradient-filled line chart showing air quality fluctuations over the next day.

---

### C. Smart Notifications (Android Optimized)

- **Daily Digest**  
  7:30 AM summary of the day’s *Healthiest Window*.
- **Umbrella Reminder**  
  Alert triggered 30 minutes before forecasted precipitation > **40%**.
- **AQI Alert**  
  Critical alert if AQI spikes suddenly (e.g., crop burning or traffic peaks).

---

### D. Background Intelligence

- **Background Fetch**  
  Uses **Android WorkManager** to refresh data even when the app is closed.
- **Local Caching**  
  Uses **Hive** to store last fetched data so the app opens instantly, even on slow connections.

---

## 4. Technical Architecture

| Component          | Technology |
|--------------------|------------|
| Framework          | Flutter (Dart) |
| State Management   | Riverpod |
| Navigation         | GoRouter |
| Networking         | Dio + Retrofit |
| Local DB           | Hive (Caching) |
| Weather API        | OpenWeatherMap One Call API 3.0 |
| AQI API            | IQAir (AirVisual) / OpenWeather |
| Location           | Geolocator (GPS) / Geocoding |
| Graphics           | FL Chart (Trends) / Lottie (Icons) |

---

## 5. Development Roadmap (Phase 1)

### Step 1: Foundation (Theme & Navigation)
- Project structure setup  
- Samsung-style design system (colors, fonts, shapes)

### Step 2: Data & API
- Integrate weather and AQI services  
- Robust error handling for API limits and offline states

### Step 3: The Algorithm
- Develop *Relative Minimum* logic to calculate best outdoor windows  
- City-specific optimization

### Step 4: Background Sync & Notifications
- Android-specific background tasks  
- Local notification triggers