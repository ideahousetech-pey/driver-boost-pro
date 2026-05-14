import 'dart:async';

class AdaptivePoller {
  Timer? _timer;
  final int _baseIntervalSeconds;    // ← final
  final Future<void> Function() callback;
  bool _isStable = true;

  AdaptivePoller({
    required int baseIntervalSeconds,
    required this.callback,
  }) : _baseIntervalSeconds = baseIntervalSeconds;

  void start() {
    _timer?.cancel();
    _scheduleNext();
  }

  void _scheduleNext() {
    final effectiveInterval = _isStable
        ? (_baseIntervalSeconds * 2).clamp(5, 300)
        : _baseIntervalSeconds;
    _timer = Timer(Duration(seconds: effectiveInterval), () async {
      await callback();
      if (_timer != null) {
        _scheduleNext();
      }
    });
  }

  void markUnstable() {
    _isStable = false;
    if (_timer != null) {
      _timer!.cancel();
      _scheduleNext();
    }
  }

  void markStable() {
    _isStable = true;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}