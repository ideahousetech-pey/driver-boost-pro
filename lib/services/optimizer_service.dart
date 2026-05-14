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
  // Tidak ada konstruktor tambahan

  StreamSubscription? _connectivitySub;
  StreamSubscription? _gpsStatusSub;
  Timer? _watchdogTimer;

  final Connectivity _connectivity = Connectivity();

  // Pengaturan default (akan diperbarui oleh provider setelah start)
  int _intervalSeconds = 5;
  String _gpsAccuracy = 'high';
  bool _modeHematBaterai = false;

  ConnectionStatus _lastConn = ConnectionStatus.empty();
  GpsStatus _lastGps = GpsStatus.empty();

  @override
  Future<void> onStart(DateTime timestamp) async {
    // Mulai pemantauan via stream
    _startMonitoring();

    // Pengecekan awal segera
    await _performCheck();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Tidak digunakan
  }

  void _startMonitoring() {
    // 1. Pantau perubahan koneksi internet
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) async {
      final conn = await _checkConnection();
      _updateIfChanged(conn: conn);
    });

    // 2. Pantau status layanan lokasi (GPS on/off)
    _gpsStatusSub = Geolocator.getServiceStatusStream().listen((status) async {
      final gps = await _checkGps();
      _updateIfChanged(gps: gps);
    });

    // 3. Watchdog fallback
    _resetWatchdog();
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    // Jika mode hemat baterai, watchdog jarang; jika tidak, 60 detik
    int interval = _modeHematBaterai ? (_intervalSeconds * 2).clamp(30, 300) : 60;
    _watchdogTimer = Timer(Duration(seconds: interval), () async {
      await _performCheck();
      _resetWatchdog();
    });
  }

  Future<void> _performCheck() async {
    final conn = await _checkConnection();
    final gps = await _checkGps();
    _updateIfChanged(conn: conn, gps: gps);
  }

  void _updateIfChanged({ConnectionStatus? conn, GpsStatus? gps}) {
    bool changed = false;

    if (conn != null &&
        (conn.isConnected != _lastConn.isConnected ||
            conn.connectionType != _lastConn.connectionType)) {
      _lastConn = conn;
      changed = true;
    }

    if (gps != null && gps.isFixed != _lastGps.isFixed) {
      _lastGps = gps;
      changed = true;
    }

    if (changed) {
      FlutterForegroundTask.sendDataToMain({
        'connection': _lastConn.toJson(),
        'gps': _lastGps.toJson(),
      });
      _updateNotification(_lastConn, _lastGps);
    }
  }

  Future<ConnectionStatus> _checkConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    String type = 'none';
    if (connectivityResult.contains(ConnectivityResult.wifi)) {
      type = 'wifi';
    } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
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
      case 'high':
        accuracy = LocationAccuracy.high;
        break;
      case 'max':
        accuracy = LocationAccuracy.bestForNavigation;
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

  Future<void> _updateNotification(ConnectionStatus conn, GpsStatus gps) async {
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
  void onReceiveData(Object data) {
    if (data is Map) {
      bool restartWatchdog = false;
      if (data.containsKey('interval')) {
        _intervalSeconds = data['interval'] as int;
        restartWatchdog = true;
      }
      if (data.containsKey('gpsAccuracy')) {
        _gpsAccuracy = data['gpsAccuracy'] as String;
      }
      if (data.containsKey('hematBaterai')) {
        _modeHematBaterai = data['hematBaterai'] as bool;
        restartWatchdog = true;
      }
      if (restartWatchdog) {
        _resetWatchdog();
      }
      // Jika diminta periksa ulang segera
      if (data.containsKey('forceCheck')) {
        _performCheck();
      }
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _connectivitySub?.cancel();
    _gpsStatusSub?.cancel();
    _watchdogTimer?.cancel();
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