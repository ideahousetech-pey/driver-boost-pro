import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/connection_status.dart';
import '../models/gps_status.dart';
import '../models/log_entry.dart';
import '../services/optimizer_service.dart';

class OptimizerProvider extends ChangeNotifier {
  bool _isActive = false;
  bool get isActive => _isActive;

  ConnectionStatus _connectionStatus = ConnectionStatus.empty();
  ConnectionStatus get connectionStatus => _connectionStatus;
  GpsStatus _gpsStatus = GpsStatus.empty();
  GpsStatus get gpsStatus => _gpsStatus;

  int _elapsedSeconds = 0;
  int get elapsedSeconds => _elapsedSeconds;
  int _totalOptimizerSeconds = 0;
  int get totalDisplaySeconds => _totalOptimizerSeconds + _elapsedSeconds;

  int _heartbeatCount = 0;
  int get heartbeatCount => _heartbeatCount;
  int _fixGpsCount = 0;
  int get fixGpsCount => _fixGpsCount;
  int _dropNetCount = 0;
  int get dropNetCount => _dropNetCount;
  int _dronGpsCount = 0;
  int get dronGpsCount => _dronGpsCount;
  int _sessionDurationSecs = 0;
  int get sessionDurationSecs => _sessionDurationSecs;

  int _batteryLevel = 100;
  int get batteryLevel => _batteryLevel;

  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => _logs;

  int _intervalSeconds = 5;
  int get intervalSeconds => _intervalSeconds;
  bool _notificationEnabled = true;
  bool get notificationEnabled => _notificationEnabled;

  bool _showDropDialog = false;
  bool get showDropDialog => _showDropDialog;
  String _dropType = '';
  String get dropType => _dropType;

  Timer? _sessionTimer; // untuk durasi
  Timer? _pollTimer;    // untuk pengecekan real‑time oleh UI
  Timer? _batteryTimer;

  final Battery _battery = Battery();

  // -------------------------------------------------------------
  Future<void> initialize() async {
    await _loadSettings();
    await _loadLogs();
    _totalOptimizerSeconds =
        (await SharedPreferences.getInstance()).getInt('totalOptimizerSeconds') ?? 0;

    // Cek apakah service sedang berjalan (aplikasi dibuka ulang)
    if (await FlutterForegroundTask.isRunningService) {
      final prefs = await SharedPreferences.getInstance();
      final startTimestamp = prefs.getInt('sessionStartTimestamp');
      if (startTimestamp != null) {
        _isActive = true;
        final now = DateTime.now().millisecondsSinceEpoch;
        _elapsedSeconds = ((now - startTimestamp) / 1000).round().clamp(0, 99999);
        _startSessionTimer();
        _startPolling();   // mulai pengecekan UI
        _startBatteryMonitor();
        notifyListeners();
      }
    }
  }

  // -------------------------------------------------------------
  Future<void> startOptimizer() async {
    if (_isActive) return;

    // Izin lokasi
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (await Geolocator.requestPermission() == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak permanen');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS belum aktif');
    }

    // Simpan waktu mulai
    final prefs = await SharedPreferences.getInstance();
    final startTimestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('sessionStartTimestamp', startTimestamp);

    // Mulai foreground service
    await FlutterForegroundTask.startService(
      notificationTitle: 'Driver Optimizer',
      notificationText: 'Optimizer dimulai...',
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'Hentikan'),
      ],
      callback: optimizerServiceTask,
    );

    // Kirim interval ke service
    FlutterForegroundTask.sendDataToTask({'interval': _intervalSeconds});

    // Atur state aktif
    _isActive = true;
    _elapsedSeconds = 0;
    _heartbeatCount = 0;
    _fixGpsCount = 0;
    _dropNetCount = 0;
    _dronGpsCount = 0;
    _sessionDurationSecs = 0;

    _startSessionTimer();
    _startPolling();
    _startBatteryMonitor();
    notifyListeners();
  }

  Future<void> stopOptimizer() async {
    if (!_isActive) return;

    await FlutterForegroundTask.stopService();
    _sessionTimer?.cancel();
    _pollTimer?.cancel();
    _batteryTimer?.cancel();

    _totalOptimizerSeconds += _elapsedSeconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalOptimizerSeconds', _totalOptimizerSeconds);
    await prefs.remove('sessionStartTimestamp');

    _isActive = false;
    _connectionStatus = ConnectionStatus.empty();
    _gpsStatus = GpsStatus.empty();
    _elapsedSeconds = 0;
    notifyListeners();
  }

  // -------------------------------------------------------------
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_isActive) return;
      _elapsedSeconds++;
      _sessionDurationSecs = _elapsedSeconds;
      notifyListeners();
    });
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!_isActive) return;
      await _performPoll();
    });
  }

  Future<void> _performPoll() async {
    // Cek koneksi & GPS dari main isolate
    final conn = await _checkConnectionDirect();
    final gps = await _checkGpsDirect();

    // Deteksi perubahan
    if (_connectionStatus.isConnected != conn.isConnected) {
      if (conn.isConnected) {
        _addLog('Internet pulih', 'normal');
      } else {
        _addLog('Drop internet', 'drop');
        _dropNetCount++;
        _triggerDropDialog('internet');
      }
    }
    if (_gpsStatus.isFixed != gps.isFixed) {
      if (gps.isFixed) {
        _addLog('GPS pulih', 'normal');
      } else {
        _addLog('GPS mati', 'drop');
        _dronGpsCount++;
        _triggerDropDialog('gps');
      }
    }

    _connectionStatus = conn;
    _gpsStatus = gps;
    _heartbeatCount++;
    if (gps.isFixed) _fixGpsCount++;
    notifyListeners();
  }

  Future<ConnectionStatus> _checkConnectionDirect() async {
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
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

  Future<GpsStatus> _checkGpsDirect() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return GpsStatus.empty();
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
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

  // -------------------------------------------------------------
  void _addLog(String eventType, String status) {
    _logs.insert(
      0,
      LogEntry(
        timestamp: DateTime.now(),
        eventType: eventType,
        status: status,
      ),
    );
    _saveLogs();
    notifyListeners();
  }

  void _triggerDropDialog(String type) {
    _showDropDialog = true;
    _dropType = type;
    notifyListeners();
  }

  void dismissDropDialog() {
    _showDropDialog = false;
    notifyListeners();
  }

  // -------------------------------------------------------------
  Future<Map<String, String>> manualCheck() async {
    final conn = await _checkConnectionDirect();
    final gps = await _checkGpsDirect();
    return {
      'latency': conn.latencyMs > 0 ? '${conn.latencyMs} ms' : 'Gagal',
      'reachable': conn.reachable ? 'Ya' : 'Tidak',
      'connectionType': conn.typeText,
      'gpsFix': gps.isFixed ? 'Terkunci' : 'Tidak Terkunci',
    };
  }

  // -------------------------------------------------------------
  Future<void> setInterval(int seconds) async {
    _intervalSeconds = seconds;
    await (await SharedPreferences.getInstance()).setInt('interval', seconds);
    if (_isActive) {
      FlutterForegroundTask.sendDataToTask({'interval': seconds});
    }
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool value) async {
    _notificationEnabled = value;
    await (await SharedPreferences.getInstance())
        .setBool('notificationEnabled', value);
    notifyListeners();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _intervalSeconds = prefs.getInt('interval') ?? 5;
    _notificationEnabled = prefs.getBool('notificationEnabled') ?? true;
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'logs', jsonEncode(_logs.map((e) => e.toJson()).toList()));
  }

  Future<void> _loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('logs');
    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _logs.clear();
      _logs.addAll(
          decoded.map((e) => LogEntry.fromJson(Map<String, dynamic>.from(e))));
    }
  }

  void _startBatteryMonitor() {
    _batteryTimer?.cancel();
    _batteryTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        _batteryLevel = await _battery.batteryLevel;
        notifyListeners();
      } catch (_) {}
    });
    _battery.batteryLevel.then((level) {
      _batteryLevel = level;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollTimer?.cancel();
    _batteryTimer?.cancel();
    super.dispose();
  }
}