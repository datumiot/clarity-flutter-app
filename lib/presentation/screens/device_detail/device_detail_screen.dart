import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/device_provider.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final int collectorId;

  const DeviceDetailScreen({super.key, required this.collectorId});

  @override
  ConsumerState<DeviceDetailScreen> createState() =>
      _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(deviceProvider.notifier).fetchCollector(widget.collectorId);
      ref.read(deviceProvider.notifier).fetchMeters(widget.collectorId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceProvider);
    final device = state.selectedCollector;

    return Scaffold(
      appBar: AppBar(
        title: Text(device?.name ?? 'Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.monitor_heart),
            tooltip: 'Diagnostics',
            onPressed: () =>
                context.push('/diagnostics/${widget.collectorId}'),
          ),
        ],
      ),
      body: state.isLoading && device == null
          ? const Center(child: CircularProgressIndicator())
          : device == null
              ? const Center(child: Text('Device not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Status card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: device.isOnline
                                      ? Colors.green
                                      : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  device.isOnline ? 'Online' : 'Offline',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: device.isOnline
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            _InfoRow('Serial', device.serial),
                            if (device.firmwareVersion != null)
                              _InfoRow('Firmware', device.firmwareVersion!),
                            if (device.connectionType != null)
                              _InfoRow('Connection', device.connectionType!),
                            if (device.ipAddress != null)
                              _InfoRow('IP Address', device.ipAddress!),
                            if (device.lastSeen != null)
                              _InfoRow(
                                'Last Seen',
                                DateFormat('MMM d, yyyy HH:mm')
                                    .format(device.lastSeen!),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Firmware card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Firmware',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                TextButton.icon(
                                  icon: const Icon(Icons.system_update, size: 18),
                                  label: const Text('Manage'),
                                  onPressed: () => context.push(
                                      '/device/${widget.collectorId}/updates'),
                                ),
                              ],
                            ),
                            _InfoRow('Version',
                                device.firmwareVersion ?? 'Unknown'),
                            _InfoRow('Auto Update',
                                device.autoUpdateEnabled ? 'ON' : 'OFF'),
                            if (device.updateStatus != null)
                              _InfoRow('Status', device.updateStatus!),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Meters
                    Text('Meters',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    if (state.meters.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Text('No meters connected',
                                style: TextStyle(color: Colors.grey[600])),
                          ),
                        ),
                      )
                    else
                      ...state.meters.map((meter) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.electrical_services,
                                  color: Colors.orange),
                              title: Text(meter.name),
                              subtitle: Text(
                                  '${meter.type} - Address ${meter.modbusAddress}'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push('/meter/${meter.id}'),
                            ),
                          )),
                  ],
                ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
