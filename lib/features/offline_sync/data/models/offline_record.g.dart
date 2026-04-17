// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineRecordAdapter extends TypeAdapter<OfflineRecord> {
  @override
  final int typeId = 0;

  @override
  OfflineRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineRecord(
      id: fields[0] as String,
      amount: fields[1] as double,
      date: fields[2] as DateTime,
      customerName: fields[3] as String,
      type: fields[4] as String,
      isSynced: fields[5] as bool,
      payloadJson: fields[6] as String,
      collectionName: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineRecord obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.customerName)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.isSynced)
      ..writeByte(6)
      ..write(obj.payloadJson)
      ..writeByte(7)
      ..write(obj.collectionName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
