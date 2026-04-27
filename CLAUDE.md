# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

> Flutter SDK is installed at `D:\Project\FloodAlert\flutter\bin\flutter.bat` (Flutter 3.41.7, Dart 3.11.5). If `flutter` isn't on PATH, use the full path.

```bash
# Install dependencies (required after any pubspec.yaml change)
flutter pub get

# Regenerate Hive adapter after modifying water_reading.dart
flutter pub run build_runner build --delete-conflicting-outputs

# Run on connected device or emulator
flutter run

# Build release APK
flutter build apk --release

# Trigger a one-off background fetch for testing
await BackgroundTaskManager.runOnce();
# Then wait ~30 seconds and check Hive data

# Verify WorkManager scheduled tasks on Android
adb shell dumpsys jobscheduler | grep flood_alert

# Get runtime crash logs from connected device
adb logcat -d -s AndroidRuntime:E flutter:*

# Verify the CWC API is reachable (standalone Dart script, no device needed)
dart lib/api_test.dart
```

`water_reading.g.dart` is pre-generated and committed. Only re-run `build_runner` if `water_reading.dart` is changed.

`adb` is at `C:\Users\kukva\AppData\Local\Android\Sdk\platform-tools\adb.exe` if not on PATH.

## Architecture

### Dual-station data flow

```
CWC API (017-SWRDKOCHI — Kallooppara)    ──►┐
                                             ├─► StorageService (Hive) ──► WaterDataProvider ──► UI
CWC API (035-SWRDKOCHI — Pullakkayar)    ──►┘         │
                                                SharedPreferences
                                              (thresholds, pause flag)
                                                       │
                                               SettingsProvider ──► UI
```

Both stations are fetched in **parallel** (`Future.wait`) on every foreground refresh and every background WorkManager tick. Each station has its own Hive box. The UI reads only from Hive, never directly from the API.

### Two-station alert logic

- **Pullakkayar (035-SWRDKOCHI)** is upstream of Kallooppara. When its level crosses `upstreamThreshold` (default 97, gauge units), an **early warning** alarm fires — Kallooppara will rise shortly after.
- **Kallooppara (017-SWRDKOCHI)** triggers the main **flood alert** alarm when its level crosses `threshold` (default 5.0 m).
- Both alerts use the same `flood_alarm_channel` which plays the **device's system alarm ringtone** (`content://settings/system/alarm_alert`) at `Importance.max` with `fullScreenIntent: true`.
- Station constants live in `WaterStation` in `lib/services/water_api_service.dart`.

### Background isolate constraint (critical)

`callbackDispatcher()` in `lib/background/background_task.dart` runs in a **separate Dart isolate** with no shared memory. It must re-initialize every dependency from scratch: `Hive.initFlutter()`, `Hive.registerAdapter()`, `StorageService.init()`. Never pass Provider state, BuildContext, or any singleton from the main isolate.

The `@pragma('vm:entry-point')` annotation on `callbackDispatcher` is **required** — without it, `flutter build --release` tree-shakes the function and background tasks silently do nothing.

`Hive.registerAdapter` is guarded with `Hive.isAdapterRegistered(0)` before calling it, because on some devices WorkManager reuses the same Dart engine across task runs and a second unconditional registration throws.

WorkManager is registered with `ExistingPeriodicWorkPolicy.keep` — repeated `scheduleHourlyFetch()` calls on each app startup do not reset the 1-hour countdown. Only a first-ever run or an explicit `cancelHourlyFetch()` + re-schedule changes the timer.

### Storage

| Data | Storage | Key / Default |
|---|---|---|
| Kallooppara readings (up to 3 days) | Hive box `water_readings` | `dataTime.millisecondsSinceEpoch.toString()` |
| Pullakkayar readings (up to 3 days) | Hive box `upstream_readings` | same key scheme |
| Kallooppara alert threshold | SharedPreferences `alarm_threshold` | 5.0 m |
| Pullakkayar early-warning threshold | SharedPreferences `upstream_alarm_threshold` | 97.0 (gauge units) |
| Pause flag | SharedPreferences `is_fetching_paused` | false |

Hive keys are idempotent — repeated fetches never create duplicates. `StorageService.init()` prunes both boxes to 3 days (`_maxStoredDays = 3`) on every call (foreground and background).

### State management

Two `ChangeNotifier` providers injected in `main.dart`:

- **`WaterDataProvider`** — owns readings for both stations. Exposes `mainStation` and `upstreamStation` as `StationData` objects (see below). `loadFromStorage()` is synchronous (cache-first render); `refreshFromApi()` fetches both stations in parallel and sets `apiReturnedEmpty = true` when **both** stations return empty — only triggered by foreground refreshes, not by the background task. Also subscribes to Hive `ValueListenable` on both boxes, so background task writes are automatically reflected in the UI without a manual refresh.
- **`SettingsProvider`** — owns `threshold`, `upstreamThreshold`, and `isPaused`. `togglePause()` is the single place that cancels or re-registers the WorkManager task.

### StationData model

`lib/models/station_data.dart` is a value object that wraps a `List<WaterReading>` and computes derived properties: `currentReading` (last entry), `previousHourReading` (most recent entry older than 1 hour ago), `levelDelta` (difference between the two), and `lastUpdated`. Both providers expose station data through this type — access readings via `provider.mainStation.currentReading`, not raw list indexes.

### CWC API

- Endpoint: `GET https://ffs.india-water.gov.in/iam/api/new-entry-data/specification/sorted`
- Datatype: `HHS`
- Both `sort-criteria` and `specification` are passed as **JSON-encoded strings** in query parameters. The exact JSON structure for `sort-criteria` must match `{"sortOrderDtos":[{"sortDirection":"ASC","field":"id.dataTime"}]}` — the API is strict about this shape.
- Timestamps use the format `"2022-08-04T17:00:00.000"` (23 chars, no trailing `Z`). See `WaterApiService._formatForApi()`.
- `WaterApiService.fetchReadings()` requests a **72-hour** lookback window by default, matching the 3-day storage retention period. This ensures sparse or temporarily-offline stations are caught on the next run, and fresh installs are populated with recent historical data.
- Stations report only a few readings per day — sparse data is normal.
- Pullakkayar (035-SWRDKOCHI) gauge readings are in different units than Kallooppara (017-SWRDKOCHI) metres — do not compare them directly.

### Initialization order in `main.dart`

Order matters — Hive must be initialized before any box is opened, and `StorageService.init()` must complete before providers are constructed.

```
Hive.initFlutter → registerAdapter → StorageService.init   (opens both Hive boxes)
→ NotificationService.init + requestPermissions             (creates alarm channel)
→ BackgroundTaskManager.initialize → scheduleHourlyFetch (if not paused)
→ _requestBatteryOptimizationExemption                      (com.floodalert/battery MethodChannel → MainActivity.kt)
→ runApp(MultiProvider → FloodAlertApp)
```

### Android build configuration

The Android project uses the **declarative Gradle plugins DSL** (migrated from the legacy `apply from:` style). Plugin versions are declared in `android/settings.gradle`, not `android/build.gradle`.

- Gradle 8.9, AGP 8.7.2, Kotlin 2.1.0
- `coreLibraryDesugaringEnabled true` — required by `flutter_local_notifications`
- `minSdkVersion 21` — required by WorkManager. Do not lower it.
- Do **not** add a `<provider>` block for `androidx.work.impl.WorkManagerInitializer` to `AndroidManifest.xml` — that class was removed in WorkManager 2.9+ and causes an immediate crash on launch. The plugin registers itself automatically.
- `USE_FULL_SCREEN_INTENT` permission is declared — required for alarm-style over-lockscreen notifications on Android 14+.

### Notification channel lock-in

Android caches notification channel settings (sound, importance, vibration) **by channel ID on first creation** and ignores all subsequent changes to the same ID. If the alarm sound or importance level ever needs to change, register a **new channel ID** in `NotificationService` — do not reuse `flood_alarm_channel`. The current channel uses `content://settings/system/alarm_alert` (device default alarm ringtone).
