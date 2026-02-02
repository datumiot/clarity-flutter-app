import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../core/constants/ble_constants.dart';

class BleDevice {
  final BluetoothDevice device;
  final String name;
  final int rssi;

  const BleDevice({
    required this.device,
    required this.name,
    required this.rssi,
  });

  String get serial => name.replaceFirst(BleConstants.deviceNamePrefix, '');
}

class BleDatasource {
  BluetoothDevice? _connectedDevice;
  BluetoothService? _clarityService;
  StreamSubscription? _statusSubscription;
  StreamSubscription? _meterSubscription;

  BluetoothDevice? get connectedDevice => _connectedDevice;

  /// Scan for Clarity devices
  Stream<BleDevice> scanForDevices() async* {
    await FlutterBluePlus.startScan(
      timeout: BleConstants.scanDuration,
      withServices: [BleConstants.serviceUuid],
    );

    await for (final results in FlutterBluePlus.scanResults) {
      for (final result in results) {
        final name = result.device.platformName;
        if (name.startsWith(BleConstants.deviceNamePrefix)) {
          yield BleDevice(
            device: result.device,
            name: name,
            rssi: result.rssi,
          );
        }
      }
    }
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a device
  Future<void> connect(BluetoothDevice device) async {
    await device.connect(timeout: BleConstants.connectionTimeout);
    final services = await device.discoverServices();
    _clarityService = services.firstWhere(
      (s) => s.serviceUuid == BleConstants.serviceUuid,
      orElse: () => throw Exception('Clarity service not found'),
    );
    _connectedDevice = device;
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    _statusSubscription?.cancel();
    _meterSubscription?.cancel();
    await _connectedDevice?.disconnect();
    _connectedDevice = null;
    _clarityService = null;
  }

  BluetoothCharacteristic _getCharacteristic(Guid uuid) {
    if (_clarityService == null) throw Exception('Not connected');
    return _clarityService!.characteristics.firstWhere(
      (c) => c.characteristicUuid == uuid,
      orElse: () => throw Exception('Characteristic $uuid not found'),
    );
  }

  /// Read device serial
  Future<String> readDeviceSerial() async {
    final char = _getCharacteristic(BleConstants.deviceSerialUuid);
    final value = await char.read();
    return utf8.decode(value);
  }

  /// Read device status
  Future<int> readDeviceStatus() async {
    final char = _getCharacteristic(BleConstants.deviceStatusUuid);
    final value = await char.read();
    return value.isNotEmpty ? value[0] : BleConstants.statusIdle;
  }

  /// Subscribe to status changes
  Stream<int> subscribeToStatus() async* {
    final char = _getCharacteristic(BleConstants.deviceStatusUuid);
    await char.setNotifyValue(true);
    await for (final value in char.onValueReceived) {
      if (value.isNotEmpty) {
        yield value[0];
      }
    }
  }

  /// Subscribe to meter list updates
  Stream<String> subscribeToMeterList() async* {
    final char = _getCharacteristic(BleConstants.meterListUuid);
    await char.setNotifyValue(true);
    await for (final value in char.onValueReceived) {
      yield utf8.decode(value);
    }
  }

  /// Write WiFi SSID
  Future<void> writeWifiSsid(String ssid) async {
    final char = _getCharacteristic(BleConstants.wifiSsidUuid);
    await char.write(utf8.encode(ssid));
  }

  /// Write WiFi password
  Future<void> writeWifiPassword(String password) async {
    final char = _getCharacteristic(BleConstants.wifiPasswordUuid);
    await char.write(utf8.encode(password));
  }

  /// Write user email
  Future<void> writeUserEmail(String email) async {
    final char = _getCharacteristic(BleConstants.userEmailUuid);
    await char.write(utf8.encode(email));
  }

  /// Write user password
  Future<void> writeUserPassword(String password) async {
    final char = _getCharacteristic(BleConstants.userPasswordUuid);
    await char.write(utf8.encode(password));
  }

  /// Send command
  Future<void> sendCommand(int command) async {
    final char = _getCharacteristic(BleConstants.commandUuid);
    await char.write([command]);
  }

  /// Configure WiFi (write credentials + send command)
  Future<void> configureWifi(String ssid, String password) async {
    await writeWifiSsid(ssid);
    await writeWifiPassword(password);
    await sendCommand(BleConstants.cmdConnectWifi);
  }

  /// Register device (write user credentials + send command)
  Future<void> registerDevice(String email, String password) async {
    await writeUserEmail(email);
    await writeUserPassword(password);
    await sendCommand(BleConstants.cmdRegisterDevice);
  }

  /// Discover meters
  Future<void> discoverMeters() async {
    await sendCommand(BleConstants.cmdDiscoverMeters);
  }

  /// Complete commissioning
  Future<void> completeCommissioning() async {
    await sendCommand(BleConstants.cmdCompleteCommissioning);
  }
}
