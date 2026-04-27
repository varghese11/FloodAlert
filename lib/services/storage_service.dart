import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/water_reading.dart';

class StorageService {
  static const _readingsBoxName = 'water_readings';
  static const _upstreamBoxName = 'upstream_readings';
  static const _thresholdKey = 'alarm_threshold';
  static const _upstreamThresholdKey = 'upstream_alarm_threshold';
  static const _pausedKey = 'is_fetching_paused';
  static const _maxStoredDays = 3;

  late Box<WaterReading> _readingsBox;
  late Box<WaterReading> _upstreamBox;
  late SharedPreferences _prefs;

  Future<void> init() async {
    _readingsBox = await Hive.openBox<WaterReading>(_readingsBoxName);
    _upstreamBox = await Hive.openBox<WaterReading>(_upstreamBoxName);
    _prefs = await SharedPreferences.getInstance();

    await _pruneBox(_readingsBox);
    await _pruneBox(_upstreamBox);
  }

  // --- Shared Storage Logic ---

  Future<void> _saveStationReadings(Box<WaterReading> box, List<WaterReading> readings) async {
    for (final r in readings) {
      await box.put(r.dataTime.millisecondsSinceEpoch.toString(), r);
    }
  }

  List<WaterReading> _getStationReadings(Box<WaterReading> box) {
    return box.values.toList()
      ..sort((a, b) => a.dataTime.compareTo(b.dataTime));
  }

  // --- Main station (KALLOOPPARA) ---

  Future<void> saveReadings(List<WaterReading> readings) => _saveStationReadings(_readingsBox, readings);
  List<WaterReading> getReadings() => _getStationReadings(_readingsBox);
  ValueListenable<Box<WaterReading>> getReadingsListenable() => _readingsBox.listenable();

  // --- Upstream station (PULLAKKAYAR) ---

  Future<void> saveUpstreamReadings(List<WaterReading> readings) => _saveStationReadings(_upstreamBox, readings);
  List<WaterReading> getUpstreamReadings() => _getStationReadings(_upstreamBox);
  ValueListenable<Box<WaterReading>> getUpstreamListenable() => _upstreamBox.listenable();

  Future<void> _pruneBox(Box<WaterReading> box) async {
    final cutoff =
        DateTime.now().subtract(const Duration(days: _maxStoredDays));
    final keysToDelete = box.keys.where((key) {
      final r = box.get(key);
      return r != null && r.dataTime.isBefore(cutoff);
    }).toList();
    await box.deleteAll(keysToDelete);
  }

  // --- Thresholds & settings ---

  double getThreshold() => _prefs.getDouble(_thresholdKey) ?? 5.0;
  Future<void> saveThreshold(double v) => _prefs.setDouble(_thresholdKey, v);

  double getUpstreamThreshold() =>
      _prefs.getDouble(_upstreamThresholdKey) ?? 97.0;
  Future<void> saveUpstreamThreshold(double v) =>
      _prefs.setDouble(_upstreamThresholdKey, v);

  bool isFetchingPaused() => _prefs.getBool(_pausedKey) ?? false;
  Future<void> savePaused(bool v) => _prefs.setBool(_pausedKey, v);
}
