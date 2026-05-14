import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/connection_status.dart';
import '../models/gps_status.dart';
import '../models/log_entry.dart';
import '../services/network_checker.dart';
import '../services/gps_checker.dart';
import '../services/adaptive_poller.dart';
import '../services/optimizer_service.dart';
import 'settings_store.dart';
import 'log_store.dart';

class OptimizerProvider extends ChangeNotifier {
  final SettingsStore settingsStore;
  final LogStore logStore;
  final NetworkChecker _networkChecker;
  final GpsChecker _gpsChecker;

  // -------------------------------------------------------------
  // State dasar
  // -------------------------------------------------------------
  bool _isActive = false;
  bool get isActive => _isActive;
  bool _initialDataReceived = false;
  bool get initialDataReceived => _initialDataReceived;

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

  // -------------------------------------------------------------
  // Grace period (10 detik setelah start)
  // -------------------------------------------------------------
  DateTime? _gracePeriodEnd;
  bool get _isGracePeriod {
    if (_gracePeriodEnd == null) return false;
    return DateTime.now().isBefore(_gracePeriodEnd!);
  }

  // -------------------------------------------------------------
  // Dialog peringatan
  // -------------------------------------------------------------
  bool _showDropDialog = false;
  bool get showDropDialog => _showDropDialog;
  String _dropType = '';
  String get dropType => _dropType;

  Timer? _sessionTimer;
  AdaptivePoller? _adaptivePoller;
  Timer? _batteryTimer;

  final Battery _battery = Battery();

  // -------------------------------------------------------------
  // Konstruktor dengan dependensi
  // -------------------------------------------------------------
  OptimizerProvider({
    required this.settingsStore,
    required this.logStore,
    NetworkChecker? networkChecker,
    GpsChecker? gpsChecker,
  })  : _networkChecker = networkChecker ?? NetworkChecker(),
        _gpsChecker = gpsChecker ?? GpsChecker() {
    settingsStore.addListener(_onSettingsChanged);
    logStore.addListener(_onLogChanged);
  }

  void _onSettingsChanged() => notifyListeners();
  void _onLogChanged() => notifyListeners();

  // -------------------------------------------------------------
  // Inisialisasi (dipanggil dari main)
  // -------------------------------------------------------------
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _totalOptimizerSeconds = prefs.getInt('totalOptimizerSeconds') ?? 0;

    if (await FlutterForegroundTask.isRunningService) {
      final startTimestamp = prefs.getInt('sessionStartTimestamp');
      if (startTimestamp != null) {
        _isActive = true;
        final now = DateTime.now().millisecondsSinceEpoch;
        _elapsedSeconds = ((now - startTimestamp) / 1000).round().clamp(0, 99999);
        // Grace period tidak berlaku setelah restart service
        _applyKeepScreenOn();
        _startSessionTimer();
        _startAdaptivePolling();
        _startBatteryMonitor();
        notifyListeners();
      }
    }
  }

  // -------------------------------------------------------------
  // Getter pengaturan (dari SettingsStore)
  // -------------------------------------------------------------
  int get intervalSeconds => settingsStore.intervalSeconds;
  bool get notificationEnabled => settingsStore.notificationEnabled;
  String get gpsAccuracy => settingsStore.gpsAccuracy;
  bool get keepScreenOn => settingsStore.keepScreenOn;
  bool get autoReconnect => settingsStore.autoReconnect;
  bool get modeHematBaterai => settingsStore.modeHematBaterai;
  bool get notifikasiDrop => settingsStore.notifikasiDrop;
  String get themeMode => settingsStore.themeMode;
  bool get soundAlert => settingsStore.soundAlert;
  bool get vibrationAlert => settingsStore.vibrationAlert;

  List<LogEntry> get logs => logStore.logs;

  // -------------------------------------------------------------
  // Setter pengaturan (diteruskan ke SettingsStore)
  // -------------------------------------------------------------
  Future<void> setInterval(int seconds) async {
    await settingsStore.setInterval(seconds);
    if (_isActive) {
      _sendSettingsToService();
      _restartAdaptivePolling();
    }
  }

  Future<void> setNotificationEnabled(bool v) async =>
      await settingsStore.setNotificationEnabled(v);
  Future<void> setGpsAccuracy(String v) async =>
      await settingsStore.setGpsAccuracy(v);
  Future<void> setKeepScreenOn(bool v) async {
    await settingsStore.setKeepScreenOn(v);
    if (_isActive) _applyKeepScreenOn();
  }
  Future<void> setAutoReconnect(bool v) async =>
      await settingsStore.setAutoReconnect(v);
  Future<void> setModeHematBaterai(bool v) async {
    await settingsStore.setModeHematBaterai(v);
    if (_isActive) {
      _sendSettingsToService();
      _restartAdaptivePolling();
    }
  }
  Future<void> setNotifikasiDrop(bool v) async =>
      await settingsStore.setNotifikasiDrop(v);
  Future<void> setThemeMode(String v) async =>
      await settingsStore.setThemeMode(v);
  Future<void> setSoundAlert(bool v) async =>
      await settingsStore.setSoundAlert(v);
  Future<void> setVibrationAlert(bool v) async =>
      await settingsStore.setVibrationAlert(v);

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
    if (!hasPermission) throw Exception('Izin lokasi belum diberikan');

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
    _initialDataReceived = false;

    // Aktifkan grace period 10 detik
    _gracePeriodEnd = DateTime.now().add(const Duration(seconds: 10));

    _applyKeepScreenOn();
    _startSessionTimer();
    _startAdaptivePolling();
    _startBatteryMonitor();
    notifyListeners();
  }

  Future<void> stopOptimizer() async {
    if (!_isActive) return;
    await FlutterForegroundTask.stopService();
    _sessionTimer?.cancel();
    _adaptivePoller?.stop();
    _batteryTimer?.cancel();

    _totalOptimizerSeconds += _elapsedSeconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('totalOptimizerSeconds', _totalOptimizerSeconds);
    await prefs.remove('sessionStartTimestamp');

    _isActive = false;
    _connectionStatus = ConnectionStatus.empty();
    _gpsStatus = GpsStatus.empty();
    _elapsedSeconds = 0;
    _gracePeriodEnd = null;

    _releaseKeepScreenOn();
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Wakelock
  // -------------------------------------------------------------
  void _applyKeepScreenOn() {
    if (settingsStore.keepScreenOn) {
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
      'interval': settingsStore.intervalSeconds,
      'gpsAccuracy': settingsStore.gpsAccuracy,
      'hematBaterai': settingsStore.modeHematBaterai,
    });
  }

  // -------------------------------------------------------------
  // Timer session (durasi)
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

  // -------------------------------------------------------------
  // Adaptive polling
  // -------------------------------------------------------------
  void _startAdaptivePolling() {
    _adaptivePoller?.stop();
    int base = settingsStore.intervalSeconds;
    if (settingsStore.modeHematBaterai) {
      base = (base * 2).clamp(5, 300);
    }
    _adaptivePoller = AdaptivePoller(
      baseIntervalSeconds: base,
      callback: _performPoll,
    );
      if (!_initialDataReceived) {
         _initialDataReceived = true;
    };
    _adaptivePoller!.start();
  }

  void _restartAdaptivePolling() {
    if (_isActive) _startAdaptivePolling();
  }

  Future<void> _performPoll() async {
    final conn = await _networkChecker.check();
    final gps = await _gpsChecker.check(accuracy: settingsStore.gpsAccuracy);

    // Deteksi perubahan status internet
    if (_connectionStatus.isConnected != conn.isConnected) {
      if (conn.isConnected) {
        logStore.add('Internet pulih', 'normal');
        _adaptivePoller?.markStable();
      } else {
        logStore.add('Drop internet', 'drop');
        _dropNetCount++;
        _adaptivePoller?.markUnstable();
        if (!_isGracePeriod) {
          _triggerDropDialog('internet');
        }
      }
    }

    // Deteksi perubahan status GPS
    if (_gpsStatus.isFixed != gps.isFixed) {
      if (gps.isFixed) {
        logStore.add('GPS pulih', 'normal');
        _adaptivePoller?.markStable();
      } else {
        logStore.add('GPS mati', 'drop');
        _dronGpsCount++;
        _adaptivePoller?.markUnstable();
        if (!_isGracePeriod) {
          _triggerDropDialog('gps');
        }
      }
    }

    _connectionStatus = conn;
    _gpsStatus = gps;
    _heartbeatCount++;
    if (gps.isFixed) _fixGpsCount++;
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Dialog peringatan
  // -------------------------------------------------------------
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
  // Pengecekan manual (dari tombol "Cek sekarang")
  // -------------------------------------------------------------
  Future<Map<String, String>> manualCheck() async {
    final conn = await _networkChecker.check();
    final gps = await _gpsChecker.check(accuracy: settingsStore.gpsAccuracy);
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

  @override
  void dispose() {
    settingsStore.removeListener(_onSettingsChanged);
    logStore.removeListener(_onLogChanged);
    _sessionTimer?.cancel();
    _adaptivePoller?.stop();
    _batteryTimer?.cancel();
    _releaseKeepScreenOn();
    super.dispose();
  }
}