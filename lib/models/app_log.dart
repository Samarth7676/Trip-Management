import 'package:hive/hive.dart';

/// Lightweight local activity log, visible to the Super Admin for
/// device-level oversight of app activity.
class AppLog extends HiveObject {
  String id;
  DateTime timestamp;
  String message;
  String profileId;

  AppLog({
    required this.id,
    required this.timestamp,
    required this.message,
    required this.profileId,
  });
}

class AppLogAdapter extends TypeAdapter<AppLog> {
  @override
  final int typeId = 5;

  @override
  AppLog read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return AppLog(
      id: fields[0] as String,
      timestamp: fields[1] as DateTime,
      message: fields[2] as String,
      profileId: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AppLog obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.timestamp)
      ..writeByte(2)
      ..write(obj.message)
      ..writeByte(3)
      ..write(obj.profileId);
  }
}
