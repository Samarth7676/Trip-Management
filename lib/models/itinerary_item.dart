import 'package:hive/hive.dart';
import 'enums.dart';

class ItineraryItem extends HiveObject {
  String id;
  String tripId;
  ItineraryType type;
  String title;
  String location;
  DateTime startDateTime;
  DateTime? endDateTime;
  String notes;
  int reminderMinutesBefore;
  String confirmationNumber;
  int notificationId;

  ItineraryItem({
    required this.id,
    required this.tripId,
    required this.type,
    required this.title,
    required this.location,
    required this.startDateTime,
    this.endDateTime,
    this.notes = '',
    this.reminderMinutesBefore = 120,
    this.confirmationNumber = '',
    required this.notificationId,
  });
}

class ItineraryItemAdapter extends TypeAdapter<ItineraryItem> {
  @override
  final int typeId = 3;

  @override
  ItineraryItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return ItineraryItem(
      id: fields[0] as String,
      tripId: fields[1] as String,
      type: fields[2] as ItineraryType,
      title: fields[3] as String,
      location: fields[4] as String,
      startDateTime: fields[5] as DateTime,
      endDateTime: fields[6] as DateTime?,
      notes: fields[7] as String? ?? '',
      reminderMinutesBefore: fields[8] as int? ?? 120,
      confirmationNumber: fields[9] as String? ?? '',
      notificationId: fields[10] as int? ?? 0,
    );
  }

  @override
  void write(BinaryWriter writer, ItineraryItem obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.location)
      ..writeByte(5)
      ..write(obj.startDateTime)
      ..writeByte(6)
      ..write(obj.endDateTime)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.reminderMinutesBefore)
      ..writeByte(9)
      ..write(obj.confirmationNumber)
      ..writeByte(10)
      ..write(obj.notificationId);
  }
}
