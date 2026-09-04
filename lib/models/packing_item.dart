import 'package:hive/hive.dart';
import 'enums.dart';

class PackingItem extends HiveObject {
  String id;
  String tripId;
  String title;
  PackingCategory category;
  bool isPacked;

  PackingItem({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    this.isPacked = false,
  });
}

class PackingItemAdapter extends TypeAdapter<PackingItem> {
  @override
  final int typeId = 6;

  @override
  PackingItem read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return PackingItem(
      id: fields[0] as String,
      tripId: fields[1] as String,
      title: fields[2] as String,
      category: fields[3] as PackingCategory,
      isPacked: fields[4] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, PackingItem obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.isPacked);
  }
}
