// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_reading.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterReadingAdapter extends TypeAdapter<WaterReading> {
  @override
  final int typeId = 0;

  @override
  WaterReading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterReading(
      dataTime: fields[0] as DateTime,
      waterLevel: fields[1] as double,
      stationCode: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, WaterReading obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dataTime)
      ..writeByte(1)
      ..write(obj.waterLevel)
      ..writeByte(2)
      ..write(obj.stationCode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterReadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
