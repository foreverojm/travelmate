import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/country_data.dart';
import '../../core/models.dart';
import 'rate_service.dart';

/// 환율 계산기 상태.
/// 입력은 항상 "위쪽(from) 통화 기준 금액"으로 관리하고,
/// 아래(to) 값은 파생 계산한다. 스왑하면 두 통화만 바꾼다.
class CurrencyProvider extends ChangeNotifier {
  final RateService _service;
  CurrencyProvider(this._service);

  RateSnapshot? _snapshot;
  bool _refreshing = false;

  // 기본: 현지통화 → 원화 (여행자가 "이거 원화로 얼마?"를 가장 많이 봄)
  Currency _from = countries.first.currency; // VND
  Currency _to = krw;

  // from 통화 기준 입력 금액(문자열로 관리해 소수점/선행 0 자연스럽게)
  String _input = '10000';

  static const _kFromKey = 'cur_from_v1';
  static const _kToKey = 'cur_to_v1';
  static const _kVisibleKey = 'cur_visible_v1';

  // 동시환산에 표시할 통화(여행지별로 필요한 것만). 기본 전체.
  Set<String> _visible = allCurrencies.map((c) => c.code).toSet();

  Currency get from => _from;
  Currency get to => _to;
  String get input => _input;
  bool get refreshing => _refreshing;
  RateSnapshot? get snapshot => _snapshot;

  /// 표시로 선택된 통화(allCurrencies 순서 유지)
  List<Currency> get visibleCurrencies =>
      allCurrencies.where((c) => _visible.contains(c.code)).toList();
  bool isVisible(String code) => _visible.contains(code);

  /// 통화 표시 on/off (KRW는 기준이라 항상 표시)
  void toggleVisible(String code) {
    if (code == 'KRW') return;
    if (_visible.contains(code)) {
      _visible.remove(code);
    } else {
      _visible.add(code);
    }
    _persistVisible();
    notifyListeners();
  }

  /// 여행지 프리셋: 원·달러 + 해당 통화들만
  void applyVisiblePreset(Set<String> codes) {
    _visible = {'KRW', ...codes};
    _persistVisible();
    notifyListeners();
  }

  DateTime? get updatedAt => _snapshot?.updatedAt;
  bool get isLive => _snapshot?.isLive ?? false;
  bool get hasEverUpdated =>
      (_snapshot?.updatedAt.millisecondsSinceEpoch ?? 0) > 0;

  /// 앱 시작: 캐시/시드 즉시 표시 → 백그라운드로 온라인 갱신
  Future<void> init() async {
    _snapshot = await _service.loadCachedOrSeed();
    await _restoreSelection();
    notifyListeners();
    refresh(); // await 안 함: 화면은 먼저 뜨고 조용히 갱신
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    final fresh = await _service.fetchLatest();
    if (fresh != null) _snapshot = fresh;
    _refreshing = false;
    notifyListeners();
  }

  // ── 통화 선택 ─────────────────────────────
  void setFrom(Currency c) {
    if (c.code == _to.code) {
      // 같은 통화 선택 시 자동 스왑되도록
      _to = _from;
    }
    _from = c;
    _persistSelection();
    notifyListeners();
  }

  void setTo(Currency c) {
    if (c.code == _from.code) {
      _from = _to;
    }
    _to = c;
    _persistSelection();
    notifyListeners();
  }

  void swap() {
    final t = _from;
    _from = _to;
    _to = t;
    _persistSelection();
    notifyListeners();
  }

  // ── 숫자패드 입력 ─────────────────────────
  void tapDigit(String d) {
    if (_input == '0') {
      _input = d;
    } else {
      if (_input.replaceAll('.', '').length >= 12) return; // 과도한 자릿수 방지
      _input += d;
    }
    notifyListeners();
  }

  void tapDot() {
    if (!_input.contains('.')) {
      _input += '.';
      notifyListeners();
    }
  }

  void backspace() {
    if (_input.isNotEmpty) {
      _input = _input.substring(0, _input.length - 1);
      if (_input.isEmpty || _input == '.') _input = '0';
      notifyListeners();
    }
  }

  void clear() {
    _input = '0';
    notifyListeners();
  }

  /// 권종 치트시트 등에서 특정 금액을 바로 세팅
  void setAmount(num amount) {
    _input = amount == amount.roundToDouble()
        ? amount.toInt().toString()
        : amount.toString();
    notifyListeners();
  }

  // ── 변환 계산 ─────────────────────────────
  double get fromAmount => double.tryParse(_input) ?? 0;

  /// from → to 환산 결과
  double get convertedAmount {
    final rates = _snapshot?.ratesPerKrw ?? seedRatesPerKrw;
    final rFrom = rates[_from.code] ?? 1; // 1 KRW 당 from
    final rTo = rates[_to.code] ?? 1; // 1 KRW 당 to
    if (rFrom == 0) return 0;
    // from → KRW → to
    final krwValue = fromAmount / rFrom;
    return krwValue * rTo;
  }

  /// 입력 금액(from 기준)을 임의 통화로 환산 — '동시 환산' 패널용
  double amountInCurrency(Currency c) {
    final rates = _snapshot?.ratesPerKrw ?? seedRatesPerKrw;
    final rFrom = rates[_from.code] ?? 1;
    final rTo = rates[c.code] ?? 1;
    if (rFrom == 0) return 0;
    return (fromAmount / rFrom) * rTo;
  }

  /// 1 from = ? to (표시용 단가)
  double get unitRate {
    final rates = _snapshot?.ratesPerKrw ?? seedRatesPerKrw;
    final rFrom = rates[_from.code] ?? 1;
    final rTo = rates[_to.code] ?? 1;
    if (rFrom == 0) return 0;
    return rTo / rFrom;
  }

  Future<void> _restoreSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final f = prefs.getString(_kFromKey);
    final t = prefs.getString(_kToKey);
    if (f != null) _from = currencyByCode(f);
    if (t != null) _to = currencyByCode(t);
    final v = prefs.getStringList(_kVisibleKey);
    if (v != null && v.isNotEmpty) _visible = {'KRW', ...v};
  }

  Future<void> _persistSelection() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kFromKey, _from.code);
    await prefs.setString(_kToKey, _to.code);
  }

  Future<void> _persistVisible() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_kVisibleKey, _visible.toList());
  }
}
