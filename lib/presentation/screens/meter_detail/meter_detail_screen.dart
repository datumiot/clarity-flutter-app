import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/device_provider.dart';

class MeterDetailScreen extends ConsumerStatefulWidget {
  final int meterId;

  const MeterDetailScreen({super.key, required this.meterId});

  @override
  ConsumerState<MeterDetailScreen> createState() => _MeterDetailScreenState();
}

class _MeterDetailScreenState extends ConsumerState<MeterDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(deviceProvider.notifier).fetchMeter(widget.meterId);
      final sixHoursAgo =
          DateTime.now().subtract(const Duration(hours: 6)).toIso8601String();
      ref.read(deviceProvider.notifier).fetchReadings(
            widget.meterId,
            startDate: sixHoursAgo,
            limit: 100,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceProvider);
    final meter = state.selectedMeter;
    final readings = state.readings;
    final latest = readings.isNotEmpty ? readings.last : null;

    return Scaffold(
      appBar: AppBar(title: Text(meter?.name ?? 'Meter')),
      body: state.isLoading && meter == null
          ? const Center(child: CircularProgressIndicator())
          : meter == null
              ? const Center(child: Text('Meter not found'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Meter info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(meter.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge),
                            Text('${meter.type} - Address ${meter.modbusAddress}',
                                style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Current readings
                    if (latest != null) ...[
                      Text('Current Readings',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1.8,
                        children: [
                          _ReadingCard('Voltage',
                              '${latest.voltage?.toStringAsFixed(1) ?? '-'} V',
                              Icons.bolt, Colors.amber),
                          _ReadingCard('Current',
                              '${latest.current?.toStringAsFixed(2) ?? '-'} A',
                              Icons.electric_meter, Colors.blue),
                          _ReadingCard('Power',
                              '${latest.power?.toStringAsFixed(0) ?? '-'} W',
                              Icons.power, Colors.orange),
                          _ReadingCard('Energy',
                              '${latest.energy?.toStringAsFixed(2) ?? '-'} kWh',
                              Icons.battery_charging_full, Colors.green),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Power chart
                    if (readings.length > 1) ...[
                      Text('Power Usage (Last 6 Hours)',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: _PowerChart(readings: readings),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ReadingCard(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _PowerChart extends StatelessWidget {
  final List readings;

  const _PowerChart({required this.readings});

  @override
  Widget build(BuildContext context) {
    final spots = readings.asMap().entries.map((e) {
      final r = e.value;
      return FlSpot(e.key.toDouble(), (r.power ?? 0).toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: const FlTitlesData(
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
