import 'dart:convert';
import 'package:http/http.dart' as http;

/// 사전에 없는 단어를 온라인으로 자동 번역(하이브리드의 보완 경로).
/// 무료·키 불필요인 MyMemory API 사용. 그 '단어'만 번역하므로 통신량이 적다.
/// 한글 발음은 자동 생성이 어려워 제공하지 않고, 화면의 🔊(TTS)로 발음을 듣게 한다.
class WordTranslator {
  static const Map<String, String> _lang = {
    'VN': 'vi',
    'JP': 'ja',
    'TW': 'zh-TW',
    'TH': 'th',
  };

  /// 한국어 단어 → 대상 국가 현지어. 실패 시 null.
  static Future<String?> translate(String koWord, String countryCode) async {
    final target = _lang[countryCode];
    if (target == null || koWord.trim().isEmpty) return null;
    final uri = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(koWord.trim())}&langpair=ko|$target');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final map = jsonDecode(res.body) as Map<String, dynamic>;
      final data = map['responseData'];
      final text = (data is Map) ? data['translatedText'] as String? : null;
      if (text == null || text.trim().isEmpty) return null;
      // 번역 실패 시 원문/경고를 그대로 돌려주는 경우 방지
      if (text.toUpperCase().contains('INVALID') ||
          text.toUpperCase().contains('MYMEMORY WARNING')) {
        return null;
      }
      return text.trim();
    } catch (_) {
      return null;
    }
  }
}
