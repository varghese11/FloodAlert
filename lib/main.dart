import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'background/background_task.dart';
import 'models/water_reading.dart';
import 'providers/settings_provider.dart';
import 'providers/water_data_provider.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/water_api_service.dart';

const _batteryChannel = MethodChannel('com.floodalert/battery');

Future<void> _requestBatteryOptimizationExemption() async {
  try {
    final isIgnoring =
        await _batteryChannel.invokeMethod<bool>('isIgnoringBatteryOptimizations') ?? false;
    if (!isIgnoring) {
      await _batteryChannel.invokeMethod('requestIgnoreBatteryOptimizations');
    }
  } catch (_) {
    // Non-Android platforms or older OS versions — safe to ignore.
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(WaterReadingAdapter());

  final storageService = StorageService();
  await storageService.init();

  final notificationService = NotificationService();
  await notificationService.init();
  await notificationService.requestPermissions();

  await BackgroundTaskManager.initialize();
  if (!storageService.isFetchingPaused()) {
    await BackgroundTaskManager.scheduleHourlyFetch();
  }
  await _requestBatteryOptimizationExemption();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              WaterDataProvider(storageService, WaterApiService()),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService),
        ),
      ],
      child: const FloodAlertApp(),
    ),
  );
}
