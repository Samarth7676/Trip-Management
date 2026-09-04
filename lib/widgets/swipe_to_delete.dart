import 'package:flutter/material.dart';

/// Wraps [child] in a swipe-to-delete Dismissible with a consistent red
/// gradient reveal and a confirmation dialog.
class SwipeToDelete extends StatelessWidget {
  final Object keyValue;
  final Widget child;
  final Future<void> Function() onDelete;
  final String confirmTitle;
  final String confirmMessage;

  const SwipeToDelete({
    super.key,
    required this.keyValue,
    required this.child,
    required this.onDelete,
    this.confirmTitle = 'Delete this item?',
    this.confirmMessage = 'This can\'t be undone.',
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(keyValue),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
          ),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(confirmTitle),
                content: Text(confirmMessage),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: child,
    );
  }
}
