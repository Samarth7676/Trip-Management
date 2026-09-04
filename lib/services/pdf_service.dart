import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/expense.dart';
import '../models/itinerary_item.dart';
import '../models/packing_item.dart';
import '../models/trip.dart';
import '../utils/icon_helpers.dart';
import 'settlement_service.dart';

class PdfService {
  static Future<void> exportAndShareTripSummary({
    required Trip trip,
    required List<Expense> expenses,
    required List<ItineraryItem> itinerary,
    List<PackingItem> packing = const [],
  }) async {
    final bytes = await buildTripSummary(
      trip: trip,
      expenses: expenses,
      itinerary: itinerary,
      packing: packing,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: '${_sanitize(trip.name)}_trip_summary.pdf',
    );
  }

  static Future<void> printTripSummary({
    required Trip trip,
    required List<Expense> expenses,
    required List<ItineraryItem> itinerary,
    List<PackingItem> packing = const [],
  }) async {
    final bytes = await buildTripSummary(
      trip: trip,
      expenses: expenses,
      itinerary: itinerary,
      packing: packing,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  static Future<Uint8List> buildTripSummary({
    required Trip trip,
    required List<Expense> expenses,
    required List<ItineraryItem> itinerary,
    List<PackingItem> packing = const [],
  }) async {
    final doc = pw.Document();
    final participantsById = {for (final p in trip.participants) p.id: p};
    final participantIds = trip.participants.map((p) => p.id).toList();

    final total = SettlementService.totalSpend(expenses);
    final balances = SettlementService.computeNetBalances(expenses, participantIds);
    final settlements = SettlementService.simplifyDebts(balances);
    final byCategory = SettlementService.categoryBreakdown(expenses);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, text: trip.name),
          pw.Text('${trip.destination}  |  ${dateFmt(trip.startDate)} - ${dateFmt(trip.endDate)}'),
          pw.SizedBox(height: 16),

          pw.Header(level: 1, text: 'Summary'),
          pw.Bullet(text: 'Total spend: ${trip.currency} ${total.toStringAsFixed(2)}'),
          pw.Bullet(text: 'Participants: ${trip.participants.map((p) => p.name).join(', ')}'),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Category Breakdown'),
          pw.TableHelper.fromTextArray(
            headers: ['Category', 'Amount'],
            data: byCategory.entries
                .map((e) => [e.key, '${trip.currency} ${e.value.toStringAsFixed(2)}'])
                .toList(),
          ),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Individual Balances'),
          pw.TableHelper.fromTextArray(
            headers: ['Participant', 'Net Balance'],
            data: balances.entries.map((e) {
              final name = participantsById[e.key]?.name ?? e.key;
              final sign = e.value >= 0 ? 'is owed' : 'owes';
              return [name, '$sign ${trip.currency} ${e.value.abs().toStringAsFixed(2)}'];
            }).toList(),
          ),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Settle Up (Who Pays Whom)'),
          if (settlements.isEmpty)
            pw.Text('All balances are settled.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['From', 'To', 'Amount'],
              data: settlements.map((s) {
                final from = participantsById[s.fromId]?.name ?? s.fromId;
                final to = participantsById[s.toId]?.name ?? s.toId;
                return [from, to, '${trip.currency} ${s.amount.toStringAsFixed(2)}'];
              }).toList(),
            ),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Expense Log'),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Title', 'Category', 'Payer', 'Amount'],
            data: (expenses..sort((a, b) => a.date.compareTo(b.date)))
                .map((e) => [
                      dateFmt(e.date),
                      e.title,
                      e.category.name,
                      participantsById[e.payerId]?.name ?? e.payerId,
                      '${e.currency} ${e.amount.toStringAsFixed(2)}',
                    ])
                .toList(),
          ),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Itinerary'),
          if (itinerary.isEmpty)
            pw.Text('No itinerary items logged.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Type', 'Title', 'Location', 'Confirmation #'],
              data: (itinerary..sort((a, b) => a.startDateTime.compareTo(b.startDateTime)))
                  .map((i) => [
                        '${dateFmt(i.startDateTime)} ${i.startDateTime.hour.toString().padLeft(2, '0')}:${i.startDateTime.minute.toString().padLeft(2, '0')}',
                        i.type.name,
                        i.title,
                        i.location,
                        i.confirmationNumber,
                      ])
                  .toList(),
            ),
          pw.SizedBox(height: 12),

          pw.Header(level: 1, text: 'Packing Checklist'),
          if (packing.isEmpty)
            pw.Text('No packing items logged.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Item', 'Category', 'Packed'],
              data: packing
                  .map((p) => [p.title, labelForPackingCategory(p.category), p.isPacked ? 'Yes' : 'No'])
                  .toList(),
            ),
        ],
      ),
    );

    return doc.save();
  }

  static String _sanitize(String input) =>
      input.replaceAll(RegExp(r'[^A-Za-z0-9_\-]+'), '_');

  static String dateFmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}


