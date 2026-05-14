import 'package:flutter/services.dart';

class VibrationAlert {
  static void vibrate() {
    HapticFeedback.heavyImpact();
  }
}