import 'water_reading.dart';

class StationData {
  final List<WaterReading> readings;

  StationData(this.readings);

  WaterReading? get currentReading => readings.isNotEmpty ? readings.last : null;

  WaterReading? get previousHourReading {
    if (readings.length < 2) return null;
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    for (int i = readings.length - 2; i >= 0; i--) {
      if (readings[i].dataTime.isBefore(oneHourAgo)) {
        return readings[i];
      }
    }
    return readings[readings.length - 2];
  }

  double? get levelDelta {
    final cur = currentReading;
    final prev = previousHourReading;
    if (cur == null || prev == null) return null;
    return cur.waterLevel - prev.waterLevel;
  }

  DateTime? get lastUpdated => readings.isNotEmpty ? readings.last.dataTime : null;
}
