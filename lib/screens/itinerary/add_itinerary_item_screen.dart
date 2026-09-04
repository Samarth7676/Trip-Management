import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/itinerary_item.dart';
import '../../providers/itinerary_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/icon_helpers.dart';
import '../../utils/id.dart';

class AddItineraryItemScreen extends ConsumerStatefulWidget {
  final String tripId;
  final ItineraryItem? existing;

  const AddItineraryItemScreen({super.key, required this.tripId, this.existing});

  @override
  ConsumerState<AddItineraryItemScreen> createState() => _AddItineraryItemScreenState();
}

class _AddItineraryItemScreenState extends ConsumerState<AddItineraryItemScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late final TextEditingController _confirmationController;

  ItineraryType _type = ItineraryType.flight;
  DateTime _dateTime = DateTime.now().add(const Duration(hours: 2));
  int _reminderMinutes = 120;

  static const _reminderOptions = [30, 60, 120, 180, 360, 720, 1440];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
    _confirmationController = TextEditingController(text: e?.confirmationNumber ?? '');
    if (e != null) {
      _type = e.type;
      _dateTime = e.startDateTime;
      _reminderMinutes = e.reminderMinutesBefore;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (time == null) return;
    setState(() {
      _dateTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final notifier = ref.read(itineraryProvider(widget.tripId).notifier);

    if (widget.existing != null) {
      final e = widget.existing!;
      e.type = _type;
      e.title = title;
      e.location = _locationController.text.trim();
      e.startDateTime = _dateTime;
      e.notes = _notesController.text.trim();
      e.reminderMinutesBefore = _reminderMinutes;
      e.confirmationNumber = _confirmationController.text.trim();
      await notifier.updateItem(e);
    } else {
      final item = ItineraryItem(
        id: newId(),
        tripId: widget.tripId,
        type: _type,
        title: title,
        location: _locationController.text.trim(),
        startDateTime: _dateTime,
        notes: _notesController.text.trim(),
        reminderMinutesBefore: _reminderMinutes,
        confirmationNumber: _confirmationController.text.trim(),
        notificationId: newNotificationId(),
      );
      await notifier.addItem(item);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.existing != null ? 'Edit Item' : 'Add Itinerary Item')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('Type', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ItineraryType.values.map((t) {
                return ChoiceChip(
                  avatar: Icon(iconForItineraryType(t), size: 18),
                  label: Text(labelForItineraryType(t)),
                  selected: _type == t,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Title', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(hintText: 'e.g. Flight to Bali - AA123'),
            ),
            const SizedBox(height: 16),

            Text('Location', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(hintText: 'e.g. JFK Airport, Terminal 4'),
            ),
            const SizedBox(height: 16),

            Text('Date & time', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _pickDateTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(formatDateTime(_dateTime)),
            ),
            const SizedBox(height: 16),

            Text('Remind me before', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reminderOptions.map((mins) {
                return ChoiceChip(
                  label: Text(_reminderLabel(mins)),
                  selected: _reminderMinutes == mins,
                  onSelected: (_) => setState(() => _reminderMinutes = mins),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Text('Confirmation number', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmationController,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
            const SizedBox(height: 16),

            Text('Notes', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
            const SizedBox(height: 28),

            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  String _reminderLabel(int mins) {
    if (mins < 60) return '$mins min';
    if (mins % 1440 == 0) return '${mins ~/ 1440} day${mins ~/ 1440 > 1 ? 's' : ''}';
    return '${mins ~/ 60} hr${mins ~/ 60 > 1 ? 's' : ''}';
  }
}
