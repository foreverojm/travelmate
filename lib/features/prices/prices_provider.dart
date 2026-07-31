import 'package:flutter/foundation.dart';
import 'price_data.dart';
import 'prices_repository.dart';

/// 물품 시세 로딩 상태. 맛집·명소와 동일한 오프라인 우선 + 원격 갱신.
class PricesProvider extends ChangeNotifier {
  final PricesRepository _repo;
  PricesProvider(this._repo);

  List<PriceItem> _items = const [];
  DateTime? _updatedAt;
  String _source = '';
  bool _refreshing = false;

  List<PriceItem> get all => _items;
  DateTime? get updatedAt => _updatedAt;
  String get source => _source;
  bool get refreshing => _refreshing;
  bool get hasRemote => _repo.hasRemote;

  Future<void> init() async {
    final data = await _repo.loadInitial();
    _items = data.items;
    _updatedAt = data.generatedAt;
    _source = data.source;
    notifyListeners();
    refresh(); // 백그라운드 원격 갱신
  }

  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    final data = await _repo.fetchRemote();
    if (data != null && !data.isEmpty) {
      _items = data.items;
      _updatedAt = data.generatedAt ?? _updatedAt;
      _source = data.source;
    }
    _refreshing = false;
    notifyListeners();
  }
}
