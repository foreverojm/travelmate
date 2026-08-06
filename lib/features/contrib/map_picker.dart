import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';
import 'contrib_service.dart';

/// 제보 위치를 지도에서 고르는 화면.
/// OpenStreetMap 타일 사용(API 키·과금 없음). 선택 좌표를 (lat,lng)로 반환.
/// 손으로 찾아가 찍는 것 말고 이름으로 검색해 바로 이동할 수 있다(Nominatim).
class MapPicker extends StatefulWidget {
  final double centerLat;
  final double centerLng;
  final double? initialLat;
  final double? initialLng;
  const MapPicker({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  final _map = MapController();
  final _queryCtrl = TextEditingController();
  final _queryFocus = FocusNode();

  LatLng? _picked;
  List<({double lat, double lng, String label})> _hits = const [];
  bool _searching = false;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _queryCtrl.text.trim();
    if (q.isEmpty || _searching) return;
    _queryFocus.unfocus();
    setState(() {
      _searching = true;
      _searched = true;
    });
    final hits = await ContribService.searchPlaces(
      q,
      nearLat: widget.centerLat,
      nearLng: widget.centerLng,
    );
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _searching = false;
    });
  }

  void _goTo(({double lat, double lng, String label}) hit) {
    final ll = LatLng(hit.lat, hit.lng);
    setState(() {
      _picked = ll;
      _hits = const [];
      _searched = false;
    });
    _map.move(ll, 17);
  }

  void _zoom(double delta) {
    final z = (_map.camera.zoom + delta).clamp(2.0, 19.0);
    _map.move(_map.camera.center, z);
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? LatLng(widget.centerLat, widget.centerLng);
    return Scaffold(
      appBar: AppBar(title: const Text('지도에서 위치 선택')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onTap: (_, ll) => setState(() {
                _picked = ll;
                _hits = const [];
                _searched = false;
              }),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jesoft.travelmate',
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          color: AppColors.danger, size: 44),
                    ),
                  ],
                ),
            ],
          ),

          // 검색창 + 결과
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(10),
                  child: TextField(
                    controller: _queryCtrl,
                    focusNode: _queryFocus,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: '가게·건물 이름이나 주소로 검색',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2.2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.arrow_forward),
                              onPressed: _search,
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    ),
                  ),
                ),
                if (_hits.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _hits.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final h = _hits[i];
                        final parts = h.label.split(',');
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 20),
                          title: Text(parts.first.trim(),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            parts.length > 1
                                ? parts.skip(1).join(',').trim()
                                : '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11.5),
                          ),
                          onTap: () => _goTo(h),
                        );
                      },
                    ),
                  )
                else if (_searched && !_searching)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6),
                      ],
                    ),
                    child: const Text(
                      '검색 결과가 없습니다. 지도를 직접 탭해서 핀을 놓아도 됩니다.',
                      style: TextStyle(fontSize: 12.5),
                    ),
                  ),
              ],
            ),
          ),

          // 확대/축소
          Positioned(
            right: 12,
            bottom: 16,
            child: Column(
              children: [
                _ZoomButton(icon: Icons.add, onTap: () => _zoom(1)),
                const SizedBox(height: 8),
                _ZoomButton(icon: Icons.remove, onTap: () => _zoom(-1)),
              ],
            ),
          ),

          // 하단 안내
          Positioned(
            left: 12,
            bottom: 16,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '검색하거나, 지도를 탭해 핀을 놓으세요',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed:
                _picked == null ? null : () => Navigator.pop(context, _picked),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              _picked == null ? '검색하거나 지도를 탭해 위치를 고르세요' : '이 위치로 선택',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 22, color: AppColors.ink),
        ),
      ),
    );
  }
}
