import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps [connectivity_plus] and exposes a simple [bool] stream.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// Emits [true] when online, [false] when offline.
  /// Emits the initial status immediately upon subscription.
  Stream<bool> get onlineStream async* {
    yield await isOnline;
    await for (final results in _connectivity.onConnectivityChanged) {
      yield _isOnline(results);
    }
  }

  Future<bool> get isOnline async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _isOnline(results);
    } catch (_) {
      return true;
    }
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    if (results.isEmpty) return true;
    return !results.contains(ConnectivityResult.none);
  }
}
