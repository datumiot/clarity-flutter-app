import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ble_provider.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _ssidController = TextEditingController();
  final _wifiPasswordController = TextEditingController();
  bool _obscureWifiPassword = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(bleProvider.notifier).startScan());
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _wifiPasswordController.dispose();
    ref.read(bleProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = ref.watch(bleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Device'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          _StepIndicator(currentStep: ble.step),
          // Error banner
          if (ble.error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(ble.error!,
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          // Status message
          if (ble.statusMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(ble.statusMessage!,
                  style: TextStyle(color: Colors.grey[600])),
            ),
          // Step content
          Expanded(child: _buildStepContent(ble)),
        ],
      ),
    );
  }

  Widget _buildStepContent(BleState ble) {
    return switch (ble.step) {
      CommissioningStep.scanning => _buildScanStep(ble),
      CommissioningStep.connecting => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to device...'),
            ],
          ),
        ),
      CommissioningStep.wifiSetup => _buildWifiStep(),
      CommissioningStep.wifiConnecting => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting to WiFi...'),
            ],
          ),
        ),
      CommissioningStep.registration => _buildRegistrationStep(ble),
      CommissioningStep.discovery => _buildDiscoveryStep(ble),
      CommissioningStep.naming || CommissioningStep.complete => _buildCompleteStep(ble),
    };
  }

  Widget _buildScanStep(BleState ble) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Scanning for Clarity devices...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (ble.isLoading) const LinearProgressIndicator(),
        Expanded(
          child: ble.discoveredDevices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bluetooth_searching,
                          size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No devices found',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: ble.discoveredDevices.length,
                  itemBuilder: (context, index) {
                    final device = ble.discoveredDevices[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.bluetooth, color: Colors.blue),
                        title: Text(device.name),
                        subtitle: Text('Signal: ${device.rssi} dBm'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => ref
                            .read(bleProvider.notifier)
                            .connectToDevice(device),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed:
                ble.isLoading ? null : () => ref.read(bleProvider.notifier).startScan(),
            icon: const Icon(Icons.refresh),
            label: const Text('Rescan'),
          ),
        ),
      ],
    );
  }

  Widget _buildWifiStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WiFi Setup',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Enter your WiFi credentials to connect the device.',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 24),
          TextField(
            controller: _ssidController,
            decoration: const InputDecoration(
              labelText: 'WiFi Network (SSID)',
              prefixIcon: Icon(Icons.wifi),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _wifiPasswordController,
            obscureText: _obscureWifiPassword,
            decoration: InputDecoration(
              labelText: 'WiFi Password',
              prefixIcon: const Icon(Icons.lock_outlined),
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureWifiPassword
                    ? Icons.visibility_off
                    : Icons.visibility),
                onPressed: () => setState(
                    () => _obscureWifiPassword = !_obscureWifiPassword),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => ref.read(bleProvider.notifier).configureWifi(
                    _ssidController.text,
                    _wifiPasswordController.text,
                  ),
              child: const Text('Connect WiFi'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationStep(BleState ble) {
    final auth = ref.watch(authProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Register Device',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'WiFi connected. Register this device with your account.',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: ble.isLoading
                  ? null
                  : () => ref.read(bleProvider.notifier).registerDevice(
                        auth.user?.email ?? '',
                        '', // Password handled server-side via token
                      ),
              child: ble.isLoading
                  ? const CircularProgressIndicator(strokeWidth: 2)
                  : const Text('Register Device'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryStep(BleState ble) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Discovering Meters',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          if (ble.discoveredMeters.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            ...ble.discoveredMeters.map((meter) => Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.electrical_services, color: Colors.orange),
                    title: Text(meter),
                  ),
                )),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () =>
                  ref.read(bleProvider.notifier).completeCommissioning(),
              child: const Text('Complete Setup'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep(BleState ble) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text('Device Added!',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('${ble.discoveredMeters.length} meter(s) discovered',
              style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final CommissioningStep currentStep;

  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Scan', 'Connect', 'WiFi', 'Register', 'Done'];
    final currentIndex = switch (currentStep) {
      CommissioningStep.scanning => 0,
      CommissioningStep.connecting => 1,
      CommissioningStep.wifiSetup || CommissioningStep.wifiConnecting => 2,
      CommissioningStep.registration ||
      CommissioningStep.discovery ||
      CommissioningStep.naming =>
        3,
      CommissioningStep.complete => 4,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(steps.length, (i) {
          final isActive = i <= currentIndex;
          return Expanded(
            child: Column(
              children: [
                Container(
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
