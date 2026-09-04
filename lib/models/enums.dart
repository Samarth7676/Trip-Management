import 'package:hive/hive.dart';

enum ItineraryType { flight, train, bus, hotel, activity, other }

enum ExpenseCategory { food, transport, lodging, activities, shopping, other }

enum SplitType { equal, exact, percentage }

enum PackingCategory { documents, clothing, electronics, toiletries, health, other }

class ItineraryTypeAdapter extends TypeAdapter<ItineraryType> {
  @override
  final int typeId = 10;

  @override
  ItineraryType read(BinaryReader reader) {
    final index = reader.readByte();
    return ItineraryType.values[index];
  }

  @override
  void write(BinaryWriter writer, ItineraryType obj) {
    writer.writeByte(obj.index);
  }
}

class ExpenseCategoryAdapter extends TypeAdapter<ExpenseCategory> {
  @override
  final int typeId = 11;

  @override
  ExpenseCategory read(BinaryReader reader) {
    final index = reader.readByte();
    return ExpenseCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, ExpenseCategory obj) {
    writer.writeByte(obj.index);
  }
}

class SplitTypeAdapter extends TypeAdapter<SplitType> {
  @override
  final int typeId = 12;

  @override
  SplitType read(BinaryReader reader) {
    final index = reader.readByte();
    return SplitType.values[index];
  }

  @override
  void write(BinaryWriter writer, SplitType obj) {
    writer.writeByte(obj.index);
  }
}

class PackingCategoryAdapter extends TypeAdapter<PackingCategory> {
  @override
  final int typeId = 13;

  @override
  PackingCategory read(BinaryReader reader) {
    final index = reader.readByte();
    return PackingCategory.values[index];
  }

  @override
  void write(BinaryWriter writer, PackingCategory obj) {
    writer.writeByte(obj.index);
  }
}
