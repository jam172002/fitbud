// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'checkin_outbox_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CheckinOutboxItemAdapter extends TypeAdapter<CheckinOutboxItem> {
  @override
  final int typeId = 51;

  @override
  CheckinOutboxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckinOutboxItem(
      clientCheckinId: fields[0] as String,
      gymId: fields[1] as String,
      createdAtMs: fields[2] as int,
      status: fields[3] as String,
      attempts: fields[4] as int,
      lastError: fields[5] as String,   
    );
  }

  @override
  void write(BinaryWriter writer, CheckinOutboxItem obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.clientCheckinId)
      ..writeByte(1)
      ..write(obj.gymId)
      ..writeByte(2)
      ..write(obj.createdAtMs)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.attempts)
      ..writeByte(5)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CheckinOutboxItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
