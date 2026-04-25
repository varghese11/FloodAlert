import 'package:hive/hive.dart';

part 'water_reading.g.dart';

@HiveType(typeId: 0)
class WaterReading extends HiveObject {
  @HiveField(0)
  final DateTime dataTime;

  @HiveField(1)
  final double waterLevel;

  @HiveField(2)
  final String stationCode;

  WaterReading({
    required this.dataTime,
    required this.waterLevel,
    required this.stationCode,
  });

  factory WaterReading.fromJson(Map<String, dynamic> json) {
    return WaterReading(
      dataTime: DateTime.parse(json['id']['dataTime'] as String).toLocal(),
      waterLevel: (json['dataValue'] as num).toDouble(),
      stationCode: json['id']['stationCode'] as String,
    );
  }
}
