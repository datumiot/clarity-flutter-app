import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/alert_provider.dart';
import '../../../data/models/alert_model.dart';

class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(alertProvider.notifier).fetchAlerts());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(alertProvider.notifier).markAllRead(),
              child: const Text('Mark all read',
                  style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(alertProvider.notifier).fetchAlerts(),
        child: state.isLoading && state.alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.alerts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off,
                            size: 60, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No alerts',
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: state.alerts.length,
                    itemBuilder: (context, index) =>
                        _AlertTile(alert: state.alerts[index]),
                  ),
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  final Alert alert;

  const _AlertTile({required this.alert});

  IconData get _icon => switch (alert.type) {
        'offline' => Icons.cloud_off,
        'reading_error' => Icons.error_outline,
        'low_storage' => Icons.storage,
        'update_available' => Icons.system_update,
        _ => Icons.notifications,
      };

  Color get _color => switch (alert.type) {
        'offline' => Colors.red,
        'reading_error' => Colors.orange,
        'low_storage' => Colors.amber,
        'update_available' => Colors.blue,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      color: alert.isRead ? null : Colors.amber.withValues(alpha: 0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Icon(_icon, color: _color),
        ),
        title: Text(
          alert.message,
          style: TextStyle(
            fontWeight: alert.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${alert.collectorName ?? 'Unknown device'} - ${DateFormat('MMM d, HH:mm').format(alert.createdAt)}',
        ),
        onTap: () {
          if (!alert.isRead) {
            ref.read(alertProvider.notifier).markRead(alert.id);
          }
        },
      ),
    );
  }
}
