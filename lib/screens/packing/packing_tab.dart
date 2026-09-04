import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/packing_item.dart';
import '../../providers/packing_provider.dart';
import '../../utils/icon_helpers.dart';
import '../../utils/id.dart';
import '../../widgets/swipe_to_delete.dart';

const _quickAddSuggestions = <String, PackingCategory>{
  'Passport': PackingCategory.documents,
  'Boarding pass': PackingCategory.documents,
  'Phone charger': PackingCategory.electronics,
  'Power adapter': PackingCategory.electronics,
  'Headphones': PackingCategory.electronics,
  'Toothbrush': PackingCategory.toiletries,
  'Sunscreen': PackingCategory.toiletries,
  'Medications': PackingCategory.health,
  'First aid kit': PackingCategory.health,
  'Swimwear': PackingCategory.clothing,
};

class PackingTab extends ConsumerStatefulWidget {
  final String tripId;

  const PackingTab({super.key, required this.tripId});

  @override
  ConsumerState<PackingTab> createState() => _PackingTabState();
}

class _PackingTabState extends ConsumerState<PackingTab> {
  void _addQuickItem(String title, PackingCategory category) {
    ref.read(packingProvider(widget.tripId).notifier).addItem(
          PackingItem(id: newId(), tripId: widget.tripId, title: title, category: category),
        );
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    var category = PackingCategory.other;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20, right: 20, top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add packing item', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'e.g. Travel pillow'),
                    onSubmitted: (_) => Navigator.pop(ctx),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PackingCategory.values.map((c) {
                      return ChoiceChip(
                        avatar: Icon(iconForPackingCategory(c), size: 16),
                        label: Text(labelForPackingCategory(c)),
                        selected: category == c,
                        onSelected: (_) => setSheetState(() => category = c),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Add'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final title = controller.text.trim();
    if (title.isNotEmpty) {
      _addQuickItem(title, category);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(packingProvider(widget.tripId));
    final scheme = Theme.of(context).colorScheme;
    final packedCount = items.where((i) => i.isPacked).length;
    final progress = items.isEmpty ? 0.0 : packedCount / items.length;

    final byCategory = <PackingCategory, List<PackingItem>>{};
    for (final item in items) {
      byCategory.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: progress),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, _) => CircularProgressIndicator(
                            value: value,
                            strokeWidth: 6,
                            backgroundColor: scheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation(
                              value >= 1.0 ? const Color(0xFF10B981) : scheme.primary,
                            ),
                          ),
                        ),
                        Text('${(progress * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Packing checklist', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 4),
                        Text(
                          items.isEmpty ? 'Nothing added yet' : '$packedCount of ${items.length} packed',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 16),
          Text('Quick add', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAddSuggestions.entries.map((entry) {
              final alreadyAdded = items.any((i) => i.title.toLowerCase() == entry.key.toLowerCase());
              return ActionChip(
                avatar: Icon(
                  alreadyAdded ? Icons.check_rounded : Icons.add_rounded,
                  size: 16,
                ),
                label: Text(entry.key),
                onPressed: alreadyAdded ? null : () => _addQuickItem(entry.key, entry.value),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    const Text('🎒', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 12),
                    Text('Add items above or with the + button', style: TextStyle(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ...byCategory.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Row(
                      children: [
                        Icon(iconForPackingCategory(entry.key), size: 16, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(labelForPackingCategory(entry.key),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  ...entry.value.asMap().entries.map((e) => _PackingRow(
                        item: e.value,
                        tripId: widget.tripId,
                      ).animate().fadeIn(delay: (30 * e.key).ms).slideX(begin: 0.05, end: 0)),
                ],
              );
            }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_packing',
        onPressed: _showAddDialog,
        child: const Icon(Icons.add_rounded),
      ).animate().scale(delay: 150.ms, duration: 250.ms, curve: Curves.easeOutBack),
    );
  }
}

class _PackingRow extends ConsumerWidget {
  final PackingItem item;
  final String tripId;

  const _PackingRow({required this.item, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SwipeToDelete(
        keyValue: item.id,
        confirmTitle: 'Delete "${item.title}"?',
        onDelete: () => ref.read(packingProvider(tripId).notifier).deleteItem(item),
        child: Material(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => ref.read(packingProvider(tripId).notifier).togglePacked(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.isPacked ? const Color(0xFF10B981) : Colors.transparent,
                    border: Border.all(
                      color: item.isPacked ? const Color(0xFF10B981) : scheme.outline,
                      width: 2,
                    ),
                  ),
                  child: item.isPacked
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 15,
                      decoration: item.isPacked ? TextDecoration.lineThrough : TextDecoration.none,
                      color: item.isPacked ? scheme.onSurfaceVariant : scheme.onSurface,
                    ),
                    child: Text(item.title),
                  ),
                ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
