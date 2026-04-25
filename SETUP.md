# FloodAlert — Setup Guide

## Prerequisites
- Flutter SDK ≥ 3.10 installed and in PATH
- Android Studio / Xcode for platform builds

## First-time setup

```bash
# Install dependencies
flutter pub get

# The Hive adapter (water_reading.g.dart) is pre-generated.
# If you modify water_reading.dart, regenerate with:
flutter pub run build_runner build --delete-conflicting-outputs
```

## Run

```bash
flutter run
```

## Android notes
- `minSdkVersion 21` required by WorkManager
- Add your keystore to `android/app` and update `build.gradle` for release signing

## iOS notes
- Open `ios/Runner.xcworkspace` in Xcode
- In **Signing & Capabilities** → add **Background Modes** capability
- Check "Background fetch" and "Background processing"
- These modes enable WorkManager periodic tasks on iOS

## Testing background fetch manually

```dart
// In main.dart or a debug button, trigger a one-off task:
await BackgroundTaskManager.runOnce();
// Check Hive data after ~30 seconds
```

On Android you can also verify scheduled work:
```bash
adb shell dumpsys jobscheduler | grep flood_alert
```

## Key files

| File | Purpose |
|---|---|
| `lib/services/water_api_service.dart` | CWC API client |
| `lib/background/background_task.dart` | Hourly WorkManager task |
| `lib/providers/water_data_provider.dart` | State: readings + delta |
| `lib/providers/settings_provider.dart` | State: threshold + pause |
| `lib/screens/home_screen.dart` | Main dashboard |
| `lib/screens/settings_screen.dart` | Threshold slider + pause toggle |
