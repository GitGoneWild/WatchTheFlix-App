import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Network service for checking connectivity
class NetworkService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  /// Check if connected to internet
  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }

  /// Stream of connectivity changes
  /// Stream of connectivity changes
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return result != ConnectivityResult.none;
    });
  }

  /// Start monitoring connectivity
  void startMonitoring(void Function(bool isConnected) onChanged) {
    /// Start monitoring connectivity
    void startMonitoring(void Function(bool isConnected) onChanged) {
      _subscription = _connectivity.onConnectivityChanged.listen((result) {
        final connected = result != ConnectivityResult.none;
        onChanged(connected);
      });
    }

    void stopMonitoring() {
      _subscription?.cancel();
      _subscription = null;
    }

    /// Dispose resources
    void dispose() {
      stopMonitoring();
    }
  }
}
