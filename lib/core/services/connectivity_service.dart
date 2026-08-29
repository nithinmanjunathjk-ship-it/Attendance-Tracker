import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Exposes a simple online/offline stream used to drive the app's
/// offline-queue sync logic and UI sync-status indicators.
class ConnectivityService {
  ConnectivityService._internal() {
    _connectivity.onConnectivityChanged.listen((results) {
      final online = _isOnline(results);
      if (online != _lastKnownState) {
        _lastKnownState = online;
        _controller.add(online);
      }
    });
  }

  static final ConnectivityService instance = ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _controller = StreamController.broadcast();
  bool _lastKnownState = true;

  Stream<bool> get onStatusChange => _controller.stream;

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }

  Future<bool> checkConnection() async {
    final results = await _connectivity.checkConnectivity();
    _lastKnownState = _isOnline(results);
    return _lastKnownState;
  }

  void dispose() {
    _controller.close();
  }
}
