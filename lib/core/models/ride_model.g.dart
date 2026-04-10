// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ride_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RideModelAdapter extends TypeAdapter<RideModel> {
  @override
  final int typeId = 0;

  @override
  RideModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RideModel(
      id: fields[0] as String,
      startTime: fields[1] as DateTime,
      endTime: fields[2] as DateTime?,
      latitudes: (fields[3] as List).cast<double>(),
      longitudes: (fields[4] as List).cast<double>(),
      distanceKm: fields[5] as double,
      maxSpeedKmh: fields[6] as double,
      avgSpeedKmh: fields[7] as double,
      coinsEarned: fields[8] as int,
      vehicleName: fields[9] as String?,
      title: fields[10] as String?,
      isSynced: fields[11] == null ? false : fields[11] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, RideModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime)
      ..writeByte(3)
      ..write(obj.latitudes)
      ..writeByte(4)
      ..write(obj.longitudes)
      ..writeByte(5)
      ..write(obj.distanceKm)
      ..writeByte(6)
      ..write(obj.maxSpeedKmh)
      ..writeByte(7)
      ..write(obj.avgSpeedKmh)
      ..writeByte(8)
      ..write(obj.coinsEarned)
      ..writeByte(9)
      ..write(obj.vehicleName)
      ..writeByte(10)
      ..write(obj.title)
      ..writeByte(11)
      ..write(obj.isSynced);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RideModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
