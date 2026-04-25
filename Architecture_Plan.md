# FloodAlert — Architecture Plan & Implementation Checklist

> **Purpose:** Track every implementation step from scaffold to production-ready app.
> Mark each item `[x]` when verified complete, `[ ]` when pending, `[~]` when partially done.

---

## 1. Project Scaffold

| # | Step | Status | File / Location |
|---|---|---|---|
| 1.1 | Create project directory structure | ✅ Done | `d:/Project/FloodAlert/` |
| 1.2 | `lib/` folder with all sub-packages | ✅ Done | `lib/models/`, `lib/services/`, `lib/background/`, `lib/providers/`, `lib/screens/`, `lib/widgets/` |
| 1.3 | `android/` platform folder | ✅ Done | `android/app/src/main/` |
| 1.4 | `ios/Runner/` platform folder | ✅ Done | `ios/Runner/` |
| 1.5 | Install Flutter SDK on machine | ✅ Done | Flutter 3.41.7 · Dart 3.11.5 (installed at `D:\Project\FloodAlert\flutter\`) |
| 1.6 | Run `flutter pub get` | ✅ Done | 117 packages resolved |
| 1.7 | Verify `flutter analyze lib` passes | ✅ Done | No issues found |

---

## 2. Dependencies (`pubspec.yaml`)

| Package | Version | Purpose | Status |
|---|---|---|---|
| `dio` | ^5.4.0 | HTTP client for CWC API | ✅ Declared |
| `fl_chart` | ^1.1.1 | 24-hour water level line chart | ✅ Declared |
| `flutter_local_notifications` | ^19.2.1 | Threshold alarm notifications | ✅ Declared |
| `workmanager` | ^0.9.0+3 | Hourly background fetch | ✅ Declared |
| `hive` | ^2.2.3 | Historical readings storage | ✅ Declared |
| `hive_flutter` | ^1.1.0 | Hive Flutter integration | ✅ Declared |
| `shared_preferences` | ^2.2.2 | Settings (threshold, pause flag) | ✅ Declared |
| `provider` | ^6.1.2 | State management | ✅ Declared |
| `intl` | ^0.19.0 | Date/time formatting for chart | ✅ Declared |
| `hive_generator` (dev) | ^2.0.1 | Hive adapter code generation | ✅ Declared |
| `build_runner` (dev) | ^2.4.8 | Code generation runner | ✅ Declared |

---

## 3. Data Layer

### 3.1 WaterReading Model
| # | Step | Status | File |
|---|---|---|---|
| 3.1.1 | `WaterReading` class with `@HiveType(typeId: 0)` | ✅ Done | [lib/models/water_reading.dart](lib/models/water_reading.dart) |
| 3.1.2 | Fields: `dataTime` (DateTime), `waterLevel` (double), `stationCode` (String) | ✅ Done | [lib/models/water_reading.dart](lib/models/water_reading.dart) |
| 3.1.3 | `WaterReading.fromJson()` factory — parses `id.dataTime`, `dataValue`, `id.stationCode` | ✅ Done | [lib/models/water_reading.dart:16](lib/models/water_reading.dart#L16) |
| 3.1.4 | `WaterReadingAdapter` (Hive TypeAdapter) | ✅ Done (pre-generated) | [lib/models/water_reading.g.dart](lib/models/water_reading.g.dart) |
| 3.1.5 | Run `build_runner` to verify generated adapter compiles | ✅ Done | 43 outputs, 0 errors |

### 3.2 StorageService
| # | Step | Status | File |
|---|---|---|---|
| 3.2.1 | `StorageService.init()` — opens Hive box + SharedPreferences | ✅ Done | [lib/services/storage_service.dart:17](lib/services/storage_service.dart#L17) |
| 3.2.2 | `saveReadings()` — upsert by `dataTime` ms key (prevents duplicates) | ✅ Done | [lib/services/storage_service.dart:22](lib/services/storage_service.dart#L22) |
| 3.2.3 | `getReadings()` — sorted ascending by `dataTime` | ✅ Done | [lib/services/storage_service.dart:31](lib/services/storage_service.dart#L31) |
| 3.2.4 | `_pruneOldReadings()` — deletes entries older than 48 hours | ✅ Done | [lib/services/storage_service.dart:37](lib/services/storage_service.dart#L37) |
| 3.2.5 | `getThreshold()` / `saveThreshold()` — SharedPrefs double, default 8.0 m | ✅ Done | [lib/services/storage_service.dart:46](lib/services/storage_service.dart#L46) |
| 3.2.6 | `isFetchingPaused()` / `savePaused()` — SharedPrefs bool, default false | ✅ Done | [lib/services/storage_service.dart:50](lib/services/storage_service.dart#L50) |

---

## 4. API Integration

### 4.1 WaterApiService
| # | Step | Status | File |
|---|---|---|---|
| 4.1.1 | Dio client with 15s connect/receive timeout | ✅ Done | [lib/services/water_api_service.dart:13](lib/services/water_api_service.dart#L13) |
| 4.1.2 | `fetchLast24Hours()` — dynamic date range (UTC now − 24h to now) | ✅ Done | [lib/services/water_api_service.dart:19](lib/services/water_api_service.dart#L19) |
| 4.1.3 | `sort-criteria` JSON matches exact sample URL format: `{"sortOrderDtos":[{"sortDirection":"ASC","field":"id.dataTime"}]}` | ✅ Done | [lib/services/water_api_service.dart:23](lib/services/water_api_service.dart#L23) |
| 4.1.4 | `specification` JSON with station `017-SWRDKOCHI`, datatype `HHS`, `btn` date operator | ✅ Done | [lib/services/water_api_service.dart:29](lib/services/water_api_service.dart#L29) |
| 4.1.5 | Timestamp format `"2022-08-04T17:00:00.000"` (no trailing Z, 23 chars) | ✅ Done | [lib/services/water_api_service.dart:83](lib/services/water_api_service.dart#L83) |
| 4.1.6 | Response parsed to `List<WaterReading>` | ✅ Done | [lib/services/water_api_service.dart:76](lib/services/water_api_service.dart#L76) |
| 4.1.7 | Test live API call returns non-empty data | ✅ Done | Live call returned 3 readings (1.37m, 1.33m, 1.32m) |
| 4.1.8 | Verify `dataValue` maps correctly to `waterLevel` field | ✅ Done | Confirmed: `json['dataValue']` → `waterLevel` double, values are valid metres |

---

## 5. Notification Service

| # | Step | Status | File |
|---|---|---|---|
| 5.1 | `NotificationService.init()` — Android `@mipmap/ic_launcher`, iOS `DarwinInitializationSettings` | ✅ Done | [lib/services/notification_service.dart:13](lib/services/notification_service.dart#L13) |
| 5.2 | `requestPermissions()` — Android 13+ `POST_NOTIFICATIONS` runtime permission | ✅ Done | [lib/services/notification_service.dart:24](lib/services/notification_service.dart#L24) |
| 5.3 | `showThresholdAlert()` — high priority, fixed `notifId = 1` (replaces, no spam) | ✅ Done | [lib/services/notification_service.dart:31](lib/services/notification_service.dart#L31) |
| 5.4 | Notification channel id `flood_alert_channel` | ✅ Done | [lib/services/notification_service.dart:7](lib/services/notification_service.dart#L7) |
| 5.5 | Test notification appears when threshold is crossed | ⬜ Pending | Set threshold below current level, trigger fetch |

---

## 6. Background Task (WorkManager)

| # | Step | Status | File |
|---|---|---|---|
| 6.1 | `callbackDispatcher()` as top-level function (not inside any class) | ✅ Done | [lib/background/background_task.dart:11](lib/background/background_task.dart#L11) |
| 6.2 | `@pragma('vm:entry-point')` annotation — prevents release build tree-shaking | ✅ Done | [lib/background/background_task.dart:10](lib/background/background_task.dart#L10) |
| 6.3 | Independent re-initialization of Hive, StorageService, in isolate | ✅ Done | [lib/background/background_task.dart:14](lib/background/background_task.dart#L14) |
| 6.4 | Pause check — returns early if `isFetchingPaused()` | ✅ Done | [lib/background/background_task.dart:20](lib/background/background_task.dart#L20) |
| 6.5 | Fetches → saves → checks threshold → notifies | ✅ Done | [lib/background/background_task.dart:22](lib/background/background_task.dart#L22) |
| 6.6 | Returns `false` on exception (triggers WorkManager linear backoff retry) | ✅ Done | [lib/background/background_task.dart:41](lib/background/background_task.dart#L41) |
| 6.7 | `BackgroundTaskManager.initialize()` — registers dispatcher | ✅ Done | [lib/background/background_task.dart:52](lib/background/background_task.dart#L52) |
| 6.8 | `scheduleHourlyFetch()` — 1h period, `NetworkType.connected`, `ExistingWorkPolicy.keep` | ✅ Done | [lib/background/background_task.dart:59](lib/background/background_task.dart#L59) |
| 6.9 | `cancelHourlyFetch()` — cancels by unique name | ✅ Done | [lib/background/background_task.dart:71](lib/background/background_task.dart#L71) |
| 6.10 | `runOnce()` helper for manual test trigger | ✅ Done | [lib/background/background_task.dart:76](lib/background/background_task.dart#L76) |
| 6.11 | Test background task fires and populates Hive | ⬜ Pending | `BackgroundTaskManager.runOnce()` + check storage after 30s |
| 6.12 | Verify on Android with `adb shell dumpsys jobscheduler \| grep flood_alert` | ⬜ Pending | Device/emulator |

---

## 7. State Management (Provider)

### 7.1 WaterDataProvider
| # | Step | Status | File |
|---|---|---|---|
| 7.1.1 | `loadFromStorage()` — synchronous cache load, immediate UI render | ✅ Done | [lib/providers/water_data_provider.dart:44](lib/providers/water_data_provider.dart#L44) |
| 7.1.2 | `refreshFromApi()` — async fetch, sets `isLoading`, catches errors | ✅ Done | [lib/providers/water_data_provider.dart:49](lib/providers/water_data_provider.dart#L49) |
| 7.1.3 | `currentReading` getter — last element of ASC sorted list | ✅ Done | [lib/providers/water_data_provider.dart:29](lib/providers/water_data_provider.dart#L29) |
| 7.1.4 | `previousHourReading` getter — most recent reading older than 1 hour | ✅ Done | [lib/providers/water_data_provider.dart:32](lib/providers/water_data_provider.dart#L32) |
| 7.1.5 | `levelDelta` getter — positive = rising, negative = falling, null if no prev | ✅ Done | [lib/providers/water_data_provider.dart:42](lib/providers/water_data_provider.dart#L42) |
| 7.1.6 | `lastUpdated` getter — timestamp of latest reading | ✅ Done | [lib/providers/water_data_provider.dart:48](lib/providers/water_data_provider.dart#L48) |
| 7.1.7 | `errorMessage` exposed for UI error banner | ✅ Done | [lib/providers/water_data_provider.dart:18](lib/providers/water_data_provider.dart#L18) |

### 7.2 SettingsProvider
| # | Step | Status | File |
|---|---|---|---|
| 7.2.1 | `threshold` and `isPaused` initialized from StorageService in constructor | ✅ Done | [lib/providers/settings_provider.dart:14](lib/providers/settings_provider.dart#L14) |
| 7.2.2 | `setThreshold()` — saves to SharedPrefs, notifies listeners | ✅ Done | [lib/providers/settings_provider.dart:20](lib/providers/settings_provider.dart#L20) |
| 7.2.3 | `togglePause()` — flips flag, cancels or re-schedules WorkManager task | ✅ Done | [lib/providers/settings_provider.dart:26](lib/providers/settings_provider.dart#L26) |

---

## 8. User Interface

### 8.1 App Root
| # | Step | Status | File |
|---|---|---|---|
| 8.1.1 | `FloodAlertApp` — Material 3 theme, seed color blue | ✅ Done | [lib/app.dart](lib/app.dart) |
| 8.1.2 | Named route `/settings` wired to `SettingsScreen` | ✅ Done | [lib/app.dart](lib/app.dart) |
| 8.1.3 | `MultiProvider` wrapping app with both providers | ✅ Done | [lib/main.dart:32](lib/main.dart#L32) |

### 8.2 HomeScreen
| # | Step | Status | File |
|---|---|---|---|
| 8.2.1 | AppBar with station subtitle "Kallooppara · Manimala River" | ✅ Done | [lib/screens/home_screen.dart:36](lib/screens/home_screen.dart#L36) |
| 8.2.2 | AppBar actions: `PauseToggleButton` + settings icon | ✅ Done | [lib/screens/home_screen.dart:53](lib/screens/home_screen.dart#L53) |
| 8.2.3 | `initState` calls `loadFromStorage()` then `refreshFromApi()` | ✅ Done | [lib/screens/home_screen.dart:18](lib/screens/home_screen.dart#L18) |
| 8.2.4 | `RefreshIndicator` — pull-to-refresh triggers API fetch | ✅ Done | [lib/screens/home_screen.dart:65](lib/screens/home_screen.dart#L65) |
| 8.2.5 | Orange "Monitoring paused" banner when `isPaused = true` | ✅ Done | [lib/screens/home_screen.dart:73](lib/screens/home_screen.dart#L73) |
| 8.2.6 | Red error banner when `errorMessage != null` | ✅ Done | [lib/screens/home_screen.dart:93](lib/screens/home_screen.dart#L93) |
| 8.2.7 | `LinearProgressIndicator` while `isLoading = true` | ✅ Done | [lib/screens/home_screen.dart:111](lib/screens/home_screen.dart#L111) |
| 8.2.8 | `WaterLevelCard` widget in body | ✅ Done | [lib/screens/home_screen.dart:117](lib/screens/home_screen.dart#L117) |
| 8.2.9 | `WaterLevelChart` widget in body | ✅ Done | [lib/screens/home_screen.dart:119](lib/screens/home_screen.dart#L119) |
| 8.2.10 | Station code footer label | ✅ Done | [lib/screens/home_screen.dart:121](lib/screens/home_screen.dart#L121) |

### 8.3 WaterLevelCard Widget
| # | Step | Status | File |
|---|---|---|---|
| 8.3.1 | Displays current water level in large text (e.g. `7.03 m`) | ✅ Done | [lib/widgets/water_level_card.dart](lib/widgets/water_level_card.dart) |
| 8.3.2 | Shows `—` placeholder when no data yet | ✅ Done | [lib/widgets/water_level_card.dart:30](lib/widgets/water_level_card.dart#L30) |
| 8.3.3 | Embeds `LevelIndicator` for rise/drop | ✅ Done | [lib/widgets/water_level_card.dart:50](lib/widgets/water_level_card.dart#L50) |
| 8.3.4 | Shows "Last updated" timestamp | ✅ Done | [lib/widgets/water_level_card.dart:53](lib/widgets/water_level_card.dart#L53) |

### 8.4 LevelIndicator Widget
| # | Step | Status | File |
|---|---|---|---|
| 8.4.1 | Green ▲ + `+X.XXm` when rising | ✅ Done | [lib/widgets/level_indicator.dart:26](lib/widgets/level_indicator.dart#L26) |
| 8.4.2 | Blue ▼ + `-X.XXm` when falling | ✅ Done | [lib/widgets/level_indicator.dart:26](lib/widgets/level_indicator.dart#L26) |
| 8.4.3 | Orange `—` Stable when delta < 0.01 | ✅ Done | [lib/widgets/level_indicator.dart:20](lib/widgets/level_indicator.dart#L20) |
| 8.4.4 | Shows grey dash when no previous data | ✅ Done | [lib/widgets/level_indicator.dart:10](lib/widgets/level_indicator.dart#L10) |

### 8.5 WaterLevelChart Widget
| # | Step | Status | File |
|---|---|---|---|
| 8.5.1 | `LineChart` from `fl_chart` with smooth curve | ✅ Done | [lib/widgets/water_level_chart.dart:49](lib/widgets/water_level_chart.dart#L49) |
| 8.5.2 | Blue fill area below the line | ✅ Done | [lib/widgets/water_level_chart.dart:56](lib/widgets/water_level_chart.dart#L56) |
| 8.5.3 | Dynamic Y-axis range (min/max from data ± padding) | ✅ Done | [lib/widgets/water_level_chart.dart:31](lib/widgets/water_level_chart.dart#L31) |
| 8.5.4 | X-axis shows HH:mm time labels (max 6 labels) | ✅ Done | [lib/widgets/water_level_chart.dart:84](lib/widgets/water_level_chart.dart#L84) |
| 8.5.5 | Dashed red horizontal line at alert threshold level | ✅ Done | [lib/widgets/water_level_chart.dart:64](lib/widgets/water_level_chart.dart#L64) |
| 8.5.6 | "Alert X.Xm" label on threshold line | ✅ Done | [lib/widgets/water_level_chart.dart:70](lib/widgets/water_level_chart.dart#L70) |
| 8.5.7 | Empty state: "No data yet — pull to refresh" | ✅ Done | [lib/widgets/water_level_chart.dart:21](lib/widgets/water_level_chart.dart#L21) |

### 8.6 PauseToggleButton Widget
| # | Step | Status | File |
|---|---|---|---|
| 8.6.1 | Shows ▶ (resume) icon when paused | ✅ Done | [lib/widgets/pause_toggle_button.dart:13](lib/widgets/pause_toggle_button.dart#L13) |
| 8.6.2 | Shows ⏸ (pause) icon when monitoring active | ✅ Done | [lib/widgets/pause_toggle_button.dart:13](lib/widgets/pause_toggle_button.dart#L13) |
| 8.6.3 | Calls `SettingsProvider.togglePause()` on tap | ✅ Done | [lib/widgets/pause_toggle_button.dart:21](lib/widgets/pause_toggle_button.dart#L21) |
| 8.6.4 | SnackBar feedback message after toggle | ✅ Done | [lib/widgets/pause_toggle_button.dart:23](lib/widgets/pause_toggle_button.dart#L23) |

### 8.7 SettingsScreen
| # | Step | Status | File |
|---|---|---|---|
| 8.7.1 | Threshold slider (1.0 – 15.0 m, 140 divisions = 0.1 m steps) | ✅ Done | [lib/screens/settings_screen.dart:56](lib/screens/settings_screen.dart#L56) |
| 8.7.2 | Large numeric display of current threshold value | ✅ Done | [lib/screens/settings_screen.dart:80](lib/screens/settings_screen.dart#L80) |
| 8.7.3 | `SwitchListTile` for pause/resume with dynamic subtitle | ✅ Done | [lib/screens/settings_screen.dart:98](lib/screens/settings_screen.dart#L98) |
| 8.7.4 | Station info section: name, river, code, state, source, interval | ✅ Done | [lib/screens/settings_screen.dart:122](lib/screens/settings_screen.dart#L122) |

---

## 9. App Initialization (`main.dart`)

| # | Step | Status | Sequence |
|---|---|---|---|
| 9.1 | `WidgetsFlutterBinding.ensureInitialized()` — first line | ✅ Done | Step 1 |
| 9.2 | `Hive.initFlutter()` | ✅ Done | Step 2 |
| 9.3 | `Hive.registerAdapter(WaterReadingAdapter())` | ✅ Done | Step 3 |
| 9.4 | `StorageService.init()` | ✅ Done | Step 4 |
| 9.5 | `NotificationService.init()` + `requestPermissions()` | ✅ Done | Step 5 |
| 9.6 | `BackgroundTaskManager.initialize()` | ✅ Done | Step 6 |
| 9.7 | `scheduleHourlyFetch()` only if not paused | ✅ Done | Step 7 |
| 9.8 | `runApp()` with `MultiProvider` | ✅ Done | Step 8 |

---

## 10. Android Platform Configuration

| # | Step | Status | File |
|---|---|---|---|
| 10.1 | `INTERNET` permission | ✅ Done | [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) |
| 10.2 | `RECEIVE_BOOT_COMPLETED` permission (WorkManager) | ✅ Done | [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) |
| 10.3 | `WAKE_LOCK` permission (WorkManager) | ✅ Done | [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) |
| 10.4 | `POST_NOTIFICATIONS` permission (Android 13+) | ✅ Done | [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml) |
| 10.5 | WorkManager `InitializationProvider` in `<application>` | ✅ Done | Handled automatically by `workmanager` plugin — do NOT add manually (crashes on WorkManager 2.9+) |
| 10.6 | `minSdkVersion 21` (required by WorkManager) | ✅ Done | [android/app/build.gradle](android/app/build.gradle) |
| 10.7 | `MainActivity.kt` extending `FlutterActivity` | ✅ Done | [android/app/src/main/kotlin/com/floodalert/flood_alert/MainActivity.kt](android/app/src/main/kotlin/com/floodalert/flood_alert/MainActivity.kt) |
| 10.8 | Root `build.gradle` with kotlin + AGP versions | ✅ Done | [android/build.gradle](android/build.gradle) |
| 10.9 | `gradle.properties` with AndroidX and jetifier | ✅ Done | [android/gradle.properties](android/gradle.properties) |
| 10.10 | Add release signing config for production APK | ⬜ Pending | `android/app/build.gradle` — add keystore |
| 10.11 | Build and install APK on Android device | ✅ Done | Installed and running on Moto G32 (Android 13, arm64) |

---

## 11. iOS Platform Configuration

| # | Step | Status | File |
|---|---|---|---|
| 11.1 | `UIBackgroundModes` — `fetch` + `background-processing` | ✅ Done | [ios/Runner/Info.plist](ios/Runner/Info.plist) |
| 11.2 | `NSUserNotificationUsageDescription` string | ✅ Done | [ios/Runner/Info.plist](ios/Runner/Info.plist) |
| 11.3 | `WorkmanagerPlugin.registerTask()` in `AppDelegate.swift` | ✅ Done | [ios/Runner/AppDelegate.swift](ios/Runner/AppDelegate.swift) |
| 11.4 | Enable **Background Modes** capability in Xcode | ⬜ Pending | Xcode → Signing & Capabilities |
| 11.5 | Check "Background fetch" + "Background processing" in Xcode | ⬜ Pending | Xcode → Signing & Capabilities |
| 11.6 | Build and run on iOS device / simulator | ⬜ Pending | `flutter run` with Xcode toolchain |

---

## 12. End-to-End Verification

| # | Test | How to Verify | Status |
|---|---|---|---|
| 12.1 | App launches without crash | Run `flutter run`, check no error | ✅ Done |
| 12.2 | API returns live water level data | Check `WaterLevelCard` shows a value | ✅ Done — showing 1.32 m live |
| 12.3 | Chart renders with time-labelled X axis | Scroll to chart section | ✅ Done |
| 12.4 | Rise/drop indicator shows correct direction | Compare card value with previous | ✅ Done — showing Stable (level is falling slowly, delta < 0.01m) |
| 12.5 | Threshold line appears correctly on chart | Set threshold in settings, check chart | ✅ Done |
| 12.6 | Notification fires when level ≥ threshold | Set threshold to 0.1 m, trigger fetch | ⬜ Pending |
| 12.7 | Pause toggle stops WorkManager task | `adb shell dumpsys jobscheduler \| grep flood_alert` | ⬜ Pending |
| 12.8 | Resume re-registers WorkManager task | Toggle pause off, repeat adb check | ⬜ Pending |
| 12.9 | Background task runs and writes to Hive | Call `runOnce()`, wait 30s, check data | ⬜ Pending |
| 12.10 | Pull-to-refresh fetches new data | Pull down on home screen | ⬜ Pending |
| 12.11 | No duplicate readings in Hive on repeated fetch | Fetch twice, count Hive entries | ⬜ Pending |
| 12.12 | Old data (>48h) is pruned from Hive | Insert old entry manually, trigger fetch | ⬜ Pending |

---

## 13. Remaining Work (Not Yet Implemented)

| # | Feature | Priority | Notes |
|---|---|---|---|
| 13.1 | App icon (`ic_launcher` assets) | Medium | Replace default Flutter icon with flood/wave icon |
| 13.2 | Splash screen | Low | `flutter_native_splash` package |
| 13.3 | Release signing (Android keystore) | High for publish | Required before Google Play upload |
| 13.4 | iOS bundle identifier + Apple Developer account | High for iOS publish | Required before App Store upload |
| 13.5 | Error retry button in UI | Medium | Currently user must pull-to-refresh |
| 13.6 | Multiple station support | Low | Extend `WaterApiService` with station selector |
| 13.7 | Dark mode theme | Low | Add `darkTheme` to `MaterialApp` |
| 13.8 | Alarm sound customization | Low | Different tones for different severity levels |
| 13.9 | Data export (CSV) | Low | Share readings as spreadsheet |

---

## Summary

```
Total steps tracked:   79
✅ Completed:          55
⬜ Pending:            24  (mostly device testing + platform publishing steps)
```

> **Next immediate step:** Install Flutter SDK, run `flutter pub get`, then `flutter run` on an Android emulator or device to verify the app end-to-end.
