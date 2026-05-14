import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/connection_status.dart';

class NetworkChecker {
  final Connectivity _connectivity = Connectivity();

  Future<ConnectionStatus> check() async {
    final result = await _connectivity.checkConnectivity();
    String type = 'none';
    if (result.contains(ConnectivityResult.wifi)) {
      type = 'wifi';
    } else if (result.contains(ConnectivityResult.mobile)) {
      type = 'mobile';
    }

    bool reachable = false;
    int latency = 0;
    try {
      final sw = Stopwatch()..start();
      final lookup = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 2));
      reachable = lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
      sw.stop();
      latency = sw.elapsedMilliseconds;
    } catch (_) {}

    return ConnectionStatus(
      isConnected: reachable,
      connectionType: type,
      latencyMs: latency,
      reachable: reachable,
    );
  }

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((result) {
      return result.contains(ConnectivityResult.mobile) ||
          result.contains(ConnectivityResult.wifi);
    });
  }
}