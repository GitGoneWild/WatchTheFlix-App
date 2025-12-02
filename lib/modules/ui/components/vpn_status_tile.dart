// VpnStatusTile
// Settings tile showing VPN status and controls.

import 'package:flutter/material.dart';

import '../../vpn/detection/vpn_detector.dart';

/// VPN user preference
enum VpnPreference {
  /// Auto-detect VPN status
  auto,

  /// User declares VPN is on
  on,

  /// User declares VPN is off
  off,
}

/// VPN status tile widget for settings
class VpnStatusTile extends StatelessWidget {
  const VpnStatusTile({
    super.key,
    this.detectionResult,
    this.preference = VpnPreference.auto,
    this.onPreferenceChanged,
    this.onRefresh,
    this.isChecking = false,
  });
  final VpnDetectionResult? detectionResult;
  final VpnPreference preference;
  final ValueChanged<VpnPreference>? onPreferenceChanged;
  final VoidCallback? onRefresh;
  final bool isChecking;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getStatusIcon(),
                  color: _getStatusColor(context),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VPN Status',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        _getStatusText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _getStatusColor(context),
                            ),
                      ),
                    ],
                  ),
                ),
                if (isChecking)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (onRefresh != null)
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Re-check VPN status',
                    onPressed: onRefresh,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'VPN may affect certain providers. Disable if you have connection issues.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            _buildPreferenceSelector(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceSelector(BuildContext context) {
    return Row(
      children: [
        Text(
          'VPN Setting: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 8),
        SegmentedButton<VpnPreference>(
          segments: const [
            ButtonSegment(
              value: VpnPreference.auto,
              label: Text('Auto'),
              icon: Icon(Icons.auto_awesome, size: 16),
            ),
            ButtonSegment(
              value: VpnPreference.on,
              label: Text('On'),
              icon: Icon(Icons.vpn_lock, size: 16),
            ),
            ButtonSegment(
              value: VpnPreference.off,
              label: Text('Off'),
              icon: Icon(Icons.vpn_lock_outlined, size: 16),
            ),
          ],
          selected: {preference},
          onSelectionChanged: (selected) {
            onPreferenceChanged?.call(selected.first);
          },
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    final effectiveStatus = _getEffectiveStatus();
    switch (effectiveStatus) {
      case VpnStatus.active:
        return Icons.vpn_lock;
      case VpnStatus.inactive:
        return Icons.vpn_lock_outlined;
      case VpnStatus.unknown:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(BuildContext context) {
    final effectiveStatus = _getEffectiveStatus();
    switch (effectiveStatus) {
      case VpnStatus.active:
        return Colors.green;
      case VpnStatus.inactive:
        return Theme.of(context).colorScheme.onSurfaceVariant;
      case VpnStatus.unknown:
        return Colors.orange;
    }
  }

  String _getStatusText() {
    final effectiveStatus = _getEffectiveStatus();
    switch (effectiveStatus) {
      case VpnStatus.active:
        return preference == VpnPreference.on
            ? 'VPN declared as ON'
            : 'VPN detected';
      case VpnStatus.inactive:
        return preference == VpnPreference.off
            ? 'VPN declared as OFF'
            : 'No VPN detected';
      case VpnStatus.unknown:
        return 'VPN status unknown';
    }
  }

  VpnStatus _getEffectiveStatus() {
    switch (preference) {
      case VpnPreference.on:
        return VpnStatus.active;
      case VpnPreference.off:
        return VpnStatus.inactive;
      case VpnPreference.auto:
        return detectionResult?.status ?? VpnStatus.unknown;
    }
  }
}

/// Small VPN indicator badge for playback/account screens
class VpnIndicatorBadge extends StatelessWidget {
  const VpnIndicatorBadge({
    super.key,
    required this.status,
    this.compact = false,
  });
  final VpnStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (status != VpnStatus.active) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.vpn_lock,
          size: 12,
          color: Colors.green,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.vpn_lock, size: 14, color: Colors.green),
          SizedBox(width: 4),
          Text(
            'VPN',
            style: TextStyle(
              fontSize: 10,
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
