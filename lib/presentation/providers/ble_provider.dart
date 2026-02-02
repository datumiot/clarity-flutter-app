import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/ble_constants.dart';
import '../../data/datasources/ble/ble_datasource.dart';

enum CommissioningStep {
  scanning,
  connecting,
  wifiSetup,
  wifiConnecting,
  registration,
  discovery,
  naming,
  complete,
}

class BleState {
  final CommissioningStep step;
  final List<BleDevice> discoveredDevices;
  final BleDevice? selectedDevice;
  final int? deviceStatus;
  final String? statusMessage;
  final List<String> discoveredMeters;
  final bool isLoading;
  final String? error;

  const BleState({
    this.step = CommissioningStep.scanning,
    this.discoveredDevices = const [],
    this.selectedDevice,
    this.deviceStatus,
    this.statusMessage,
    this.discoveredMeters = const [],
    this.isLoading = false,
    this.error,
  });

  BleState copyWith({
    CommissioningStep? step,
    List<BleDevice>? discoveredDevices,
    BleDevice? selectedDevice,
    int? deviceStatus,
    String? statusMessage,
    List<String>? discoveredMeters,
    bool? isLoading,
    String? error,
  }) =>
      BleState(
        step: step ?? this.step,
        discoveredDevices: discoveredDevices ?? this.discoveredDevices,
        selectedDevice: selectedDevice ?? this.selectedDevice,
        deviceStatus: deviceStatus ?? this.deviceStatus,
        statusMessage: statusMessage ?? this.statusMessage,
        discoveredMeters: discoveredMeters ?? this.discoveredMeters,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class BleNotifier extends StateNotifier<BleState> {
  final BleDatasource _ble;
  StreamSubscription? _scanSub;
  StreamSubscription? _statusSub;
  StreamSubscription? _meterSub;

  BleNotifier(this._ble) : super(const BleState());

  Future<void> startScan() async {
    state = state.copyWith(
      discoveredDevices: [],
      isLoading: true,
      error: null,
    );

    try {
      _scanSub?.cancel();
      final devices = <String, BleDevice>{};
      _scanSub = _ble.scanForDevices().listen(
        (device) {
          devices[device.device.remoteId.str] = device;
          state = state.copyWith(
            discoveredDevices: devices.values.toList(),
          );
        },
        onDone: () => state = state.copyWith(isLoading: false),
        onError: (e) => state = state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> stopScan() async {
    _scanSub?.cancel();
    await _ble.stopScan();
    state = state.copyWith(isLoading: false);
  }

  Future<void> connectToDevice(BleDevice device) async {
    state = state.copyWith(
      selectedDevice: device,
      step: CommissioningStep.connecting,
      isLoading: true,
      error: null,
    );

    try {
      await _ble.connect(device.device);

      // Subscribe to status updates
      _statusSub?.cancel();
      _statusSub = _ble.subscribeToStatus().listen((status) {
        state = state.copyWith(
          deviceStatus: status,
          statusMessage: BleConstants.statusMessage(status),
        );

        // Auto-advance on WiFi connected
        if (status == BleConstants.statusWifiConnected &&
            state.step == CommissioningStep.wifiConnecting) {
          state = state.copyWith(step: CommissioningStep.registration);
        }

        // Auto-advance on ready
        if (status == BleConstants.statusReady) {
          state = state.copyWith(step: CommissioningStep.complete);
        }
      });

      // Subscribe to meter list
      _meterSub?.cancel();
      _meterSub = _ble.subscribeToMeterList().listen((meterData) {
        final meters = meterData.split(',').where((m) => m.isNotEmpty).toList();
        state = state.copyWith(discoveredMeters: meters);
      });

      state = state.copyWith(
        step: CommissioningStep.wifiSetup,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to connect: ${e.toString()}',
        step: CommissioningStep.scanning,
      );
    }
  }

  Future<void> configureWifi(String ssid, String password) async {
    state = state.copyWith(
      step: CommissioningStep.wifiConnecting,
      isLoading: true,
      error: null,
      statusMessage: 'Sending WiFi credentials...',
    );

    try {
      await _ble.configureWifi(ssid, password);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'WiFi setup failed: ${e.toString()}',
        step: CommissioningStep.wifiSetup,
      );
    }
  }

  Future<void> registerDevice(String email, String password) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      statusMessage: 'Registering device...',
    );

    try {
      await _ble.registerDevice(email, password);
      await _ble.discoverMeters();
      state = state.copyWith(
        step: CommissioningStep.discovery,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
    }
  }

  Future<void> completeCommissioning() async {
    try {
      await _ble.completeCommissioning();
      state = state.copyWith(step: CommissioningStep.complete);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> reset() async {
    _scanSub?.cancel();
    _statusSub?.cancel();
    _meterSub?.cancel();
    await _ble.disconnect();
    state = const BleState();
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _statusSub?.cancel();
    _meterSub?.cancel();
    _ble.disconnect();
    super.dispose();
  }
}

final bleDatasourceProvider = Provider<BleDatasource>((ref) => BleDatasource());

final bleProvider = StateNotifierProvider<BleNotifier, BleState>((ref) {
  final ble = ref.watch(bleDatasourceProvider);
  return BleNotifier(ble);
});
