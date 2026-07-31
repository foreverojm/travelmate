import 'package:flutter_tts/flutter_tts.dart';

/// 기기 내장 TTS로 현지어를 읽어주는 단일 서비스.
/// 음성 합성은 OS 엔진(안드로이드 Google TTS 등)을 쓰므로 무료이며,
/// 해당 언어 음성팩이 깔려 있으면 오프라인에서도 동작한다.
class PhraseTts {
  PhraseTts._();
  static final PhraseTts instance = PhraseTts._();

  final FlutterTts _tts = FlutterTts();
  String? _lang;
  bool _initDone = false;

  Future<void> _ensure() async {
    if (_initDone) return;
    await _tts.setSpeechRate(0.42); // 현지인이 알아듣기 쉽게 살짝 느리게
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initDone = true;
  }

  /// 해당 로케일 음성이 기기에 설치돼 있는지(없으면 무음일 수 있음)
  Future<bool> isAvailable(String locale) async {
    try {
      final v = await _tts.isLanguageAvailable(locale);
      return v == true;
    } catch (_) {
      return false;
    }
  }

  /// 현지어 재생. 재생이 끝나거나 오류면 조용히 종료.
  Future<void> speak(String text, String locale) async {
    await _ensure();
    await _tts.stop();
    if (_lang != locale) {
      await _tts.setLanguage(locale);
      _lang = locale;
    }
    await _tts.speak(text);
  }

  Future<void> stop() => _tts.stop();
}
