# Cuan Mobile

> Personal finance for Indonesian users — tracked by chat, designed like a private bank.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%3E%3D3.4-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey)](#)
[![Tests](https://img.shields.io/badge/Tests-19%20suites-brightgreen)](#testing)

**Cuan Mobile** is the native companion to the [Cuan web app](https://cuan-web.akudong85.workers.dev) — a personal finance tracker whose signature interaction is a conversation: tell the AI assistant what you spent, in plain Indonesian, and it records the transaction for you. No forms first; the ledger follows the chat.

The interface follows the **Midnight Ledger** design language — a dark-first, calm, high-trust aesthetic built for glancing at your money at night: one big balance, one prompt bar, nothing shouting. It is deliberately *not* a shrunken version of the web dashboard.

---

## Features

- **AI Assistant (center tab)** — log income and expenses by chatting or by voice (speech-to-text), with instant haptic/visual feedback.
- **Home** — animated balance hero, month in/out strip, budget overview, and a financial health score.
- **Activity** — full transaction history with filters and search.
- **Budgets** — per-category monthly budgets with 90% / over-budget push alerts.
- **Accounts** — multiple wallets/accounts with full CRUD.
- **Savings Goals** — goal tracking with add-funds flow.
- **Debts** — record debts and receivables, track repayments.
- **Recurring** — scheduled transactions (subscriptions, salary, bills).
- **Split Bill** — split expenses with friends and save the result to your ledger.
- **Security** — biometric app lock (fingerprint/face), session cookies stored in encrypted storage.
- **Push Notifications** — Firebase Cloud Messaging for budget alerts (graceful no-op when Firebase is not configured).
- **Backup** — export/import your data.

## Tech Stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.x / Dart ≥ 3.4 |
| State management | `flutter_bloc` (BLoC/Cubit per feature) |
| Networking | `dio` + `dio_cookie_manager` (cookie-based sessions) |
| Backend | Cuan API — Cloudflare Workers + D1 (`https://cuan-core.akudong85.workers.dev`) |
| Auth | Session cookies in `flutter_secure_storage`, biometric unlock via `local_auth` |
| Push | `firebase_messaging` + `flutter_local_notifications` |
| Voice input | `speech_to_text` |
| Formatting | `intl` (IDR currency, id_ID dates) |

## Architecture

Feature-first clean architecture. Every feature owns its BLoC, data layer, and presentation:

```
lib/
├── main.dart               # Entry point (Firebase bootstrap, graceful fallback)
├── app.dart                # MaterialApp, theme, routing shell
├── core/
│   ├── api/                # Dio client, session interceptor
│   ├── notifications/      # FCM + local notification services
│   ├── security/           # Biometric lock, secure storage
│   ├── theme/              # Midnight Ledger tokens & ThemeData
│   ├── utils/              # IDR/date formatting, validators
│   └── widgets/            # Shared UI (error states, empty states, sheets)
└── features/
    ├── accounts/   activity/   assistant/   auth/      budgets/
    ├── debts/      home/       onboarding/  recurring/ savings/
    ├── settings/   shell/      splitbill/
    └── <feature>/{bloc, data, presentation}
```

See [`DESIGN.md`](DESIGN.md) for the full design direction (palette, typography, layout strategy) and [`docs/android-bug-audit.md`](docs/android-bug-audit.md) for the latest platform audit.

## Getting Started

### Prerequisites

- Flutter SDK 3.x (developed against 3.38)
- Dart SDK ≥ 3.4
- Android Studio / Android SDK for Android builds, Xcode for iOS builds

### Run locally

```bash
git clone https://github.com/arifhidayat65/cuan-mobile.git
cd cuan-mobile
flutter pub get
flutter run
```

The app talks to the production Cuan API by default (`lib/core/api/cuan_api.dart`). To point it at your own backend, change `CuanApi.baseUrl` there.

### Firebase (optional)

Push notifications need a Firebase project. Without it the app still runs — messaging simply stays disabled. Setup steps: [`FIREBASE_SETUP.md`](FIREBASE_SETUP.md).

### Build a release APK

```bash
flutter build apk --release --split-per-abi
```

## Testing

```bash
flutter analyze   # expected: no issues
flutter test      # 19 suites: BLoC, validation, security, error states, formatting
```

## Roadmap / Known Notes

- Payment-gateway integration is intentionally **out of scope** — Cuan records money in; it does not collect payments (see [`PAYMENT_DISCOVERY_REPORT.md`](PAYMENT_DISCOVERY_REPORT.md)).
- iOS builds are configured but Android is the primary tested platform.

## Related

- **Cuan Web** — https://cuan-web.akudong85.workers.dev
- **Cuan API** — https://cuan-core.akudong85.workers.dev

## License

Private project — all rights reserved. The Cuan web codebase this app complements was originally based on the open-source Cuan project by [fiqrisr](https://github.com/fiqrisr).
