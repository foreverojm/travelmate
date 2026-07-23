import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'place_data.dart';

/// 로드 결과: 장소 목록 + 데이터 생성시각(generatedAt).
class PlacesData {
  final List<Place> places;
  final DateTime? generatedAt;
  const PlacesData(this.places, this.generatedAt);

  static const empty = PlacesData([], null);
  bool get isEmpty => places.isEmpty;
}

/// OSM 장소 데이터를 로드한다. (환율과 같은 '오프라인 우선 + 원격 갱신' 패턴)
/// - 앱 시작: 캐시(prefs) → 없으면 앱 내장 asset 으로 즉시 표시
/// - 온라인: 원격 JSON 받아 캐시에 저장 → 다음부터 최신 반영
///
/// 원격 URL만 살아 있으면 데이터 갱신에 앱 업데이트가 필요 없다.
/// (fetch_osm.py 결과 JSON을 아래 URL에 올리면 됨)
class PlacesRepository {
  // 데이터 JSON을 호스팅할 주소. 비워두면 앱 내장(asset)만 사용.
  // 예) 'https://raw.githubusercontent.com/<user>/<repo>/main/osm_places.json'
  static const String remoteUrl = String.fromEnvironment(
    'PLACES_URL',
    defaultValue: '',
  );

  static const _assetPath = 'assets/data/osm_places.json';
  static const _cacheKey = 'osm_places_json_v1';

  bool get hasRemote => remoteUrl.isNotEmpty;

  /// 즉시 표시용: 캐시 우선, 없으면 내장 asset.
  Future<PlacesData> loadInitial() async {
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
      return PlacesData.empty;
    }
  }

  /// 온라인 갱신. 실패/미설정 시 null (기존 데이터 유지).
  Future<PlacesData?> fetchRemote() async {
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

  PlacesData _parse(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = (map['places'] as List?) ?? const [];
      final places = list
          .map((e) => Place.fromJson(e as Map<String, dynamic>))
          .toList();
      final gen = map['generatedAt'];
      final at = (gen is String && gen.isNotEmpty)
          ? DateTime.tryParse(gen)?.toLocal()
          : null;
      return PlacesData(places, at);
    } catch (_) {
      return PlacesData.empty;
    }
  }
}
