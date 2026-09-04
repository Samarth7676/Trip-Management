import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/participant.dart';
import '../../providers/trip_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/id.dart';
import '../../utils/palette.dart';

class EditTripScreen extends ConsumerStatefulWidget {
  final String tripId;

  const EditTripScreen({super.key, required this.tripId});

  @override
  ConsumerState<EditTripScreen> createState() => _EditTripScreenState();
}

class _EditTripScreenState extends ConsumerState<EditTripScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _destinationController;
  final _participantController = TextEditingController();
  late DateTime _startDate;
  late DateTime _endDate;
  late String _currency;

  @override
  void initState() {
    super.initState();
    final trip = ref.read(tripByIdProvider(widget.tripId))!;
    _nameController = TextEditingController(text: trip.name);
    _destinationController = TextEditingController(text: trip.destination);
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    _currency = trip.currency;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (range != null) {
      setState(() {
        _startDate = range.start;
        _endDate = range.end;
      });
    }
  }

  void _addParticipant() {
    final name = _participantController.text.trim();
    if (name.isEmpty) return;
    final trip = ref.read(tripByIdProvider(widget.tripId))!;
    setState(() {
      trip.participants.add(
        Participant(id: newId(), name: name, colorValue: paletteColorFor(trip.participants.length).toARGB32()),
      );
      _participantController.clear();
    });
  }

  Future<void> _save() async {
    final trip = ref.read(tripByIdProvider(widget.tripId))!;
    trip.name = _nameController.text.trim();
    trip.destination = _destinationController.text.trim();
    trip.startDate = _startDate;
    trip.endDate = _endDate;
    trip.currency = _currency;
    await ref.read(tripsProvider.notifier).updateTrip(trip);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(tripByIdProvider(widget.tripId));
    if (trip == null) return const Scaffold(body: SizedBox.shrink());

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Trip')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Trip name', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(controller: _nameController),
            const SizedBox(height: 16),

            Text('Destination', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(controller: _destinationController),
            const SizedBox(height: 16),

            Text('Dates', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range_rounded),
              label: Text(formatDateRange(_startDate, _endDate)),
            ),
            const SizedBox(height: 16),

            Text('Currency', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kCurrencies.map((c) {
                return ChoiceChip(
                  label: Text(c),
                  selected: _currency == c,
                  onSelected: (_) => setState(() => _currency = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Participants', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: trip.participants.map((p) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(p.colorValue),
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  label: Text(p.isYou ? '${p.name} (You)' : p.name),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _participantController,
                    decoration: const InputDecoration(hintText: 'Add participant name'),
                    onSubmitted: (_) => _addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addParticipant, icon: const Icon(Icons.add_rounded)),
              ],
            ),
            const SizedBox(height: 28),

            FilledButton(onPressed: _save, child: const Text('Save changes')),
          ],
        ),
      ),
    );
  }
}
