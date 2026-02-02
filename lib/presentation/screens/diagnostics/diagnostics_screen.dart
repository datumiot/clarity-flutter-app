import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';

class DiagnosticsScreen extends ConsumerStatefulWidget {
  final int collectorId;

  const DiagnosticsScreen({super.key, required this.collectorId});

  @override
  ConsumerState<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends ConsumerState<DiagnosticsScreen> {
  Map<String, dynamic>? _diagnostics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDiagnostics();
  }

  Future<void> _fetchDiagnostics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final response =
          await api.getCollectorDiagnostics(widget.collectorId);
      setState(() {
        _diagnostics = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostics')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _diagnostics == null
                  ? const Center(child: Text('No diagnostics data'))
                  : RefreshIndicator(
                      onRefresh: _fetchDiagnostics,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _buildSection('Network', Icons.wifi, [
                            _entry('Connection', _diagnostics!['network']?['connection_type']),
                            _entry('Signal', '${_diagnostics!['network']?['signal_strength'] ?? '-'} dBm'),
                            _entry('Latency', '${_diagnostics!['network']?['latency'] ?? '-'} ms'),
                            _entry('IP Address', _diagnostics!['network']?['ip_address']),
                          ]),
                          _buildSection('Storage', Icons.storage, [
                            _entry('Total', '${_diagnostics!['storage']?['total'] ?? '-'} GB'),
                            _entry('Free', '${_diagnostics!['storage']?['free'] ?? '-'} GB'),
                            _entry('Used', '${_diagnostics!['storage']?['used_percent'] ?? '-'}%'),
                          ]),
                          _buildSection('Buffer', Icons.pending_actions, [
                            _entry('Pending Readings', '${_diagnostics!['buffer']?['pending_count'] ?? 0}'),
                            _entry('Oldest', _diagnostics!['buffer']?['oldest_timestamp'] ?? '-'),
                          ]),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _entry(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text('${value ?? '-'}',
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
