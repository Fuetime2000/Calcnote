// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderModelAdapter extends TypeAdapter<ReminderModel> {
  @override
  final int typeId = 3;

  @override
  ReminderModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderModel(
      id: fields[0] as String,
      noteId: fields[1] as String,
      title: fields[2] as String,
      description: fields[3] as String?,
      reminderTime: fields[4] as DateTime,
      isCompleted: fields[5] as bool,
      isNotified: fields[6] as bool,
      priority: fields[7] as String,
      repeatType: fields[8] as String?,
      createdAt: fields[9] as DateTime,
      completedAt: fields[10] as DateTime?,
      isSnoozed: fields[11] as bool,
      snoozeUntil: fields[12] as DateTime?,
      tags: (fields[13] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ReminderModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.noteId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.reminderTime)
      ..writeByte(5)
      ..write(obj.isCompleted)
      ..writeByte(6)
      ..write(obj.isNotified)
      ..writeByte(7)
      ..write(obj.priority)
      ..writeByte(8)
      ..write(obj.repeatType)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.completedAt)
      ..writeByte(11)
      ..write(obj.isSnoozed)
      ..writeByte(12)
      ..write(obj.snoozeUntil)
      ..writeByte(13)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
