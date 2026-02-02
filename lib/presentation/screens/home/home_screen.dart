import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/device_provider.dart';
import '../../../data/models/collector_model.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(deviceProvider.notifier).fetchCollectors());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final devices = ref.watch(deviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${auth.user?.firstName ?? 'User'}'),
        actions: [
          if (devices.collectors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${devices.collectors.length} device${devices.collectors.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(deviceProvider.notifier).fetchCollectors(),
        child: devices.isLoading && devices.collectors.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : devices.collectors.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: devices.collectors.length,
                    itemBuilder: (context, index) =>
                        _buildDeviceCard(context, devices.collectors[index]),
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/add-device'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices_other, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No devices yet',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Add your first Clarity Logger',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.push('/add-device'),
            icon: const Icon(Icons.add),
            label: const Text('Add Device'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(BuildContext context, Collector device) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/device/${device.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _StatusBadge(status: device.status),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                device.serial,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (device.connectionType != null || device.lastSeen != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (device.connectionType != null) ...[
                      Icon(Icons.wifi, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(device.connectionType!,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(width: 16),
                    ],
                    if (device.lastSeen != null) ...[
                      Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM d, HH:mm').format(device.lastSeen!),
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'online' => Colors.green,
      'offline' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status[0].toUpperCase() + status.substring(1),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
