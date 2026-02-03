# Clarity Mobile App

Flutter mobile application for the Clarity Energy Management Platform. Monitor energy consumption, manage collectors, and control firmware updates from your iOS or Android device.

## Features

### Core Functionality
- **Real-time Dashboard** - Monitor energy consumption across all sites
- **Site Management** - View and manage meters at each location
- **Collector Control** - Monitor device status and connectivity
- **Push Notifications** - Alerts for power events and system issues
- **BLE Commissioning** - Set up new collectors via Bluetooth

### Firmware Updates (OTA)
- **Update Management** - View available firmware versions
- **One-tap Updates** - Trigger updates from device detail screen
- **Auto-update Toggle** - Enable/disable automatic updates per collector
- **Update History** - Track all update attempts and results
- **Restore Points** - View snapshots and trigger rollbacks
- **Progress Tracking** - Real-time update status (downloading, installing, verifying)

## Screenshots

| Dashboard | Device Detail | Update Management |
|-----------|---------------|-------------------|
| ![Dashboard](docs/screenshots/dashboard.png) | ![Device](docs/screenshots/device.png) | ![Updates](docs/screenshots/updates.png) |

## Technology Stack

| Component | Technology |
|-----------|------------|
| Framework | Flutter 3.x |
| State Management | Riverpod |
| Navigation | go_router |
| HTTP Client | Dio |
| Local Storage | SharedPreferences |
| Push Notifications | Firebase Cloud Messaging |

## Project Structure

```
lib/
├── core/
│   ├── network/
│   │   └── api_client.dart       # API client with all endpoints
│   └── theme/
│       └── app_theme.dart        # App theming
├── data/
│   └── models/
│       ├── collector_model.dart  # Collector with OTA fields
│       ├── meter_model.dart
│       └── update_model.dart     # FirmwareRelease, UpdateHistory, RestorePoint
├── presentation/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── device_provider.dart
│   │   └── update_provider.dart  # OTA update state management
│   ├── router/
│   │   └── app_router.dart       # Navigation routes
│   └── screens/
│       ├── home/
│       ├── device_detail/        # Device info + firmware card
│       ├── updates/              # Update management screen
│       └── ...
└── main.dart
```

## Getting Started

### Prerequisites
- Flutter SDK 3.x
- Dart SDK 3.x
- Android Studio / Xcode
- iOS: CocoaPods

### Installation

```bash
# Clone repository
git clone https://github.com/datumiot/clarity-flutter-app.git
cd clarity-flutter-app

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Configuration

### API Endpoint

Update the base URL in `lib/core/network/api_client.dart`:

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.clarity.datumiot.tech/api/v1',
  // ...
));
```

### Firebase Setup

1. Create Firebase project
2. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
3. Place in respective platform directories

## Key Screens

### Home Screen
- Site cards with energy summary
- Quick navigation to meters
- Pull-to-refresh data

### Device Detail Screen
- Collector status (online/offline)
- Connection info (IP, signal strength)
- **Firmware card** with version and "Manage Updates" button
- Associated meters list

### Update Management Screen
Three tabs:
1. **Available Updates** - List of newer firmware versions with install buttons
2. **History** - Past update attempts with status
3. **Restore Points** - Snapshots for rollback

## API Endpoints Used

### OTA Updates
```dart
// Get update status and available versions
GET /collectors/{id}/updates

// Trigger firmware update
POST /collectors/{id}/updates/trigger
  body: { "version": "1.0.1" }

// Toggle auto-update
PATCH /collectors/{id}/updates/auto-update
  body: { "enabled": true }

// Get update history
GET /collectors/{id}/updates/history

// Get restore points
GET /collectors/{id}/restore-points

// Trigger rollback
POST /collectors/{id}/restore-points/{rpid}/rollback

// Delete restore point
DELETE /collectors/{id}/restore-points/{rpid}
```

## State Management

The app uses Riverpod for state management. Key providers:

```dart
// Auth state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Device/collector state
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>(...);

// OTA update state
final updateProvider = StateNotifierProvider<UpdateNotifier, UpdateState>(...);
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

Proprietary - DatumIOT (Pty) Ltd

## Support

- Documentation: https://docs.datumiot.tech
- Issues: https://github.com/datumiot/clarity-flutter-app/issues
- Email: support@datumiot.tech
