# telemed_app

Telemed — a Flutter telemedicine app (audio/video consults) with localization.

## Overview

This repository contains the Telemed mobile application built with Flutter.
It includes Android and iOS projects, localization assets, and core app code under `lib/`.

## Features

- Audio & video consult support
- Localization (English, Hindi, Marathi)
- Secure storage and native integrations

## Quick Start

Prerequisites:

- Install Flutter SDK: https://docs.flutter.dev/get-started/install
- Android SDK (for Android builds) / Xcode (for iOS builds)

Setup:

```bash
git clone <repo>
cd telemed_app
flutter pub get
```

Run on Android:

```bash
flutter run -d android
```

Build APK:

```bash
flutter build apk --release
```

Run tests:

```bash
flutter test
```

## Localization

Localization files live in `assets/l10n/` (e.g. `en.json`, `hi.json`, `mr.json`). The app uses these for runtime translations.

## Project layout

- `lib/main.dart`: app entrypoint
- `lib/core/`, `lib/features/`, `lib/shared/`: core app modules
- `android/`, `ios/`: platform projects

## Contributing

Open an issue or submit a PR. For quick changes, run `flutter analyze` and `flutter test` before submitting.

## License

See repository license (if any) or contact the maintainers.
