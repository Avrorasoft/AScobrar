import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._();

  static final _connectivity = Connectivity();
  static bool _isOnline = true;
  static final _controller = StreamController<bool>.broadcast();

  static bool get isOnline => _isOnline;
  static Stream<bool> get onStatusChange => _controller.stream;

  static Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    _connectivity.onConnectivityChanged.listen((results) {
      final online = _isConnected(results);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
        debugPrint(online ? '🌐 Online' : '📴 Offline');
      }
    });
  }

  static bool _isConnected(List<ConnectivityResult> results) =>
      results.any((r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet);

  static void dispose() => _controller.close();
}