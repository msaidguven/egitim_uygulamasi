import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final FlutterTts _tts = FlutterTts();

  /// Tek seferlik ayarlar
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;

    await _tts.setLanguage("tr-TR");
    await _tts.setSpeechRate(0.45); // çocuklar için yavaş
    await _tts.setPitch(1.1);       // biraz daha canlı
    await _tts.setVolume(1.0);

    _initialized = true;
  }

  /// Metni seslendir
  static Future<void> speak(String text) async {
    await _init();
    await _tts.stop(); // üst üste binmeyi engeller
    await _tts.speak(text);
  }

  /// Ses varsa durdur
  static Future<void> stop() async {
    await _tts.stop();
  }
}
