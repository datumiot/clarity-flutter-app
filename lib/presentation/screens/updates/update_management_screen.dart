import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/update_provider.dart';
import '../../../data/models/update_model.dart';

class UpdateManagementScreen extends ConsumerStatefulWidget {
  final int collectorId;

  const UpdateManagementScreen({super.key, required this.collectorId});

  @override
  ConsumerState<UpdateManagementScreen> createState() =>
      _UpdateManagementScreenState();
}

class _UpdateManagementScreenState
    extends ConsumerState<UpdateManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    Future.microtask(
        () => ref.read(updateProvider.notifier).loadUpdates(widget.collectorId));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firmware Updates'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Available (${state.availableUpdates.length})'),
            Tab(text: 'History (${state.history.length})'),
            Tab(text: 'Restore (${state.restorePoints.length})'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Status header
                _StatusHeader(
                  currentVersion: state.currentVersion,
                  autoUpdateEnabled: state.autoUpdateEnabled,
                  updateStatus: state.updateStatus,
                  targetVersion: state.targetVersion,
                  onToggleAutoUpdate: (enabled) => ref
                      .read(updateProvider.notifier)
                      .toggleAutoUpdate(widget.collectorId, enabled),
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      color: Colors.red.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.error, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(state.error!,
                                    style:
                                        const TextStyle(color: Colors.red))),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (state.updateInProgress) _UpdateProgressBar(state.updateStatus!),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _AvailableUpdatesTab(
                        updates: state.availableUpdates,
                        isUpdating: state.updateInProgress,
                        onInstall: (version) => ref
                            .read(updateProvider.notifier)
                            .triggerUpdate(widget.collectorId, version),
                      ),
                      _HistoryTab(history: state.history),
                      _RestorePointsTab(
                        restorePoints: state.restorePoints,
                        isUpdating: state.updateInProgress,
                        onRollback: (rpId) => ref
                            .read(updateProvider.notifier)
                            .triggerRollback(widget.collectorId, rpId),
                        onDelete: (rpId) => ref
                            .read(updateProvider.notifier)
                            .deleteRestorePoint(widget.collectorId, rpId),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final String? currentVersion;
  final bool autoUpdateEnabled;
  final String? updateStatus;
  final String? targetVersion;
  final ValueChanged<bool> onToggleAutoUpdate;

  const _StatusHeader({
    this.currentVersion,
    required this.autoUpdateEnabled,
    this.updateStatus,
    this.targetVersion,
    required this.onToggleAutoUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current Version',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              Text('v${currentVersion ?? 'unknown'}',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              const Text('Auto-update'),
              Switch(
                value: autoUpdateEnabled,
                onChanged: onToggleAutoUpdate,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpdateProgressBar extends StatelessWidget {
  final String status;

  const _UpdateProgressBar(this.status);

  static const steps = ['pending', 'downloading', 'installing', 'verifying', 'completed'];

  @override
  Widget build(BuildContext context) {
    final idx = steps.indexOf(status);
    final progress = (idx + 1) / steps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          LinearProgressIndicator(value: progress),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps
                .map((s) => Text(
                      s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight:
                            s == status ? FontWeight.bold : FontWeight.normal,
                        color: s == status
                            ? Theme.of(context).primaryColor
                            : Colors.grey,
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _AvailableUpdatesTab extends StatelessWidget {
  final List<FirmwareRelease> updates;
  final bool isUpdating;
  final ValueChanged<String> onInstall;

  const _AvailableUpdatesTab({
    required this.updates,
    required this.isUpdating,
    required this.onInstall,
  });

  @override
  Widget build(BuildContext context) {
    if (updates.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Firmware is up to date'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: updates.length,
      itemBuilder: (context, index) {
        final release = updates[index];
        return Card(
          child: ListTile(
            leading: Icon(
              release.isCritical ? Icons.priority_high : Icons.system_update,
              color: release.isCritical ? Colors.red : Colors.blue,
            ),
            title: Text('v${release.version}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (release.releaseNotes != null)
                  Text(release.releaseNotes!,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                Text(
                  '${release.formattedSize} - ${release.publishedAt != null ? DateFormat('MMM d, yyyy').format(release.publishedAt!) : 'Unknown date'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: ElevatedButton(
              onPressed:
                  isUpdating ? null : () => onInstall(release.version),
              child: const Text('Install'),
            ),
            isThreeLine: release.releaseNotes != null,
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  final List<UpdateHistory> history;

  const _HistoryTab({required this.history});

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'rolled_back':
        return Colors.red;
      case 'downloading':
      case 'installing':
      case 'verifying':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'failed':
      case 'rolled_back':
        return Icons.error;
      case 'downloading':
        return Icons.cloud_download;
      case 'installing':
        return Icons.build;
      case 'verifying':
        return Icons.verified;
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No update history'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final h = history[index];
        return Card(
          child: ListTile(
            leading: Icon(_statusIcon(h.status), color: _statusColor(h.status)),
            title: Text(
                '${h.fromVersion ?? '?'} -> v${h.toVersion}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${h.initiatedBy} - ${h.startedAt != null ? DateFormat('MMM d, HH:mm').format(h.startedAt!) : '?'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (h.errorMessage != null)
                  Text(h.errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Chip(
              label: Text(h.status, style: const TextStyle(fontSize: 11)),
              backgroundColor: _statusColor(h.status).withValues(alpha: 0.1),
              labelStyle: TextStyle(color: _statusColor(h.status)),
            ),
            isThreeLine: h.errorMessage != null,
          ),
        );
      },
    );
  }
}

class _RestorePointsTab extends StatelessWidget {
  final List<RestorePoint> restorePoints;
  final bool isUpdating;
  final ValueChanged<int> onRollback;
  final ValueChanged<int> onDelete;

  const _RestorePointsTab({
    required this.restorePoints,
    required this.isUpdating,
    required this.onRollback,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (restorePoints.isEmpty) {
      return const Center(child: Text('No restore points'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: restorePoints.length,
      itemBuilder: (context, index) {
        final rp = restorePoints[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.restore, color: Colors.amber),
            title: Text('v${rp.version}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (rp.label != null) Text(rp.label!),
                Text(
                  '${rp.formattedSize} - ${rp.createdAt != null ? DateFormat('MMM d, yyyy HH:mm').format(rp.createdAt!) : '?'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: Colors.orange),
                  tooltip: 'Rollback',
                  onPressed:
                      isUpdating ? null : () => _confirmRollback(context, rp),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed:
                      isUpdating ? null : () => onDelete(rp.restorePointId),
                ),
              ],
            ),
            isThreeLine: rp.label != null,
          ),
        );
      },
    );
  }

  void _confirmRollback(BuildContext context, RestorePoint rp) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rollback'),
        content: Text('Roll back to v${rp.version}? This will restart the collector services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRollback(rp.restorePointId);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Rollback'),
          ),
        ],
      ),
    );
  }
}
