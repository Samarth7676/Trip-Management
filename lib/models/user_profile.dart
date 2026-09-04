import 'package:hive/hive.dart';

class UserProfile extends HiveObject {
  String id;
  String name;
  String avatarEmoji;
  String defaultCurrency;
  String? pinHash;
  bool biometricEnabled;
  bool isSuperAdmin;
  DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.defaultCurrency,
    this.pinHash,
    this.biometricEnabled = false,
    this.isSuperAdmin = false,
    required this.createdAt,
  });

  bool get hasSecurityLock => pinHash != null || biometricEnabled;
}

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      avatarEmoji: fields[2] as String,
      defaultCurrency: fields[3] as String,
      pinHash: fields[4] as String?,
      biometricEnabled: fields[5] as bool? ?? false,
      isSuperAdmin: fields[6] as bool? ?? false,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.avatarEmoji)
      ..writeByte(3)
      ..write(obj.defaultCurrency)
      ..writeByte(4)
      ..write(obj.pinHash)
      ..writeByte(5)
      ..write(obj.biometricEnabled)
      ..writeByte(6)
      ..write(obj.isSuperAdmin)
      ..writeByte(7)
      ..write(obj.createdAt);
  }
}
