import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'contrib_config.dart';
import 'user_place.dart';

/// Supabase REST(순수 http)로 여행자 제보를 읽고/쓰고/추천한다.
/// 네이티브 SDK 없이 동작 → 빌드 안전.
class ContribService {
  String get _base => '${ContribConfig.supabaseUrl}/rest/v1';
  Map<String, String> get _headers => {
        'apikey': ContribConfig.supabaseAnonKey,
        'Authorization': 'Bearer ${ContribConfig.supabaseAnonKey}',
        'Content-Type': 'application/json',
      };

  // ── 기기 식별(익명) : 스팸 제한·중복 추천 방지용 ──
  Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('contrib_device_id');
    if (id == null) {
      final r = Random();
      id = 'd${DateTime.now().millisecondsSinceEpoch}${r.nextInt(1 << 32)}';
      await prefs.setString('contrib_device_id', id);
    }
    return id;
  }

  // 공개 조회 컬럼(device_id 제외 — 소유 증명용 비밀로 유지)
  static const _cols =
      'id,type,country_code,city,name,kind,audience,price_hint,note,lat,lng,confirms,status,created_at';

  // ── 목록 조회 (숨김 제외, 최신순) ──
  Future<List<UserPlace>> fetchAll() async {
    if (!ContribConfig.enabled) return const [];
    final uri = Uri.parse(
        '$_base/contributions?select=$_cols&status=neq.hidden&order=created_at.desc&limit=500');
    try {
      final res = await http.get(uri, headers: _headers).timeout(
            const Duration(seconds: 10),
          );
      if (res.statusCode != 200) return const [];
      final list = jsonDecode(res.body) as List;
      return list
          .map((e) => UserPlace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ── 제보 등록 → 성공 시 생성된 id 반환(내 제보로 기억) ──
  Future<String?> submit(UserPlace p) async {
    if (!ContribConfig.enabled) return null;
    final deviceId = await this.deviceId();
    final uri = Uri.parse('$_base/contributions');
    try {
      final res = await http
          .post(uri,
              headers: {..._headers, 'Prefer': 'return=representation'},
              body: jsonEncode(p.toInsert(deviceId)))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 201 || res.statusCode == 200) {
        await _recordSubmit();
        String? id;
        try {
          id = '${(jsonDecode(res.body) as List).first['id']}';
        } catch (_) {}
        if (id != null) await _rememberMine(id);
        return id ?? '';
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── 내가 올린 제보 id 기억(자기 글 자기추천 방지·수정용) ──
  Future<void> _rememberMine(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final mine = prefs.getStringList('my_contribs') ?? [];
    if (!mine.contains(id)) {
      mine.add(id);
      await prefs.setStringList('my_contribs', mine);
    }
  }

  Future<Set<String>> myIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('my_contribs') ?? []).toSet();
  }

  // ── 내 제보 수정 (서버 RPC가 device_id 대조로 본인만 허용) ──
  Future<bool> updateOwn(UserPlace p) async {
    if (!ContribConfig.enabled) return false;
    final dev = await deviceId();
    final uri = Uri.parse('$_base/rpc/update_contribution');
    try {
      final res = await http
          .post(uri,
              headers: _headers,
              body: jsonEncode({
                'row_id': p.id,
                'dev': dev,
                'p_name': p.name,
                'p_note': p.note,
                'p_price': p.priceHint,
                'p_audience': p.audience,
                'p_lat': p.lat,
                'p_lng': p.lng,
                'p_city': p.city,
                'p_kind': p.kind,
              }))
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  // ── 내 제보 삭제 (본인만) ──
  Future<bool> deleteOwn(String id) async {
    if (!ContribConfig.enabled) return false;
    final dev = await deviceId();
    final uri = Uri.parse('$_base/rpc/delete_contribution');
    try {
      final res = await http
          .post(uri,
              headers: _headers,
              body: jsonEncode({'row_id': id, 'dev': dev}))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
        final prefs = await SharedPreferences.getInstance();
        final mine = prefs.getStringList('my_contribs') ?? [];
        mine.remove(id);
        await prefs.setStringList('my_contribs', mine);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ── '가봤어요' 추천 (서버 RPC로 원자적 증가) ──
  Future<bool> confirm(String id) async {
    if (!ContribConfig.enabled) return false;
    final prefs = await SharedPreferences.getInstance();
    final key = 'contrib_confirmed';
    final done = prefs.getStringList(key) ?? [];
    if (done.contains(id)) return false; // 이미 추천함
    final uri = Uri.parse('$_base/rpc/confirm_contribution');
    try {
      final res = await http
          .post(uri, headers: _headers, body: jsonEncode({'row_id': id}))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
        done.add(id);
        await prefs.setStringList(key, done);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> alreadyConfirmed(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('contrib_confirmed') ?? []).contains(id);
  }

  // ── 부적절 제보 신고 (누적 시 서버가 자동 숨김) ──
  Future<bool> report(String id) async {
    if (!ContribConfig.enabled) return false;
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getStringList('contrib_reported') ?? [];
    if (done.contains(id)) return false;
    final uri = Uri.parse('$_base/rpc/report_contribution');
    try {
      final res = await http
          .post(uri, headers: _headers, body: jsonEncode({'row_id': id}))
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 || res.statusCode == 204) {
        done.add(id);
        await prefs.setStringList('contrib_reported', done);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> alreadyReported(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList('contrib_reported') ?? []).contains(id);
  }

  // ── 스팸/홍보 필터 (등록 전, 즉시) ──
  /// 통과하면 null, 막히면 사유 문자열 반환.
  static String? spamReason(String name, String note) {
    final t = '$name $note'.toLowerCase();
    // URL·연락처·홍보 유입 차단
    final url = RegExp(r'(https?://|www\.|\.com|\.net|\.kr|@|카톡|카카오|텔레|010[-\s]?\d)');
    if (url.hasMatch(t)) {
      return '링크·연락처·SNS는 넣을 수 없어요(홍보 방지).';
    }
    const promo = ['홍보', '광고', '협찬', '할인코드', '쿠폰', '이벤트 참여', '구독', '팔로우'];
    if (promo.any((w) => t.contains(w))) {
      return '홍보성 표현은 등록할 수 없어요.';
    }
    if (name.trim().length < 2) return '상호(이름)를 2자 이상 적어주세요.';
    return null;
  }

  // ── 구글지도 링크/좌표에서 위경도 추출 ──
  /// "12.24,109.19", 또는 구글지도 URL(@lat,lng / !3d!4d / q=lat,lng),
  /// 또는 단축링크(goo.gl/maps.app)를 받아 좌표로 변환. 실패 시 null.
  static Future<(double, double)?> extractLatLng(String input) async {
    var s = input.trim();
    if (s.isEmpty) return null;

    // 1) "위도,경도" 직접 입력
    final plain =
        RegExp(r'^\s*(-?\d{1,2}\.\d+)\s*,\s*(-?\d{1,3}\.\d+)\s*$').firstMatch(s);
    if (plain != null) {
      return (double.parse(plain[1]!), double.parse(plain[2]!));
    }

    // 2) 단축링크면 실제 URL로 펼침
    if (s.contains('goo.gl') || s.contains('maps.app') || s.contains('naver.me')) {
      s = await _resolveRedirect(s) ?? s;
    }

    // 3) URL 안의 좌표 패턴들
    const patterns = [
      r'@(-?\d+\.\d+),(-?\d+\.\d+)',
      r'!3d(-?\d+\.\d+)!4d(-?\d+\.\d+)',
      r'[?&]q=(-?\d+\.\d+),(-?\d+\.\d+)',
      r'[?&]ll=(-?\d+\.\d+),(-?\d+\.\d+)',
      r'[?&]center=(-?\d+\.\d+),(-?\d+\.\d+)',
      r'/(-?\d+\.\d+),(-?\d+\.\d+)',
    ];
    for (final p in patterns) {
      final m = RegExp(p).firstMatch(s);
      if (m != null) {
        final la = double.tryParse(m[1]!);
        final lo = double.tryParse(m[2]!);
        if (la != null && lo != null && la.abs() <= 90 && lo.abs() <= 180) {
          return (la, lo);
        }
      }
    }
    return null;
  }

  // ── 이름으로 위치 찾기(무료 지오코딩, OpenStreetMap Nominatim) ──
  /// "{상호} {도시}"로 좌표를 찾아 (lat, lng, 표시이름) 반환. 실패 시 null.
  /// 결과 표시이름을 사용자에게 보여주고 확인시키는 용도(엉뚱하면 링크로 대체).
  static Future<(double, double, String)?> geocode(String query) async {
    final q = query.trim();
    if (q.isEmpty) return null;
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&limit=1&q=${Uri.encodeComponent(q)}');
    try {
      final res = await http.get(uri, headers: {
        'User-Agent': 'TravelMate-app/1.0 (traveler POI)'
      }).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return null;
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      final m = list.first as Map<String, dynamic>;
      final la = double.tryParse('${m['lat']}');
      final lo = double.tryParse('${m['lon']}');
      final label = (m['display_name'] as String?) ?? q;
      if (la == null || lo == null) return null;
      return (la, lo, label);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _resolveRedirect(String url) async {
    try {
      var current = Uri.parse(url);
      for (int i = 0; i < 6; i++) {
        final req = http.Request('GET', current)..followRedirects = false;
        final res =
            await http.Client().send(req).timeout(const Duration(seconds: 8));
        final loc = res.headers['location'];
        if (loc == null) return current.toString();
        final next = Uri.parse(loc);
        current = next.hasScheme ? next : current.resolve(loc);
      }
      return current.toString();
    } catch (_) {
      return null;
    }
  }

  // ── 기기당 하루 제보 수 제한 ──
  Future<bool> canSubmitToday() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final used = prefs.getInt('contrib_submits_$today') ?? 0;
    return used < ContribConfig.dailySubmitLimit;
  }

  Future<void> _recordSubmit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayKey();
    final k = 'contrib_submits_$today';
    await prefs.setInt(k, (prefs.getInt(k) ?? 0) + 1);
  }

  String _todayKey() {
    final n = DateTime.now();
    return '${n.year}${n.month.toString().padLeft(2, '0')}${n.day.toString().padLeft(2, '0')}';
  }
}
