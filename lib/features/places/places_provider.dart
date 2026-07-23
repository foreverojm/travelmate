import 'package:flutter/foundation.dart';
import 'place_data.dart';
import 'places_repository.dart';

/// OSM 장소 로딩 상태. 큐레이션(seedPlaces)과 합쳐 화면에 노출.
class PlacesProvider extends ChangeNotifier {
  final PlacesRepository _repo;
  PlacesProvider(this._repo);

  List<Place> _osm = const [];
  DateTime? _updatedAt;
  bool _refreshing = false;

  /// 큐레이션 + OSM 합본
  List<Place> get all => [...seedPlaces, ..._osm];
  int get osmCount => _osm.length;
  DateTime? get updatedAt => _updatedAt;
  bool get refreshing => _refreshing;
  bool get hasRemote => _repo.hasRemote;

  Future<void> init() async {
    final data = await _repo.loadInitial();
    _osm = data.places;
    _updatedAt = data.generatedAt;
    notifyListeners();
    refresh(); // 백그라운드 원격 갱신 (await 안 함)
  }

  /// 수동/당겨서 새로고침. 원격에서 최신 데이터를 받아온다.
  Future<void> refresh() async {
    if (_refreshing) return;
    _refreshing = true;
    notifyListeners();
    final data = await _repo.fetchRemote();
    if (data != null && !data.isEmpty) {
      _osm = data.places;
      _updatedAt = data.generatedAt ?? _updatedAt;
    }
    _refreshing = false;
    notifyListeners();
  }
}
