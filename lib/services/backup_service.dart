import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/enums.dart';
import '../models/expense.dart';
import '../models/itinerary_item.dart';
import '../models/participant.dart';
import '../models/trip.dart';

/// Local, offline multi-user collaboration mechanism: a trip (with its
/// participants, itinerary and expenses) can be exported to a JSON file and
/// shared through any local channel (AirDrop, Bluetooth, local Wi-Fi file
/// transfer, USB, etc.), then imported on another device to merge/join it -
/// no cloud server involved.
class BackupService {
  static Map<String, dynamic> tripToJson(
    Trip trip,
    List<ItineraryItem> itinerary,
    List<Expense> expenses,
  ) {
    return {
      'formatVersion': 1,
      'trip': {
        'id': trip.id,
        'name': trip.name,
        'destination': trip.destination,
        'startDate': trip.startDate.toIso8601String(),
        'endDate': trip.endDate.toIso8601String(),
        'currency': trip.currency,
        'coverColorValue': trip.coverColorValue,
        'coverEmoji': trip.coverEmoji,
        'createdAt': trip.createdAt.toIso8601String(),
        'participants': trip.participants
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'colorValue': p.colorValue,
                  'isYou': p.isYou,
                })
            .toList(),
      },
      'itinerary': itinerary
          .map((i) => {
                'id': i.id,
                'tripId': i.tripId,
                'type': i.type.name,
                'title': i.title,
                'location': i.location,
                'startDateTime': i.startDateTime.toIso8601String(),
                'endDateTime': i.endDateTime?.toIso8601String(),
                'notes': i.notes,
                'reminderMinutesBefore': i.reminderMinutesBefore,
                'confirmationNumber': i.confirmationNumber,
                'notificationId': i.notificationId,
              })
          .toList(),
      'expenses': expenses
          .map((e) => {
                'id': e.id,
                'tripId': e.tripId,
                'title': e.title,
                'category': e.category.name,
                'amount': e.amount,
                'currency': e.currency,
                'payerId': e.payerId,
                'participantIds': e.participantIds,
                'splitType': e.splitType.name,
                'splitValues': e.splitValues,
                'date': e.date.toIso8601String(),
                'notes': e.notes,
              })
          .toList(),
    };
  }

  static Future<File> exportTripToFile(Map<String, dynamic> json, String tripName) async {
    final dir = await getTemporaryDirectory();
    final safeName = tripName.replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_');
    final file = File('${dir.path}/${safeName}_export.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    return file;
  }

  static Future<void> shareTripFile(File file, String tripName) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Trip export: $tripName',
      text: 'Import this file in Trip Management to join the trip offline.',
    );
  }

  static Future<Map<String, dynamic>?> pickAndParseImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return null;
    final file = File(result.files.single.path!);
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  static ({Trip trip, List<ItineraryItem> itinerary, List<Expense> expenses})
      parseImportedTrip(Map<String, dynamic> json) {
    final t = json['trip'] as Map<String, dynamic>;
    final trip = Trip(
      id: t['id'] as String,
      name: t['name'] as String,
      destination: t['destination'] as String,
      startDate: DateTime.parse(t['startDate'] as String),
      endDate: DateTime.parse(t['endDate'] as String),
      currency: t['currency'] as String,
      coverColorValue: t['coverColorValue'] as int,
      coverEmoji: t['coverEmoji'] as String,
      createdAt: DateTime.parse(t['createdAt'] as String),
      participants: (t['participants'] as List)
          .map((p) => Participant(
                id: p['id'] as String,
                name: p['name'] as String,
                colorValue: p['colorValue'] as int,
                isYou: p['isYou'] as bool? ?? false,
              ))
          .toList(),
    );

    final itinerary = (json['itinerary'] as List)
        .map((i) => ItineraryItem(
              id: i['id'] as String,
              tripId: i['tripId'] as String,
              type: ItineraryType.values.byName(i['type'] as String),
              title: i['title'] as String,
              location: i['location'] as String,
              startDateTime: DateTime.parse(i['startDateTime'] as String),
              endDateTime: i['endDateTime'] != null
                  ? DateTime.parse(i['endDateTime'] as String)
                  : null,
              notes: i['notes'] as String? ?? '',
              reminderMinutesBefore: i['reminderMinutesBefore'] as int? ?? 120,
              confirmationNumber: i['confirmationNumber'] as String? ?? '',
              notificationId: i['notificationId'] as int? ??
                  DateTime.now().millisecondsSinceEpoch.remainder(100000),
            ))
        .toList();

    final expenses = (json['expenses'] as List)
        .map((e) => Expense(
              id: e['id'] as String,
              tripId: e['tripId'] as String,
              title: e['title'] as String,
              category: ExpenseCategory.values.byName(e['category'] as String),
              amount: (e['amount'] as num).toDouble(),
              currency: e['currency'] as String,
              payerId: e['payerId'] as String,
              participantIds: (e['participantIds'] as List).cast<String>(),
              splitType: SplitType.values.byName(e['splitType'] as String),
              splitValues: (e['splitValues'] as Map)
                  .map((k, v) => MapEntry(k as String, (v as num).toDouble())),
              date: DateTime.parse(e['date'] as String),
              notes: e['notes'] as String? ?? '',
            ))
        .toList();

    return (trip: trip, itinerary: itinerary, expenses: expenses);
  }
}
