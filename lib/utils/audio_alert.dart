import 'package:flutter/services.dart';

class AudioAlert {
  static void play() {
    HapticFeedback.heavyImpact();
    // Gunakan plugin audioplayers jika ingin suara nyata
    // final player = AudioPlayer();
    // player.play(AssetSource('sounds/alert.mp3'));
  }
}