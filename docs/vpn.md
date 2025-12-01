# VPN Detection

This document explains how VPN detection works in WatchTheFlix.

## Overview

The VPN module (`lib/modules/vpn/`) provides VPN detection and status UI components. This helps users understand when VPN may affect their streaming experience.

## Module Structure

```
vpn/
├── detection/
│   └── vpn_detector.dart           # VPN detection logic
└── providers/
    └── vpn_provider_interface.dart # Provider interfaces
```

## VPN Status

The detector reports one of three statuses:

```dart
enum VpnStatus {
  active,   // VPN is detected as active
  inactive, // VPN is not detected  
  unknown,  // Status could not be determined
}
```

## Detection Logic

The `VpnDetector` attempts to detect VPN through:

1. **Network interface names/types** (platform-specific)
2. **Known VPN IP ranges/ASNs** (if external service available)
3. **DNS/gateway anomalies** (where feasible)

### Platform Support

| Platform | Detection Supported |
|----------|---------------------|
| Android | Yes (via network interfaces) |
| iOS | Partial (limited API access) |
| Windows | Yes (via network adapters) |
| macOS | Partial |
| Linux | Yes (via network interfaces) |
| Web | No (browser restrictions) |

## Usage

### Basic Detection

```dart
final detector = VpnDetector();

// Check if detection is supported
if (detector.isSupported) {
  final result = await detector.detect();
  
  print('Status: ${result.status}');
  print('Method: ${result.detectionMethod}');
  print('Checked at: ${result.checkedAt}');
  
  if (result.isActive) {
    print('VPN is active');
  }
}
```

### With Repository

Implement `VpnDetectionRepository` for platform-specific detection:

```dart
class AndroidVpnDetectionRepository implements VpnDetectionRepository {
  @override
  Future<VpnDetectionResult> detectVpn() async {
    // Platform-specific implementation
    // Check network interfaces for VPN adapters
  }
}

final detector = VpnDetector(repository: AndroidVpnDetectionRepository());
final result = await detector.detect();
```

## VPN Detection Result

```dart
class VpnDetectionResult {
  final VpnStatus status;
  final String? detectionMethod;
  final String? message;
  final DateTime checkedAt;
  
  bool get isActive => status == VpnStatus.active;
  bool get isInactive => status == VpnStatus.inactive;
  bool get isUnknown => status == VpnStatus.unknown;
}
```

## User Preferences

Users can override auto-detection with a preference:

```dart
enum VpnPreference {
  auto,  // Use detection result
  on,    // User declares VPN is on
  off,   // User declares VPN is off
}
```

Store preference using the storage service:

```dart
// Save preference
await storage.setString(StorageKeys.vpnPreference, preference.name);

// Load preference
final prefStr = await storage.getString(StorageKeys.vpnPreference);
final preference = VpnPreference.values.byName(prefStr ?? 'auto');
```

## UI Components

### VpnStatusTile

Settings tile showing VPN status and preference controls:

```dart
VpnStatusTile(
  detectionResult: result,
  preference: currentPreference,
  onPreferenceChanged: (newPref) {
    // Save preference
  },
  onRefresh: () async {
    // Re-check VPN status
  },
  isChecking: isLoading,
)
```

### VpnIndicatorBadge

Small badge for playback/account screens:

```dart
VpnIndicatorBadge(
  status: effectiveStatus,
  compact: true,  // Just icon, or icon + "VPN" text
)
```

## Provider Integration

The `IVpnProvider` interface supports actual VPN control (if available):

```dart
abstract class IVpnProvider {
  Future<bool> isConnected();
  Future<bool> connect();
  Future<bool> disconnect();
  Future<VpnProviderStatus> getStatus();
  bool get isAvailable;
  String get providerName;
}
```

**Note**: Most platforms don't allow programmatic VPN control. The system VPN provider can only detect status, not control connections.

## Configuration

Enable/disable VPN detection in `AppConfig`:

```dart
AppConfig().vpnDetectionEnabled = true;  // Enable detection
AppConfig().vpnDetectionEnabled = false; // Disable (always returns unknown)
```

## Graceful Degradation

If detection is not possible:

1. Return `VpnStatus.unknown`
2. Show appropriate messaging to user
3. Allow user to manually set preference
4. Don't block any functionality

## Best Practices

1. **Don't block on VPN**: Some users require VPN for privacy/security
2. **Inform, don't restrict**: Show warnings but allow playback
3. **Respect preferences**: If user says "off", trust them
4. **Handle failures gracefully**: Detection may fail; that's OK
5. **Re-check periodically**: VPN status can change

## Example Integration

```dart
class PlaybackScreen extends StatefulWidget {
  @override
  _PlaybackScreenState createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen> {
  VpnDetectionResult? _vpnResult;
  
  @override
  void initState() {
    super.initState();
    _checkVpn();
  }
  
  Future<void> _checkVpn() async {
    final detector = VpnDetector();
    final result = await detector.detect();
    setState(() => _vpnResult = result);
  }
  
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Video player
        VideoPlayer(),
        
        // VPN indicator (if active)
        if (_vpnResult?.isActive == true)
          Positioned(
            top: 8,
            right: 8,
            child: VpnIndicatorBadge(
              status: _vpnResult!.status,
              compact: true,
            ),
          ),
      ],
    );
  }
}
```
