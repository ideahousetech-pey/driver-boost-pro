import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/connection_status.dart';
import '../models/gps_status.dart';
import '../models/log_entry.dart';
import '../services/optimizer_service.dart';

class OptimizerProvider extends ChangeNotifier {
  // -------------------------------------------------------------
  // State dasar
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // Pengaturan lama
  // -------------------------------------------------------------
  int _intervalSeconds = 5;
  int get intervalSeconds => _intervalSeconds;
  bool _notificationEnabled = true;
  bool get notificationEnabled => _notificationEnabled;

  // -------------------------------------------------------------
  // Pengaturan baru
  // -------------------------------------------------------------
  String _gpsAccuracy = 'high';
  String get gpsAccuracy => _gpsAccuracy;

  bool _keepScreenOn = true;
  bool get keepScreenOn => _keepScreenOn;

  bool _autoReconnect = true;
  bool get autoReconnect => _autoReconnect;

  bool _modeHematBaterai = false;
  bool get modeHematBaterai => _modeHematBaterai;

  bool _notifikasiDrop = true;
  bool get notifikasiDrop => _notifikasiDrop;

  // -------------------------------------------------------------
  // Tema
  // -------------------------------------------------------------
  String _themeMode = 'dark'; // 'light', 'dark', atau 'system'
  String get themeMode => _themeMode;

  // -------------------------------------------------------------
  // Keamanan (belum digunakan secara aktif, tersedia untuk data sensitif)
  // -------------------------------------------------------------
  // ignore: unused_field
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // -------------------------------------------------------------
  // Dialog peringatan
  // -------------------------------------------------------------
  bool _showDropDialog = false;
  bool get showDropDialog => _showDropDialog;
  String _dropType = '';
  String get dropType => _dropType;

  Timer? _sessionTimer;
  Timer? _pollTimer;
  Timer? _batteryTimer;

  final Battery _battery = Battery();

  // -------------------------------------------------------------
  // Inisialisasi & penyimpanan pengaturan
  // -------------------------------------------------------------
  Future<void> initialize() async {
    await _loadSettings();
    await _loadLogs();
    _totalOptimizerSeconds =
        (await SharedPreferences.getInstance()).getInt('totalOptimizerSeconds') ?? 0;

    if (await FlutterForegroundTask.isRunningService) {
      final prefs = await SharedPreferences.getInstance();
      final startTimestamp = prefs.getInt('sessionStartTimestamp');
      if (startTimestamp != null) {
        _isActive = true;
        final now = DateTime.now().millisecondsSinceEpoch;
        _elapsedSeconds = ((now - startTimestamp) / 1000).round().clamp(0, 99999);
        _applyKeepScreenOn();
        _startSessionTimer();
        _startPolling();
        _startBatteryMonitor();
        notifyListeners();
      }
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _intervalSeconds = prefs.getInt('interval') ?? 5;
    _notificationEnabled = prefs.getBool('notificationEnabled') ?? true;
    _gpsAccuracy = prefs.getString('gpsAccuracy') ?? 'high';
    _keepScreenOn = prefs.getBool('keepScreenOn') ?? true;
    _autoReconnect = prefs.getBool('autoReconnect') ?? true;
    _modeHematBaterai = prefs.getBool('modeHematBaterai') ?? false;
    _notifikasiDrop = prefs.getBool('notifikasiDrop') ?? true;
    _themeMode = prefs.getString('themeMode') ?? 'dark';
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval', _intervalSeconds);
    await prefs.setBool('notificationEnabled', _notificationEnabled);
    await prefs.setString('gpsAccuracy', _gpsAccuracy);
    await prefs.setBool('keepScreenOn', _keepScreenOn);
    await prefs.setBool('autoReconnect', _autoReconnect);
    await prefs.setBool('modeHematBaterai', _modeHematBaterai);
    await prefs.setBool('notifikasiDrop', _notifikasiDrop);
    await prefs.setString('themeMode', _themeMode);
  }

  // -------------------------------------------------------------
  // Setter pengaturan baru (termasuk tema)
  // -------------------------------------------------------------
  Future<void> setInterval(int seconds) async {
    _intervalSeconds = seconds;
    await _saveSettings();
    if (_isActive) {
      _sendSettingsToService();
    }
    notifyListeners();
  }

  Future<void> setNotificationEnabled(bool value) async {
    _notificationEnabled = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setGpsAccuracy(String value) async {
    _gpsAccuracy = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setKeepScreenOn(bool value) async {
    _keepScreenOn = value;
    await _saveSettings();
    if (_isActive) {
      _applyKeepScreenOn();
    }
    notifyListeners();
  }

  Future<void> setAutoReconnect(bool value) async {
    _autoReconnect = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setModeHematBaterai(bool value) async {
    _modeHematBaterai = value;
    await _saveSettings();
    if (_isActive) {
      _sendSettingsToService();
    }
    notifyListeners();
  }

  Future<void> setNotifikasiDrop(bool value) async {
    _notifikasiDrop = value;
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setThemeMode(String value) async {
    _themeMode = value;
    await _saveSettings();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Kontrol optimizer (start / stop)
  // -------------------------------------------------------------
  Future<bool> _requestLocationPermissionWithRationale() async {
    final status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }

  Future<void> startOptimizer() async {
    if (_isActive) return;

    final hasPermission = await _requestLocationPermissionWithRationale();
    if (!hasPermission) {
      throw Exception('Izin lokasi belum diberikan');
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('GPS belum aktif');
    }

    final prefs = await SharedPreferences.getInstance();
    final startTimestamp = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt('sessionStartTimestamp', startTimestamp);

    await FlutterForegroundTask.startService(
      notificationTitle: 'Driver Optimizer',
      notificationText: 'Optimizer dimulai...',
      notificationButtons: [
        const NotificationButton(id: 'stop', text: 'Hentikan'),
      ],
      callback: optimizerServiceTask,
    );

    _sendSettingsToService();

    _isActive = true;
    _elapsedSeconds = 0;
    _heartbeatCount = 0;
    _fixGpsCount = 0;
    _dropNetCount = 0;
    _dronGpsCount = 0;
    _sessionDurationSecs = 0;

    _applyKeepScreenOn();
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

    _releaseKeepScreenOn();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Wakelock
  // -------------------------------------------------------------
  void _applyKeepScreenOn() {
    if (_keepScreenOn) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _releaseKeepScreenOn() {
    WakelockPlus.disable();
  }

  // -------------------------------------------------------------
  // Kirim pengaturan ke foreground service
  // -------------------------------------------------------------
  void _sendSettingsToService() {
    FlutterForegroundTask.sendDataToTask({
      'interval': _intervalSeconds,
      'gpsAccuracy': _gpsAccuracy,
      'hematBaterai': _modeHematBaterai,
    });
  }

  // -------------------------------------------------------------
  // Timer internal
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
    final conn = await _checkConnectionDirect();
    final gps = await _checkGpsDirect();

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

    LocationAccuracy accuracy;
    switch (_gpsAccuracy) {
      case 'low':
        accuracy = LocationAccuracy.low;
        break;
      case 'high':
        accuracy = LocationAccuracy.high;
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

  // -------------------------------------------------------------
  // Log dengan pembatasan 100 entri & hapus >7 hari saat muat
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
    while (_logs.length > 100) {
      _logs.removeLast();
    }
    _saveLogs();
    if (kDebugMode) {
      debugPrint('Log: $eventType ($status)');
    }
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
  // Pengecekan manual
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
  // Baterai
  // -------------------------------------------------------------
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

  // -------------------------------------------------------------
  // Penyimpanan log (filter >7 hari saat muat)
  // -------------------------------------------------------------
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
      final now = DateTime.now();
      for (var item in decoded) {
        final log = LogEntry.fromJson(Map<String, dynamic>.from(item));
        if (now.difference(log.timestamp).inDays < 7) {
          _logs.add(log);
        }
      }
      _saveLogs();
    }
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _pollTimer?.cancel();
    _batteryTimer?.cancel();
    _releaseKeepScreenOn();
    super.dispose();
  }
}