import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/country_data.dart';

/// 환율 데이터 + 마지막 갱신 시각을 함께 담는다.
class RateSnapshot {
  final Map<String, double> ratesPerKrw; // "1 KRW 당 통화 단위"
  final DateTime updatedAt;
  final bool isLive; // true=API에서 받은 값, false=시드/캐시

  const RateSnapshot({
    required this.ratesPerKrw,
    required this.updatedAt,
    required this.isLive,
  });
}

/// 환율을 온라인으로 받아오고, 오프라인 대비 로컬에 캐싱한다.
/// - 앱 시작 시: 캐시 → 없으면 시드값으로 즉시 표시(오프라인에서도 동작)
/// - 온라인이면: API로 갱신 후 캐시에 저장
class RateService {
  static const _kRatesKey = 'rates_per_krw_v1';
  static const _kUpdatedKey = 'rates_updated_at_v1';

  // 무료·키 불필요·전 통화 지원. 기준통화 KRW로 요청하면
  // rates[code] = "1 KRW 당 code 단위" 형태로 응답.
  static const _endpoint = 'https://open.er-api.com/v6/latest/KRW';

  /// 캐시가 있으면 캐시를, 없으면 시드값을 즉시 반환(항상 성공).
  Future<RateSnapshot> loadCachedOrSeed() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRatesKey);
    if (raw != null) {
      try {
        final decoded = (jsonDecode(raw) as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toDouble()),
        );
        final ts = prefs.getInt(_kUpdatedKey) ?? 0;
        return RateSnapshot(
          ratesPerKrw: {...seedRatesPerKrw, ...decoded},
          updatedAt: DateTime.fromMillisecondsSinceEpoch(ts),
          isLive: false,
        );
      } catch (_) {
        // 캐시 손상 시 시드로 폴백
      }
    }
    return RateSnapshot(
      ratesPerKrw: Map.of(seedRatesPerKrw),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isLive: false,
    );
  }

  /// 온라인 갱신 시도. 실패하면 null 반환(호출측에서 기존 값 유지).
  Future<RateSnapshot?> fetchLatest() async {
    try {
      final res = await http
          .get(Uri.parse(_endpoint))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      if (body['result'] != 'success') return null;

      final rates = (body['rates'] as Map<String, dynamic>);
      // 우리가 쓰는 통화만 추려 저장
      final wanted = <String, double>{};
      for (final code in seedRatesPerKrw.keys) {
        final v = rates[code];
        if (v is num) wanted[code] = v.toDouble();
      }
      wanted['KRW'] = 1.0;

      final snapshot = RateSnapshot(
        ratesPerKrw: {...seedRatesPerKrw, ...wanted},
        updatedAt: DateTime.now(),
        isLive: true,
      );
      await _cache(snapshot);
      return snapshot;
    } catch (_) {
      return null; // 오프라인/타임아웃 → 조용히 실패
    }
  }

  Future<void> _cache(RateSnapshot s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRatesKey, jsonEncode(s.ratesPerKrw));
    await prefs.setInt(_kUpdatedKey, s.updatedAt.millisecondsSinceEpoch);
  }
}
