import 'package:hive/hive.dart';

class Participant {
  final String id;
  String name;
  int colorValue;
  bool isYou;

  Participant({
    required this.id,
    required this.name,
    required this.colorValue,
    this.isYou = false,
  });
}

class ParticipantAdapter extends TypeAdapter<Participant> {
  @override
  final int typeId = 2;

  @override
  Participant read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Participant(
      id: fields[0] as String,
      name: fields[1] as String,
      colorValue: fields[2] as int,
      isYou: fields[3] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, Participant obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.colorValue)
      ..writeByte(3)
      ..write(obj.isYou);
  }
}
