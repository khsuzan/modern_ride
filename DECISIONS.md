# Engineering Decisions & Thought Process

When approaching this assessment, my goal was to build a clean, solid, and reliable navigation experience that feels like a real ride-hailing app (like Uber or Pathao) while keeping the codebase maintainable and practical.

Here is the breakdown of why I made certain architectural choices, how I solved core engineering challenges, and what I learned along the way.

---

## 1. Why I Chose this Architecture & State Management

### Layered Structure

I organized the app into three clear layers: **Domain**, **Data**, and **Presentation**:

- In `lib/features/map_navigation/domain/`, I kept the core models (`RouteEntity`, `UserLocation`) and repository contracts completely pure Dart. There is no Flutter code, no Dio, and no third-party plugin dependencies here. This made writing unit tests straightforward because I didn't have to mock any UI or platform channels.
- In `lib/features/map_navigation/data/`, I placed the remote API calls (OSRM routing with Dio), native location wrappers, and the navigation math logic (`RouteNavigator`).
- In `lib/features/map_navigation/presentation/`, I kept the UI widgets, controllers, and BLoCs.

### State Management: Why BLoC?

Map navigation apps require coordinating multiple asynchronous, high-frequency data streams: native GPS ticks, car progress updates, user map gestures, destination pin placements, and OSRM network requests.

I chose `flutter_bloc` primarily for its reactive stream foundation and concurrency control capabilities:

1. **First-Class Event Transformers (`debounceRestartable`)**:
   A key reason for choosing BLoC over other state managers is its native support for custom event transformers via `stream_transform` and `bloc_concurrency`. When a user rapidly taps or drags across the map to select a destination, handling this cleanly at the state pipeline level with `debounceRestartable` debounces the incoming events and automatically cancels any previous in-flight OSRM routing requests. This eliminates race conditions where an older, slower network response could overwrite a newer route, and prevents unnecessary load on the routing server without having to manually manage timer handles or cancellation tokens inside UI components.

2. **Deterministic State Machine**:
   A ride lifecycle follows a strict sequence: `NavigationInitial` → `PickupSelected` → `DestinationSelectionReady` → `RouteLoading` → `RouteReady` → `Navigating` → `NavigationCompleted` (or `RouteFailureState`). BLoC models these transitions as a predictable finite-state machine with immutable state objects, ensuring the UI always reflects a coherent snapshot of the navigation flow.

3. **Separation of Hardware vs. Navigation Concerns**:
   - `LocationBloc`: Exclusively handles hardware-level concerns—checking permission status, dispatching native permission requests, and listening to the `modern_locate` event stream.
   - `NavigationBloc`: Coordinates domain-level routing—confirming pickup, requesting routes, driving simulation, off-route deviation tracking, and trip completion.

   This decoupling keeps hardware lifecycle issues isolated from route calculation logic.

---

## 2. Designing the Flutter ↔ Native Location Bridge (`modern_locate`)

I created my own native location package in `packages/modern_locate/` with custom implementations for Android (Kotlin) and iOS (Swift) to have complete control over the GPS lifecycle, native error mapping, and system resolution dialogs.

### Channel Strategy: MethodChannel + EventChannel

- I used a **MethodChannel** (`modern_locate/control`) for one-off commands: checking permission status, requesting permission, getting a single location fix, and opening system settings.
- I used an **EventChannel** (`modern_locate/stream`) for the continuous location stream. Location updates are streaming by nature, and `EventChannel` is the cleanest, lowest-overhead way to push coordinates from Android's `FusedLocationProviderClient` and iOS's `CLLocationManager` directly into Dart.

### Stream Lifecycle & Battery Consideration

Leaving GPS streaming active when it is not needed is the fastest way to kill a phone's battery.

- In both Kotlin and Swift, location updates are only started inside `onListen`.
- The moment the Flutter app cancels the subscription or the user leaves the screen, `onCancel` runs immediately, detaching the location listeners and powering down the GPS chip.

### The Android GPS-Disabled Edge Case

A common issue on Android is when the user has granted location permission, but their system GPS is toggled off.
Initially, tapping "Use Current Location" would fail with a disabled GPS error. I improved this by integrating Google Play Services `SettingsClient` with a `ResolvableApiException`. Now, if GPS is turned off, Android automatically shows the native system dialog: _"To continue, turn on device location..."_. When the user taps OK, GPS turns on in the background without forcing them to leave the app.

---

## 3. Movement, Bearing, and Map Tracking

### 60fps Smooth Car Movement

Early on, I noticed that if the car marker moves by rebuilding the entire map or bottom panel, the UI stutters.
To solve this:

- The map view (`NavigationMapView`) is wrapped in a `RepaintBoundary` so it paints on its own isolated layer.
- The car marker uses its own `AnimationController` inside `CarMarkerLayer`. Between each 100ms route update, the car interpolates smoothly across the road.

### The 0° / 360° Angle Flip Bug

When calculating the car's bearing angle, a common math bug occurs when turning through North (e.g. from 350° to 10°). Naive linear interpolation calculates `10 - 350 = -340°`, which causes the car icon to violently spin 340 degrees counter-clockwise instead of turning 20 degrees clockwise.
I wrote `NavigationMath.shortestAngleDelta`:

```dart
delta = (targetAngle - currentAngle + 540) % 360 - 180;
```

This forces the rotation to always take the shortest arc across the 360° boundary.

### Off-Route Deviation & Camera Smoothing

- In `RouteNavigator`, every coordinate is checked against the route polyline using segment projection. If the car is further than 50 meters from the nearest point, it triggers an off-route state and recalculates a new route from the current position.
- In `MapCameraAnimator.trackVehicle`, during normal driving the camera follows the car directly. But when an off-route deviation happens (or the simulation test button shifts the car 60m), the camera doesn't jump abruptly. Instead, it detects the jump (`distance > 8m`) and glides smoothly using `Curves.easeOutCubic` over 500ms.

---

## 4. How I Structured the Flavor Configuration

I set up two distinct flavors: **`dev`** and **`prod`**.

- In Dart, I created two entry points: `lib/main_dev.dart` and `lib/main_prod.dart`. Both initialize an immutable `AppConfig` with the appropriate flavor settings (app title, API URLs, and a visual DEV watermark banner).
- On Android (`build.gradle.kts`), I configured `productFlavors` with `applicationIdSuffix = ".dev"`. This means `ModernRide Dev` and `ModernRide` can be installed on the same phone side-by-side without replacing each other.
- On iOS, I added separate Xcode shared schemes (`dev.xcscheme` and `prod.xcscheme`) and configuration xcconfig files matching both environments.

---

## 5. Real Edge Cases & UX Details I Noticed

### The Single-Screen Permission Dilemma

On a single-screen app, asking for location permissions immediately on cold start is bad UX. Users often reject permissions when prompted with zero context.
To solve this:

- On startup, the map renders immediately.
- The bottom panel shows a clear, helpful message explaining why location is needed, with a "USE CURRENT LOCATION" button.
- If the user prefers not to grant permission, they can simply tap anywhere on the map to set their pickup location manually. Nothing is blocked.

### Initial Map Framing for New Users

Currently, if GPS is not yet acquired, the map centers on a sensible default coordinate (Dhaka, Bangladesh).
A real improvement I would add here is checking the user's device locale or SIM country code on first launch. If a user opens the app in another country or city, we could immediately frame the map to their city bounds while waiting for their GPS fix, so they don't see an irrelevant country for a few seconds.

### OpenStreetMap Tile Attribution

To comply with the OSM tile usage policy, I set the `userAgentPackageName` on the tile layer and created a dedicated `MapAttributionTag` positioned at the top-left inside `SafeArea`. It displays the required copyright text ("© OpenStreetMap contributors") in a subtle, compact pill that remains visible on the map without obstructing the view or getting hidden beneath the bottom panel.

---

## 6. What I Would Change Before Going to Production

1. **Adaptive GPS Polling (Battery Saving)**:
   Right now, the GPS stream asks for high-accuracy navigation coordinates continuously. In production, I would make this adaptive: request 1-second updates only while the car is driving, but switch to a slower interval (or distance filter of 10-20m) when the user is stationary or waiting for pickup.
2. **Background Location Service**:
   If a user locks their screen or switches apps during a ride, iOS and Android throttle background execution. For a real production driver or rider app, I would implement a Foreground Service with an ongoing notification on Android and enable `UIBackgroundModes: location` on iOS.
3. **Dedicated Routing Server**:
   The public OSRM demo server (`router.project-osrm.org`) is free and keyless, but has rate limits and no SLA. For production, I would host OSRM or Valhalla on AWS/GCP behind an API gateway with caching for common road corridors.
4. **Vector Tiles vs. Raster Tiles**:
   Raster PNG map tiles use considerable network bandwidth. Switching to vector tiles (e.g. MapLibre) would reduce tile download sizes by up to 80% and allow smoother zooming and rotation.

---

## 7. What Was Left Out Due to Time

- **Last-Known / Nearest Location Fallback**: Persisting the user's last-used coordinates (or detecting their nearest city/region) to frame the map immediately to their familiar riding area on cold launch, rather than relying on a static default center while waiting for GPS.
- **Offline Map Tile Caching**: Pre-caching tile packages (MBTiles) for driving through low-connectivity areas.
