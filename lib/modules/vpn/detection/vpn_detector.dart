// VpnDetector
// Detects whether the user is using a VPN connection.

import '../../core/logging/app_logger.dart';

/// VPN status enumeration
enum VpnStatus {
  /// VPN is detected as active
  active,

  /// VPN is not detected
  inactive,

  /// VPN status could not be determined
  unknown,
}

/// VPN detection result
class VpnDetectionResult {
  const VpnDetectionResult({
    required this.status,
    this.detectionMethod,
    this.message,
    required this.checkedAt,
  });
  final VpnStatus status;
  final String? detectionMethod;
  final String? message;
  final DateTime checkedAt;

  bool get isActive => status == VpnStatus.active;
  bool get isInactive => status == VpnStatus.inactive;
  bool get isUnknown => status == VpnStatus.unknown;
}

/// VPN detector interface
abstract class IVpnDetector {
  /// Check if VPN is currently active
  Future<VpnDetectionResult> detect();

  /// Check if detection is supported on this platform
  bool get isSupported;
}

/// Default VPN detector implementation
/// Note: Actual implementation depends on platform capabilities
class VpnDetector implements IVpnDetector {
  VpnDetector({VpnDetectionRepository? repository}) : _repository = repository;
  final VpnDetectionRepository? _repository;

  @override
  bool get isSupported => _repository != null;

  @override
  Future<VpnDetectionResult> detect() async {
    try {
      moduleLogger.info('Checking VPN status', tag: 'VpnDetector');

      if (_repository == null) {
        return VpnDetectionResult(
          status: VpnStatus.unknown,
          detectionMethod: 'none',
          message: 'VPN detection not available on this platform',
          checkedAt: DateTime.now(),
        );
      }

      final result = await _repository.detectVpn();

      moduleLogger.info(
        'VPN detection result: ${result.status.name}',
        tag: 'VpnDetector',
      );

      return result;
    } catch (e, stackTrace) {
      moduleLogger.error(
        'VPN detection failed',
        tag: 'VpnDetector',
        error: e,
        stackTrace: stackTrace,
      );

      return VpnDetectionResult(
        status: VpnStatus.unknown,
        detectionMethod: 'error',
        message: 'Detection failed: $e',
        checkedAt: DateTime.now(),
      );
    }
  }
}

/// VPN detection repository interface
/// Platform-specific implementations should implement this
abstract class VpnDetectionRepository {
  /// Perform VPN detection
  Future<VpnDetectionResult> detectVpn();
}

/// Stub implementation for platforms without VPN detection
class StubVpnDetectionRepository implements VpnDetectionRepository {
  @override
  Future<VpnDetectionResult> detectVpn() async {
    return VpnDetectionResult(
      status: VpnStatus.unknown,
      detectionMethod: 'stub',
      message: 'VPN detection not implemented',
      checkedAt: DateTime.now(),
    );
  }
}
