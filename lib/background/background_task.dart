import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import '../models/water_reading.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/water_api_service.dart';

// Must be top-level — runs in a fresh Dart isolate.
// @pragma annotation prevents release tree-shaking.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(WaterReadingAdapter());
      }

      final storage = StorageService();
      await storage.init();

      if (storage.isFetchingPaused()) return true;

      final api = WaterApiService();
      final notif = NotificationService();
      await notif.init();

      // Fetch all stations in parallel, handling failures independently
      final upstreamFuture = () async {
        final upstreamReadings = await api.fetchReadings(stationCode: WaterStation.pullakkayar);
        if (upstreamReadings.isNotEmpty) {
          await storage.saveUpstreamReadings(upstreamReadings);
          final upstreamLevel = upstreamReadings.last.waterLevel;
          final upstreamThreshold = storage.getUpstreamThreshold();
          if (upstreamLevel >= upstreamThreshold) {
            await notif.showUpstreamAlert(
              currentLevel: upstreamLevel,
              threshold: upstreamThreshold,
            );
          }
        }
      }();

      final manikalFuture = () async {
        final manikalReadings = await api.fetchReadings(stationCode: WaterStation.manikal);
        if (manikalReadings.isNotEmpty) {
          await storage.saveManikalReadings(manikalReadings);
          final manikalLevel = manikalReadings.last.waterLevel;
          final manikalThreshold = storage.getManikalThreshold();
          if (manikalLevel >= manikalThreshold) {
            await notif.showManikalAlert(
              currentLevel: manikalLevel,
              threshold: manikalThreshold,
            );
          }
        }
      }();

      final mainFuture = () async {
        final mainReadings = await api.fetchReadings(stationCode: WaterStation.kallooppara);
        if (mainReadings.isNotEmpty) {
          await storage.saveReadings(mainReadings);
          final mainLevel = mainReadings.last.waterLevel;
          final threshold = storage.getThreshold();
          if (mainLevel >= threshold) {
            await notif.showThresholdAlert(
              currentLevel: mainLevel,
              threshold: threshold,
            );
          }
        }
      }();

      bool upstreamSuccess = false;
      bool manikalSuccess = false;
      bool mainSuccess = false;

      try {
        await upstreamFuture;
        upstreamSuccess = true;
      } catch (_) {}

      try {
        await manikalFuture;
        manikalSuccess = true;
      } catch (_) {}

      try {
        await mainFuture;
        mainSuccess = true;
      } catch (_) {}

      return upstreamSuccess && manikalSuccess && mainSuccess;
    } catch (_) {
      // false triggers WorkManager retry with backoff
      return false;
    }
  });
}

class BackgroundTaskManager {
  static const _uniqueTaskName = 'flood_alert_unique';
  static const _taskName = 'flood_alert_hourly';

  static Future<void> initialize() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  static Future<void> scheduleHourlyFetch() async {
    await Workmanager().registerPeriodicTask(
      _uniqueTaskName,
      _taskName,
      frequency: const Duration(hours: 1),
      constraints: Constraints(networkType: NetworkType.connected),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      backoffPolicy: BackoffPolicy.linear,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }

  static Future<void> cancelHourlyFetch() async {
    await Workmanager().cancelByUniqueName(_uniqueTaskName);
  }

  static Future<void> runOnce() async {
    await Workmanager().registerOneOffTask(
      '${_uniqueTaskName}_once',
      _taskName,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
}
