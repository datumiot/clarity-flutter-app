import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConstants {
  BleConstants._();

  // Service UUID
  static final Guid serviceUuid =
      Guid('12345678-1234-5678-1234-56789abcdef0');

  // Characteristic UUIDs
  static final Guid wifiSsidUuid =
      Guid('12345678-1234-5678-1234-56789abcdef1');
  static final Guid wifiPasswordUuid =
      Guid('12345678-1234-5678-1234-56789abcdef2');
  static final Guid userEmailUuid =
      Guid('12345678-1234-5678-1234-56789abcdef3');
  static final Guid userPasswordUuid =
      Guid('12345678-1234-5678-1234-56789abcdef4');
  static final Guid deviceStatusUuid =
      Guid('12345678-1234-5678-1234-56789abcdef5');
  static final Guid deviceSerialUuid =
      Guid('12345678-1234-5678-1234-56789abcdef6');
  static final Guid commandUuid =
      Guid('12345678-1234-5678-1234-56789abcdef7');
  static final Guid meterListUuid =
      Guid('12345678-1234-5678-1234-56789abcdef8');

  // Commands
  static const int cmdConnectWifi = 1;
  static const int cmdRegisterDevice = 2;
  static const int cmdDiscoverMeters = 3;
  static const int cmdCompleteCommissioning = 4;
  static const int cmdReset = 255;

  // Status Codes
  static const int statusIdle = 0;
  static const int statusConnectingWifi = 1;
  static const int statusWifiConnected = 2;
  static const int statusWifiFailed = 3;
  static const int statusRegistering = 4;
  static const int statusRegistered = 5;
  static const int statusRegistrationFailed = 6;
  static const int statusDiscoveringMeters = 7;
  static const int statusReady = 8;
  static const int statusError = 255;

  static String statusMessage(int code) {
    switch (code) {
      case statusIdle:
        return 'Idle';
      case statusConnectingWifi:
        return 'Connecting to WiFi...';
      case statusWifiConnected:
        return 'WiFi connected';
      case statusWifiFailed:
        return 'WiFi connection failed';
      case statusRegistering:
        return 'Registering device...';
      case statusRegistered:
        return 'Device registered';
      case statusRegistrationFailed:
        return 'Registration failed';
      case statusDiscoveringMeters:
        return 'Discovering meters...';
      case statusReady:
        return 'Ready';
      case statusError:
        return 'Error';
      default:
        return 'Unknown status ($code)';
    }
  }

  // Scan settings
  static const Duration scanDuration = Duration(seconds: 10);
  static const String deviceNamePrefix = 'Clarity-';
  static const Duration connectionTimeout = Duration(seconds: 30);
}
