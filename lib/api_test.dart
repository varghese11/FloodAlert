import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flood_alert/services/water_api_service.dart';
import 'package:flood_alert/models/water_reading.dart';

void main() async {
  print('Starting API Test...');
  try {
    final api = WaterApiService();
    print('Fetching main station...');
    final readings = await api.fetchLast24Hours();
    print('Fetched ${readings.length} readings for main station.');
    if (readings.isNotEmpty) {
      print('Latest: ${readings.last.waterLevel} at ${readings.last.dataTime}');
    }

    print('Fetching upstream station...');
    final upReadings = await api.fetchLast24Hours(stationCode: WaterStation.pullakkayar);
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
