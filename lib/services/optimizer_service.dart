import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../models/connection_status.dart';
import '../models/gps_status.dart';

/// ENTRY POINT (WAJIB TOP LEVEL)
@pragma('vm:entry-point')
void optimizerServiceTask() {
  FlutterForegroundTask.setTaskHandler(
    OptimizerTaskHandler(),
  );
}

class OptimizerTaskHandler extends TaskHandler {
  Timer? _monitorTimer;
  final Connectivity _connectivity = Connectivity();

  OptimizerTaskHandler();

  @override
  void onStart(DateTime timestamp) {
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    final interval =
        await FlutterForegroundTask.getData<int>(key: 'interval') ?? 5;
    _startMonitoring(interval);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // tidak dipakai
  }

  void _startMonitoring(int seconds) {
    _monitorTimer?.cancel();

    _monitorTimer = Timer.periodic(
      Duration(seconds: seconds),
      (_) async {
        final conn = await _checkConnection();
        final gps = await _checkGps();

        FlutterForegroundTask.sendDataToMain({
          'connection': conn.toJson(),
          'gps': gps.toJson(),
        });

        await _updateNotification(conn, gps);
      },
    );
  }

  Future<ConnectionStatus> _checkConnection() async {
    final results = await _connectivity.checkConnectivity();

    String type = 'none';

    if (results.contains(ConnectivityResult.wifi)) {
      type = 'wifi';
    } else if (results.contains(ConnectivityResult.mobile)) {
      type = 'mobile';
    }

    bool reachable = false;
    int latency = 0;

    try {
      final sw = Stopwatch()..start();

      final lookup = await InternetAddress.lookup('8.8.8.8')
          .timeout(const Duration(seconds: 2));

      reachable =
          lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;

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

  Future<GpsStatus> _checkGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GpsStatus.empty();
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 3),
        ),
      );

      return GpsStatus(
        isFixed: true,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        bearing: pos.heading,
        altitude: pos.altitude,
      );
    } catch (_) {
      return GpsStatus.empty();
    }
  }

  Future<void> _updateNotification(
    ConnectionStatus conn,
    GpsStatus gps,
  ) async {
    final connText =
        'Internet: ${conn.stabilityText} (${conn.typeText})';

    final gpsText = gps.isFixed
        ? ' | GPS: Terkunci (${gps.accuracyText})'
        : ' | GPS: Tidak Terkunci';

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Driver Optimizer Aktif',
      notificationText: '$connText$gpsText',
    );
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _monitorTimer?.cancel();
  }

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onReceiveData(Object data) {}
}