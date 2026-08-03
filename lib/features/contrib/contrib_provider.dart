import 'package:flutter/foundation.dart';
import 'contrib_config.dart';
import 'contrib_service.dart';
import 'user_place.dart';

/// 여행자 제보 상태. 맛집·명소 목록에 합쳐 노출한다.
class ContribProvider extends ChangeNotifier {
  final ContribService _svc;
  ContribProvider(this._svc);

  List<UserPlace> _items = const [];
  Set<String> _mine = {};
  bool _loading = false;

  List<UserPlace> get all => _items;
  Set<String> get mine => _mine; // 내가 올린 제보 id
  bool isMine(String id) => _mine.contains(id);
  bool get loading => _loading;
  bool get enabled => ContribConfig.enabled;

  Future<void> init() async {
    if (!ContribConfig.enabled) return;
    _mine = await _svc.myIds();
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

  /// 제보 등록 → 성공 시 목록 갱신. 내 제보로 기억.
  Future<bool> submit(UserPlace p) async {
    final id = await _svc.submit(p);
    if (id == null) return false;
    if (id.isNotEmpty) _mine.add(id);
    await refresh();
    return true;
  }

  /// '가봤어요' 추천 → 성공 시 갱신.
  Future<bool> confirm(String id) async {
    final ok = await _svc.confirm(id);
    if (ok) await refresh();
    return ok;
  }

  /// 내 제보 수정.
  Future<bool> updateOwn(UserPlace p) async {
    final ok = await _svc.updateOwn(p);
    if (ok) await refresh();
    return ok;
  }

  /// 내 제보 삭제.
  Future<bool> deleteOwn(String id) async {
    final ok = await _svc.deleteOwn(id);
    if (ok) {
      _mine.remove(id);
      await refresh();
    }
    return ok;
  }

  Future<bool> alreadyConfirmed(String id) => _svc.alreadyConfirmed(id);
  Future<bool> canSubmitToday() => _svc.canSubmitToday();
}
