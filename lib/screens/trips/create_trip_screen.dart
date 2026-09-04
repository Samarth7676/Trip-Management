import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/participant.dart';
import '../../models/trip.dart';
import '../../providers/profile_provider.dart';
import '../../providers/trip_provider.dart';
import '../../services/hive_service.dart';
import '../../utils/formatters.dart';
import '../../utils/id.dart';
import '../../utils/palette.dart';
import 'trip_detail_screen.dart';

class CreateTripScreen extends ConsumerStatefulWidget {
  const CreateTripScreen({super.key});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _participantController = TextEditingController();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));
  String _currency = 'USD';
  String _coverEmoji = kCoverEmojis.first;
  int _coverColorIndex = 0;
  late List<Participant> _participants;
  String _liveName = '';
  String _liveDestination = '';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    _currency = profile?.defaultCurrency ?? 'USD';
    _participants = [
      Participant(id: newId(), name: profile?.name ?? 'You', colorValue: paletteColorFor(0).toARGB32(), isYou: true),
    ];
    _nameController.addListener(() => setState(() => _liveName = _nameController.text));
    _destinationController.addListener(() => setState(() => _liveDestination = _destinationController.text));
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
    setState(() {
      _participants.add(
        Participant(
          id: newId(),
          name: name,
          colorValue: paletteColorFor(_participants.length).toARGB32(),
        ),
      );
      _participantController.clear();
    });
  }

  Future<void> _createTrip() async {
    final name = _nameController.text.trim();
    final destination = _destinationController.text.trim();
    if (name.isEmpty || destination.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in trip name and destination')),
      );
      return;
    }

    final trip = Trip(
      id: newId(),
      name: name,
      destination: destination,
      startDate: _startDate,
      endDate: _endDate,
      currency: _currency,
      coverColorValue: paletteColorFor(_coverColorIndex).toARGB32(),
      coverEmoji: _coverEmoji,
      participants: _participants,
      createdAt: DateTime.now(),
    );

    await ref.read(tripsProvider.notifier).addTrip(trip);
    final profile = ref.read(currentProfileProvider);
    if (profile != null) {
      await HiveService.log(profile.id, 'Trip created: ${trip.name} (${trip.destination})');
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => TripDetailScreen(tripId: trip.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coverColor = paletteColorFor(_coverColorIndex);

    return Scaffold(
      appBar: AppBar(title: const Text('New Trip')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Live gradient preview.
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [coverColor, Color.lerp(coverColor, Colors.black, 0.35)!],
                ),
                boxShadow: [
                  BoxShadow(color: coverColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -24,
                    child: Opacity(
                      opacity: 0.2,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(_coverEmoji, key: ValueKey(_coverEmoji), style: const TextStyle(fontSize: 110)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          _liveName.isEmpty ? 'Your trip name' : _liveName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: _liveName.isEmpty ? 0.6 : 1),
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _liveDestination.isEmpty ? 'Destination' : _liveDestination,
                          style: TextStyle(color: Colors.white.withValues(alpha: _liveDestination.isEmpty ? 0.5 : 0.85), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: 20),

            Text('Cover', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(kCoverEmojis.length, (i) {
                final selected = i == _coverColorIndex;
                return GestureDetector(
                  onTap: () => setState(() {
                    _coverColorIndex = i;
                    _coverEmoji = kCoverEmojis[i];
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    width: 52,
                    height: 52,
                    transform: selected
                        ? (Matrix4.identity()..scaleByDouble(1.08, 1.08, 1.08, 1))
                        : Matrix4.identity(),
                    transformAlignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: paletteColorFor(i).withValues(alpha: selected ? 0.32 : 0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: selected ? Border.all(color: paletteColorFor(i), width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(kCoverEmojis[i], style: const TextStyle(fontSize: 22)),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            Text('Trip name', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Bali Getaway'),
            ),
            const SizedBox(height: 16),

            Text('Destination', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _destinationController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Bali, Indonesia'),
            ),
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
            const SizedBox(height: 20),

            Text('Participants', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _participants.map((p) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundColor: Color(p.colorValue),
                    child: Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                  label: Text(p.isYou ? '${p.name} (You)' : p.name),
                  onDeleted: p.isYou
                      ? null
                      : () => setState(() => _participants.remove(p)),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _participantController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(hintText: 'Add participant name'),
                    onSubmitted: (_) => _addParticipant(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(onPressed: _addParticipant, icon: const Icon(Icons.add_rounded)),
              ],
            ),
            const SizedBox(height: 28),

            FilledButton(onPressed: _createTrip, child: const Text('Create Trip')),
          ],
        ),
      ),
    );
  }
}
