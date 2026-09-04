import 'package:hive/hive.dart';
import 'participant.dart';

class Trip extends HiveObject {
  String id;
  String name;
  String destination;
  DateTime startDate;
  DateTime endDate;
  String currency;
  int coverColorValue;
  String coverEmoji;
  List<Participant> participants;
  DateTime createdAt;

  Trip({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.coverColorValue,
    required this.coverEmoji,
    required this.participants,
    required this.createdAt,
  });

  bool get isActive =>
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);

  bool get isUpcoming => DateTime.now().isBefore(startDate);

  bool get isPast => DateTime.now().isAfter(endDate);
}

class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 1;

  @override
  Trip read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Trip(
      id: fields[0] as String,
      name: fields[1] as String,
      destination: fields[2] as String,
      startDate: fields[3] as DateTime,
      endDate: fields[4] as DateTime,
      currency: fields[5] as String,
      coverColorValue: fields[6] as int,
      coverEmoji: fields[7] as String,
      participants: (fields[8] as List).cast<Participant>(),
      createdAt: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.destination)
      ..writeByte(3)
      ..write(obj.startDate)
      ..writeByte(4)
      ..write(obj.endDate)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.coverColorValue)
      ..writeByte(7)
      ..write(obj.coverEmoji)
      ..writeByte(8)
      ..write(obj.participants)
      ..writeByte(9)
      ..write(obj.createdAt);
  }
}
