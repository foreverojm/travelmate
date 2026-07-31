import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'price_data.dart';

/// 로드 결과: 시세 목록 + 생성시각 + 출처/안내(신뢰도 표기용).
class PricesData {
  final List<PriceItem> items;
  final DateTime? generatedAt;
  final String source; // 데이터 출처 표기
  final String note; // 상단 안내
  const PricesData(this.items, this.generatedAt,
      {this.source = '', this.note = ''});

  static const empty = PricesData([], null);
  bool get isEmpty => items.isEmpty;
}

/// 물품 시세(prices.json)를 로드한다. 맛집 데이터와 같은 '오프라인 우선 + 원격 갱신' 패턴.
/// 시세는 앱 업데이트 없이 원격 JSON만 갱신하면 사용자에게 반영된다.
class PricesRepository {
  static const String remoteUrl = String.fromEnvironment(
    'PRICES_URL',
    defaultValue:
        'https://raw.githubusercontent.com/foreverojm/travelmate/main/assets/data/prices.json',
  );

  static const _assetPath = 'assets/data/prices.json';
  static const _cacheKey = 'prices_json_v1';

  bool get hasRemote => remoteUrl.isNotEmpty;

  Future<PricesData> loadInitial() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      final data = _parse(cached);
      if (!data.isEmpty) return data;
    }
    try {
      final asset = await rootBundle.loadString(_assetPath);
      return _parse(asset);
    } catch (_) {
      return PricesData.empty;
    }
  }

  Future<PricesData?> fetchRemote() async {
    if (remoteUrl.isEmpty) return null;
    try {
      final res = await http
          .get(Uri.parse(remoteUrl))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final data = _parse(res.body);
      if (data.isEmpty) return null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, res.body);
      return data;
    } catch (_) {
      return null;
    }
  }

  PricesData _parse(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = (map['items'] as List?) ?? const [];
      final items = list
          .map((e) => PriceItem.fromJson(e as Map<String, dynamic>))
          .toList();
      final gen = map['generatedAt'];
      final at = (gen is String && gen.isNotEmpty)
          ? DateTime.tryParse(gen)?.toLocal()
          : null;
      return PricesData(items, at,
          source: (map['source'] as String?) ?? '',
          note: (map['note'] as String?) ?? '');
    } catch (_) {
      return PricesData.empty;
    }
  }
}
