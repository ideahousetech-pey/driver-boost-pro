import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import '../models/connection_status.dart';
import '../models/gps_status.dart';

@pragma('vm:entry-point')
void optimizerServiceTask() {
  FlutterForegroundTask.setTaskHandler(OptimizerTaskHandler());
}

class OptimizerTaskHandler extends TaskHandler {
  // ← hapus constructor dengan super.key, TaskHandler tidak punya key
  Timer? _monitorTimer;
  final Connectivity _connectivity = Connectivity();

  int _intervalSeconds = 5;
  String _gpsAccuracy = 'high';
  bool _modeHematBaterai = false;

  @override
  void onStart(DateTime timestamp) {
    // ← void bukan Future<void>, hapus TaskStarter
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    _intervalSeconds =
        await FlutterForegroundTask.getData<int>(key: 'interval') ?? 5;
    _gpsAccuracy =
        await FlutterForegroundTask.getData<String>(key: 'gpsAccuracy') ?? 'high';
    _modeHematBaterai =
        await FlutterForegroundTask.getData<bool>(key: 'hematBaterai') ?? false;

    _startPeriodicCheck();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // tidak digunakan
  }

  @override
  void onReceiveData(Object data) {
    if (data is Map) {
      bool restartTimer = false;
      if (data.containsKey('interval')) {
        _intervalSeconds = data['interval'] as int;
        restartTimer = true;
      }
      if (data.containsKey('gpsAccuracy')) {
        _gpsAccuracy = data['gpsAccuracy'] as String;
      }
      if (data.containsKey('hematBaterai')) {
        _modeHematBaterai = data['hematBaterai'] as bool;
        restartTimer = true;
      }
      if (restartTimer) {
        _startPeriodicCheck();
      }
    }
  }

  void _startPeriodicCheck() {
    _monitorTimer?.cancel();

    final effectiveInterval = _modeHematBaterai
        ? (_intervalSeconds * 2).clamp(5, 300)
        : _intervalSeconds;

    _monitorTimer = Timer.periodic(
      Duration(seconds: effectiveInterval),
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

  Future<GpsStatus> _checkGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GpsStatus.empty();
    }

    LocationAccuracy accuracy;
    switch (_gpsAccuracy) {
      case 'low':
        accuracy = LocationAccuracy.low;
        break;
      case 'max':
        accuracy = LocationAccuracy.best;
        break;
      default:
        accuracy = LocationAccuracy.high;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        timeLimit: const Duration(seconds: 3),
      );
      return GpsStatus(
        isFixed: true,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        speed: position.speed,
        bearing: position.heading,
        altitude: position.altitude,
      );
    } catch (_) {
      return GpsStatus.empty();
    }
  }

  Future<void> _updateNotification(
      ConnectionStatus conn, GpsStatus gps) async {
    final connText = 'Internet: ${conn.stabilityText} (${conn.typeText})';
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
  void onNotificationButtonPressed(String id) {
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }
}