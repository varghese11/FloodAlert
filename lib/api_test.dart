import 'dart:io';
import 'package:flood_alert/services/water_api_service.dart';

void main() async {
  print('Starting API Test...');
  try {
    final api = WaterApiService();
    print('Fetching main station...');
    final readings = await api.fetchReadings();
    print('Fetched ${readings.length} readings for main station.');
    if (readings.isNotEmpty) {
      print('Latest: ${readings.last.waterLevel} at ${readings.last.dataTime}');
    }

    print('Fetching upstream station...');
    final upReadings = await api.fetchReadings(stationCode: WaterStation.pullakkayar);
    print('Fetched ${upReadings.length} readings for upstream station.');
    if (upReadings.isNotEmpty) {
      print('Latest: ${upReadings.last.waterLevel} at ${upReadings.last.dataTime}');
    }
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
  exit(0);
}
