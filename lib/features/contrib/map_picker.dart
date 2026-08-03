import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme.dart';

/// 제보 위치를 지도에서 탭해 고르는 화면.
/// OpenStreetMap 타일 사용(API 키 불필요). 선택 좌표를 (lat,lng)로 반환.
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
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _picked = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = _picked ?? LatLng(widget.centerLat, widget.centerLng);
    return Scaffold(
      appBar: AppBar(title: const Text('지도에서 위치 선택')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              onTap: (_, ll) => setState(() => _picked = ll),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
          // 상단 안내
          Positioned(
            top: 10,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '장소를 손가락으로 탭해서 핀을 놓으세요. 확대/이동해 정확히 맞춘 뒤 아래 버튼을 누르세요.',
                style: TextStyle(color: Colors.white, fontSize: 12.5, height: 1.4),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _picked == null
                ? null
                : () => Navigator.pop(context, _picked),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
              _picked == null ? '지도를 탭해 위치를 고르세요' : '이 위치로 선택',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
