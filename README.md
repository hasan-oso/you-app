<div align="center">

# YOU — Smart Health Companion

**An AI-powered personal health coach built with Flutter.**

[![Platform](https://img.shields.io/badge/platform-Android-3DDC84?logo=android&logoColor=white)](https://play.google.com/store)
[![Flutter](https://img.shields.io/badge/Flutter-3.5%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-1.2.2-blue.svg)](pubspec.yaml)

[English](README.md) · [العربية](README.ar.md) · [Türkçe](README.tr.md)

</div>

---

## Overview

**YOU** is a cross-platform mobile health companion that combines AI-powered food scanning, personalized workout plans, step tracking, and habit gamification into a single experience. The app helps users build healthier daily routines through actionable insights, daily quests, and a rank-progression system.

Live on Google Play. Built with Flutter, Supabase, and Google's Gemini AI.

## Key Features

- **AI Food Scanner** — Snap a meal and receive instant nutritional breakdown, toxic-ingredient warnings, and personalized health scoring via Google Gemini.
- **Personalized Workout Plans** — Adaptive routines generated from the user's biometrics, lifestyle, and goals.
- **Step Tracking** — Native pedometer integration with daily goals and progress visualization.
- **Daily Health Quests** — Gamified missions that reward consistency with coins, rank promotions, and achievements.
- **Smart Notifications** — Locale-aware, timezone-correct reminders for water, meals, and activity.
- **Privacy-First Onboarding** — Health data is collected with explicit consent and stored securely.
- **Trilingual UI** — Full Arabic (RTL), Turkish, and English support with locale-persistent preferences.
- **Offline-First Architecture** — Local SQLite cache with a sync queue that reconciles with Supabase when online.

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3.5+) |
| State Management | GetX |
| Backend / Auth | Supabase (PostgreSQL + Auth + Storage) |
| AI | Google Generative AI (Gemini) |
| Local Storage | SQLite (`sqflite`), `shared_preferences` |
| Authentication | Google Sign-In + Supabase Auth |
| Notifications | `flutter_local_notifications` + `timezone` |
| Monetization | Google AdMob (App Open, Rewarded, Banner, Native) |
| Sensors | `pedometer`, `camera`, `permission_handler` |
| UI / UX | `google_fonts`, `flutter_svg`, `fl_chart`, `confetti`, `shimmer` |

## Architecture

The codebase follows a **feature-first layered architecture**:

```
lib/
├── core/           # Theme, routing, bindings, localization, shared widgets
├── data/           # Repositories, local datasources, data models
├── features/       # Feature modules (auth, onboarding, dashboard, profile, history, splash)
│   └── <feature>/
│       ├── controllers/
│       ├── screens/
│       └── widgets/
├── models/         # Domain models
├── services/       # Cross-cutting services (AI, auth, notifications, ads, sync, DB)
└── main.dart       # App bootstrap & lifecycle
```

**Design principles:**
- Single responsibility per service — each service owns one concern (auth, ads, notifications, etc.).
- Repository pattern for data access — UI never talks directly to remote APIs.
- Sync queue for resilience — writes are queued locally and reconciled when connectivity returns.
- Locale-aware everything — strings, dates, numbers, and timezones all respect the user's locale.

## Getting Started

### Prerequisites

- Flutter SDK **3.5.0** or higher
- Android Studio / VS Code with Flutter & Dart plugins
- Android SDK (min API **21** / Android 5.0)
- A Supabase project, a Gemini API key, and AdMob app IDs (see below)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/hasanoso151/you-app.git
   cd you-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment variables**

   Copy `.env.example` to `.env` and fill in your own credentials:
   ```bash
   cp .env.example .env
   ```

   Required keys are documented in [`.env.example`](.env.example).

4. **Run the app**
   ```bash
   flutter run
   ```

### Building a Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release
```

Release signing requires an Android keystore. See the Flutter docs on [signing the app](https://docs.flutter.dev/deployment/android#signing-the-app).

## Localization

Translations live in `lib/core/localization/`. The app ships with three locales:

- `ar_AE` — Arabic (default, RTL)
- `tr_TR` — Turkish
- `en_US` — English

User locale is persisted in `shared_preferences` and respected across app restarts.

## Privacy & Security

- All secrets are loaded from `.env` at runtime — none are hardcoded into the binary.
- API keys, signing keys, and credentials are excluded from version control via [`.gitignore`](.gitignore).
- Health data is stored in Supabase under row-level security policies tied to the authenticated user.
- See [SECURITY.md](SECURITY.md) for vulnerability reporting.

## Project Status

- **Live on Google Play** — version **1.2.2** (build 22)
- Active development on new AI scanning capabilities and expanded localization

## License

This project is released under a **Proprietary** license — all rights reserved. The source is published for portfolio and educational viewing only. See [LICENSE](LICENSE) for the full terms.

## Author

Built and maintained by **[@hasan-oso](https://github.com/hasan-oso)**.

For commercial inquiries, partnerships, or licensing requests, open an issue or reach out via GitHub.

---

<div align="center">

**If you find this project interesting, consider giving it a ⭐**

</div>
