# ModernRide - Route & Car Navigation

A production-grade, single-screen Flutter ride navigation application featuring native Android and iOS location bridges, real-time driving route calculation, smooth 60fps vehicle animation, off-route deviation detection with automatic rerouting, and complete flavor separation.

---

## Technical Stack & Package Versions

- **Flutter SDK**: `3.47.5` (Dart `^3.13.4`)
- **State Management**: `flutter_bloc: ^9.1.1`, `bloc_concurrency: ^0.3.0`, `stream_transform: ^2.1.2`
- **Map & Spatial Mathematics**: `flutter_map: ^8.3.2`, `latlong2: ^0.10.1`
- **Networking**: `dio: ^5.11.1`
- **Native Location Module**: `modern_locate` (in-tree federated package at `./packages/modern_locate`)
- **Value Equality**: `equatable: ^3.0.0`
- **Testing**: `flutter_test`, `bloc_test: ^10.0.0`, `mocktail: ^1.0.4`, `fake_async: ^1.3.3`

---

## Environment & Requirements

- **Flutter SDK**: `3.47.5` (configured via `.fvmrc`)
- **Dart SDK**: `^3.13.4`
- **Android**: compileSdk 34, minSdk 21, Java 17
- **iOS**: iOS 15.0+ deployment target, Xcode 15+

---

## How to Build and Run Each Flavor

The project uses build flavors (`dev` and `prod`) with distinct application IDs, app display names, and environment configurations.

### 1. Android

#### Run in Development Mode
```bash
flutter run --flavor dev -t lib/main_dev.dart
```
- **App ID**: `com.kawsar.modern_ride.dev`
- **App Label**: `ModernRide Dev`
- **Features**: Visual DEV ribbon watermark, verbose native location logs.

#### Run in Production Mode
```bash
flutter run --flavor prod -t lib/main_prod.dart
```
- **App ID**: `com.kawsar.modern_ride`
- **App Label**: `ModernRide`
- **Features**: Clean production UI, release logging policy.

#### Build Android Binaries
```bash
# Development APK
flutter build apk --flavor dev -t lib/main_dev.dart

# Production APK
flutter build apk --flavor prod -t lib/main_prod.dart

# Production Release App Bundle (for Google Play Store)
flutter build appbundle --flavor prod -t lib/main_prod.dart
```

---

### 2. iOS

The iOS project includes shared schemes (`dev` and `prod`) and configuration xcconfig files.

#### Run on iOS Simulator / Physical Device
```bash
# Development Flavor
flutter run --flavor dev -t lib/main_dev.dart

# Production Flavor
flutter run --flavor prod -t lib/main_prod.dart
```

#### Build iOS Binaries (macOS only)
```bash
# Build Development Archive
flutter build ipa --flavor dev -t lib/main_dev.dart --no-codesign

# Build Production Release IPA
flutter build ipa --flavor prod -t lib/main_prod.dart
```

---

## Testing & Quality Assurance

Run the test suite covering domain entities, business logic BLoCs, route navigation math, camera animators, and native location repositories:

```bash
# Run static analysis
flutter analyze

# Run all automated tests
flutter test
```

---

## Known Limitations

1. **Public OSRM Demo Server**:
   The default routing engine uses the public demo server (`https://router.project-osrm.org`). While suitable for development and demonstrations, it imposes rate limits and does not guarantee strict uptime SLAs.
2. **Native GPS Dialog Dependency on Android**:
   The in-app GPS enablement resolution dialog utilizes Google Play Services `SettingsClient`. On AOSP devices without Google Play Services, the app gracefully falls back to opening the system location settings page.
3. **Foreground Lifecycle**:
   Vehicle simulation is currently scoped to the foreground application lifecycle. Leaving the app or locking the screen pauses route animation until the app is resumed.
