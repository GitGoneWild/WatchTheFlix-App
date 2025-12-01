import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network service for checking connectivity
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// Check if connected to internet
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result.isNotEmpty &&
        result.any((r) => r != ConnectivityResult.none);
  }

  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
    });
  }

  /// Start monitoring connectivity
  void startMonitoring(void Function(bool isConnected) onChanged) {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final connected = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      onChanged(connected);
    });
  }

  /// Stop monitoring connectivity
  void stopMonitoring() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}
