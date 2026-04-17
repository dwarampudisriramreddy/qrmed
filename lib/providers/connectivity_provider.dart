import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isOnline = true;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool get isOnline => _isOnline;

  ConnectivityProvider() {
    _init();
  }

  Future<void> _init() async {
    // Initial check
    final List<ConnectivityResult> results = await _connectivity.checkConnectivity();
    _updateStatus(results);

    // Listen to changes
    _subscription = _connectivity.onConnectivityChanged.listen(_updateStatus);
  }

  void _updateStatus(List<ConnectivityResult> results) {
    bool online = false;
    // If results is empty or all results are 'none', it's offline
    if (results.isNotEmpty) {
      for (var result in results) {
        if (result != ConnectivityResult.none) {
          online = true;
          break;
        }
      }
    }
    
    if (_isOnline != online) {
      _isOnline = online;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
