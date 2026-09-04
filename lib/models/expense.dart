import 'package:hive/hive.dart';
import 'enums.dart';

class Expense extends HiveObject {
  String id;
  String tripId;
  String title;
  ExpenseCategory category;
  double amount;
  String currency;
  String payerId;
  List<String> participantIds;
  SplitType splitType;
  Map<String, double> splitValues;
  DateTime date;
  String notes;

  Expense({
    required this.id,
    required this.tripId,
    required this.title,
    required this.category,
    required this.amount,
    required this.currency,
    required this.payerId,
    required this.participantIds,
    required this.splitType,
    required this.splitValues,
    required this.date,
    this.notes = '',
  });

  /// Returns the resolved share amount (in trip currency) for each participant.
  Map<String, double> resolveShares() {
    switch (splitType) {
      case SplitType.equal:
        final share = amount / participantIds.length;
        return {for (final id in participantIds) id: share};
      case SplitType.exact:
        return Map.from(splitValues);
      case SplitType.percentage:
        return {
          for (final id in participantIds)
            id: amount * (splitValues[id] ?? 0) / 100,
        };
    }
  }
}

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 4;

  @override
  Expense read(BinaryReader reader) {
    final numFields = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < numFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      tripId: fields[1] as String,
      title: fields[2] as String,
      category: fields[3] as ExpenseCategory,
      amount: fields[4] as double,
      currency: fields[5] as String,
      payerId: fields[6] as String,
      participantIds: (fields[7] as List).cast<String>(),
      splitType: fields[8] as SplitType,
      splitValues: (fields[9] as Map).cast<String, double>(),
      date: fields[10] as DateTime,
      notes: fields[11] as String? ?? '',
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.tripId)
      ..writeByte(2)
      ..write(obj.title)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.payerId)
      ..writeByte(7)
      ..write(obj.participantIds)
      ..writeByte(8)
      ..write(obj.splitType)
      ..writeByte(9)
      ..write(obj.splitValues)
      ..writeByte(10)
      ..write(obj.date)
      ..writeByte(11)
      ..write(obj.notes);
  }
}
