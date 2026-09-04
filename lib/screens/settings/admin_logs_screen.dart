import 'package:flutter/material.dart';

import '../../services/hive_service.dart';
import '../../utils/formatters.dart';

class AdminLogsScreen extends StatefulWidget {
  const AdminLogsScreen({super.key});

  @override
  State<AdminLogsScreen> createState() => _AdminLogsScreenState();
}

class _AdminLogsScreenState extends State<AdminLogsScreen> {
  Future<void> _clearLogs() async {
    await HiveService.logBox.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final logs = HiveService.logBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Activity Logs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            tooltip: 'Clear logs',
            onPressed: logs.isEmpty ? null : _clearLogs,
          ),
        ],
      ),
      body: logs.isEmpty
          ? Center(
              child: Text('No activity recorded yet', style: TextStyle(color: scheme.onSurfaceVariant)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Card(
                    child: ListTile(
                      dense: true,
                      leading: const Icon(Icons.circle_notifications_rounded),
                      title: Text(log.message),
                      subtitle: Text(formatDateTime(log.timestamp)),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
