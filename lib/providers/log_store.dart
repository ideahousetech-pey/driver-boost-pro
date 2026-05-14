import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_entry.dart';

class LogStore extends ChangeNotifier {
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => _logs;

  Future<void> load() async {
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
    }
    notifyListeners();
  }

  Future<void> add(String eventType, String status) async {
    _logs.insert(0, LogEntry(timestamp: DateTime.now(), eventType: eventType, status: status));
    while (_logs.length > 100) {
      _logs.removeLast();
    }
    await _save();
    notifyListeners();
  }

  Future<void> clear() async {
    _logs.clear();
    await _save();
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('logs', jsonEncode(_logs.map((e) => e.toJson()).toList()));
  }
}