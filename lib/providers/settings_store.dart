import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  int intervalSeconds = 5;
  bool notificationEnabled = true;
  String gpsAccuracy = 'high';
  bool keepScreenOn = true;
  bool autoReconnect = true;
  bool modeHematBaterai = false;
  bool notifikasiDrop = true;
  String themeMode = 'dark';

  bool soundAlert = false;
  bool vibrationAlert = true;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    intervalSeconds = prefs.getInt('interval') ?? 5;
    notificationEnabled = prefs.getBool('notificationEnabled') ?? true;
    gpsAccuracy = prefs.getString('gpsAccuracy') ?? 'high';
    keepScreenOn = prefs.getBool('keepScreenOn') ?? true;
    autoReconnect = prefs.getBool('autoReconnect') ?? true;
    modeHematBaterai = prefs.getBool('modeHematBaterai') ?? false;
    notifikasiDrop = prefs.getBool('notifikasiDrop') ?? true;
    themeMode = prefs.getString('themeMode') ?? 'dark';
    soundAlert = prefs.getBool('soundAlert') ?? false;
    vibrationAlert = prefs.getBool('vibrationAlert') ?? true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('interval', intervalSeconds);
    await prefs.setBool('notificationEnabled', notificationEnabled);
    await prefs.setString('gpsAccuracy', gpsAccuracy);
    await prefs.setBool('keepScreenOn', keepScreenOn);
    await prefs.setBool('autoReconnect', autoReconnect);
    await prefs.setBool('modeHematBaterai', modeHematBaterai);
    await prefs.setBool('notifikasiDrop', notifikasiDrop);
    await prefs.setString('themeMode', themeMode);
    await prefs.setBool('soundAlert', soundAlert);
    await prefs.setBool('vibrationAlert', vibrationAlert);
  }

  Future<void> setInterval(int s) async { intervalSeconds = s; await save(); notifyListeners(); }
  Future<void> setNotificationEnabled(bool v) async { notificationEnabled = v; await save(); notifyListeners(); }
  Future<void> setGpsAccuracy(String v) async { gpsAccuracy = v; await save(); notifyListeners(); }
  Future<void> setKeepScreenOn(bool v) async { keepScreenOn = v; await save(); notifyListeners(); }
  Future<void> setAutoReconnect(bool v) async { autoReconnect = v; await save(); notifyListeners(); }
  Future<void> setModeHematBaterai(bool v) async { modeHematBaterai = v; await save(); notifyListeners(); }
  Future<void> setNotifikasiDrop(bool v) async { notifikasiDrop = v; await save(); notifyListeners(); }
  Future<void> setThemeMode(String v) async { themeMode = v; await save(); notifyListeners(); }
  Future<void> setSoundAlert(bool v) async { soundAlert = v; await save(); notifyListeners(); }
  Future<void> setVibrationAlert(bool v) async { vibrationAlert = v; await save(); notifyListeners(); }
}