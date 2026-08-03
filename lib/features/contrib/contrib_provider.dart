import 'package:flutter/foundation.dart';
import 'contrib_config.dart';
import 'contrib_service.dart';
import 'user_place.dart';

/// 여행자 제보 상태. 맛집·명소 목록에 합쳐 노출한다.
class ContribProvider extends ChangeNotifier {
  final ContribService _svc;
  ContribProvider(this._svc);

  List<UserPlace> _items = const [];
  bool _loading = false;

  List<UserPlace> get all => _items;
  bool get loading => _loading;
  bool get enabled => ContribConfig.enabled;

  Future<void> init() async {
    if (!ContribConfig.enabled) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (!ContribConfig.enabled || _loading) return;
    _loading = true;
    notifyListeners();
    _items = await _svc.fetchAll();
    _loading = false;
    notifyListeners();
  }

  /// 제보 등록 → 성공 시 목록 갱신.
  Future<bool> submit(UserPlace p) async {
    final ok = await _svc.submit(p);
    if (ok) await refresh();
    return ok;
  }

  /// '가봤어요' 추천 → 성공 시 갱신.
  Future<bool> confirm(String id) async {
    final ok = await _svc.confirm(id);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> alreadyConfirmed(String id) => _svc.alreadyConfirmed(id);
  Future<bool> canSubmitToday() => _svc.canSubmitToday();
}
