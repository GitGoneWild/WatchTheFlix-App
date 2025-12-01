// VpnProvider
// Interfaces for VPN provider integration.

/// VPN provider interface for controlling VPN connections
abstract class IVpnProvider {
  /// Check if VPN is connected
  Future<bool> isConnected();

  /// Connect to VPN
  Future<bool> connect();

  /// Disconnect from VPN
  Future<bool> disconnect();

  /// Get current VPN status
  Future<VpnProviderStatus> getStatus();

  /// Check if provider is available on this platform
  bool get isAvailable;

  /// Provider name
  String get providerName;
}

/// VPN provider status
class VpnProviderStatus {
  final bool isConnected;
  final String? serverLocation;
  final String? serverAddress;
  final String? protocol;
  final DateTime? connectedSince;

  const VpnProviderStatus({
    required this.isConnected,
    this.serverLocation,
    this.serverAddress,
    this.protocol,
    this.connectedSince,
  });

  Duration? get connectionDuration {
    if (!isConnected || connectedSince == null) return null;
    return DateTime.now().difference(connectedSince!);
  }
}

/// System VPN provider implementation
/// Uses system-level VPN APIs when available
class SystemVpnProvider implements IVpnProvider {
  @override
  String get providerName => 'System VPN';

  @override
  bool get isAvailable => false; // Platform-specific implementation needed

  @override
  Future<bool> isConnected() async {
    // Platform-specific implementation
    return false;
  }

  @override
  Future<bool> connect() async {
    // Cannot programmatically connect to system VPN
    // User must do this manually via system settings
    return false;
  }

  @override
  Future<bool> disconnect() async {
    // Cannot programmatically disconnect system VPN
    // User must do this manually via system settings
    return false;
  }

  @override
  Future<VpnProviderStatus> getStatus() async {
    return const VpnProviderStatus(isConnected: false);
  }
}
