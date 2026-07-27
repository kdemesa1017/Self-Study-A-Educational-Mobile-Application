import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [connectivity_plus] and exposes a simple [bool] stream.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Emits [true] when online, [false] when offline.
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged.map(
    (results) => _isOnline(results),
  );

  Future<bool> get isOnline async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    return results.any(
      (r) =>
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.ethernet,
    );
  }
}
