import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import '../places/place_data.dart';
import 'contrib_provider.dart';
import 'contrib_service.dart';
import 'map_picker.dart';
import 'user_place.dart';

/// 여행자 제보 폼. 별점이 아니라 "직접 가봤다 + 다른 여행자 추천"으로 신뢰를 쌓는다.
class ContribForm extends StatefulWidget {
  final String initialCountry;
  const ContribForm({super.key, required this.initialCountry});

  @override
  State<ContribForm> createState() => _ContribFormState();
}

class _ContribFormState extends State<ContribForm> {
  late String _cc = widget.initialCountry;
  String? _city;
  String _kind = 'food';
  String? _audience; // 'local' | 'tourist' | null
  bool _visited = false;
  bool _submitting = false;
  (double, double)? _coords; // 지정된 위치
  String? _coordLabel; // 위치 출처 표시

  final _name = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _loc = TextEditingController();
  final _cityCtrl = TextEditingController();
  bool _customCity = false; // 목록에 없는 새 도시 직접 입력

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _note.dispose();
    _loc.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    if (_city == null) return _toast('도시를 선택해 주세요.');
    if (name.length < 2) return _toast('상호(이름)를 2자 이상 적어주세요.');
    if (!_visited) return _toast('“직접 가봤어요”를 체크해 주세요.');

    final spam = ContribService.spamReason(name, _note.text);
    if (spam != null) return _toast(spam);

    final prov = context.read<ContribProvider>();
    if (!await prov.canSubmitToday()) {
      return _toast('오늘 제보 한도를 초과했어요. 내일 다시 부탁드려요.');
    }

    setState(() => _submitting = true);

    // 위치: 지도에서 찍은 좌표 우선, 없으면 붙여넣은 링크/좌표에서 추출
    (double, double)? coords = _coords;
    final locText = _loc.text.trim();
    if (coords == null && locText.isNotEmpty) {
      coords = await ContribService.extractLatLng(locText);
    }

    final ok = await prov.submit(UserPlace(
      id: '',
      countryCode: _cc,
      city: _city!,
      name: name,
      kind: _kind,
      audience: _audience,
      priceHint: _price.text.trim(),
      note: _note.text.trim(),
      lat: coords?.$1,
      lng: coords?.$2,
    ));
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _toast(locText.isNotEmpty && coords == null
          ? '등록됐어요. 다만 위치 링크를 못 읽어 지도는 이름으로 검색돼요.'
          : '제보 감사합니다! 다른 여행자의 “가봤어요”로 검증돼요.');
      Navigator.pop(context);
    } else {
      _toast('등록에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  static const _countryCenters = {
    'VN': [16.0, 107.9],
    'JP': [36.2, 138.2],
    'TW': [23.7, 121.0],
    'TH': [13.7, 100.9],
  };
  static const _countryEn = {
    'VN': 'Vietnam',
    'JP': 'Japan',
    'TW': 'Taiwan',
    'TH': 'Thailand',
  };

  Future<void> _openMap() async {
    if (_city == null) return _toast('먼저 도시를 선택하거나 입력해 주세요.');
    List<double> c = cityCenters[_city!] ?? const [];
    if (c.isEmpty) {
      // 목록에 없는 새 도시: 이름으로 중심 추정
      final g =
          await ContribService.geocode('${_city!} ${_countryEn[_cc] ?? ''}');
      c = g != null
          ? [g.$1, g.$2]
          : (_countryCenters[_cc] ?? const [13.7563, 100.5018]);
    }
    if (!mounted) return;
    final res = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPicker(
          centerLat: c[0],
          centerLng: c[1],
          initialLat: _coords?.$1,
          initialLng: _coords?.$2,
        ),
      ),
    );
    if (res != null) {
      setState(() {
        _coords = (res.latitude, res.longitude);
        _coordLabel = '지도에서 선택';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = citiesByCountry[_cc] ?? const [];
    return Scaffold(
      appBar: AppBar(title: const Text('찐 맛집·명소 제보')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _intro(),
          const SizedBox(height: 16),
          _label('나라'),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: countries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = countries[i];
                return SelectPill(
                  label: c.nameKo,
                  selected: c.code == _cc,
                  leading: CountryFlag(code: c.code, height: 15),
                  onTap: () => setState(() {
                    _cc = c.code;
                    _city = null;
                    _customCity = false;
                    _cityCtrl.clear();
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _label('도시'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in cities)
                SelectPill(
                  label: city,
                  selected: !_customCity && _city == city,
                  onTap: () => setState(() {
                    _customCity = false;
                    _cityCtrl.clear();
                    _city = city;
                  }),
                ),
              SelectPill(
                label: _customCity ? '✎ 새 도시' : '＋ 다른 도시',
                selected: _customCity,
                onTap: () => setState(() {
                  _customCity = true;
                  _city = _cityCtrl.text.trim().isEmpty
                      ? null
                      : _cityCtrl.text.trim();
                }),
              ),
            ],
          ),
          if (_customCity) ...[
            const SizedBox(height: 8),
            _field(_cityCtrl, '도시 이름 (예: 달랏, 붕따우, 사파)',
                onChanged: (v) =>
                    setState(() => _city = v.trim().isEmpty ? null : v.trim())),
            const Padding(
              padding: EdgeInsets.only(top: 6, left: 2),
              child: Text('목록에 없는 도시도 직접 적어 공유할 수 있어요. 다른 여행자도 필터에서 보게 됩니다.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted, height: 1.4)),
            ),
          ],
          const SizedBox(height: 14),
          _label('종류'),
          Row(
            children: [
              _seg('맛집', _kind == 'food', () => setState(() => _kind = 'food')),
              const SizedBox(width: 8),
              _seg('명소', _kind == 'sight', () => setState(() => _kind = 'sight')),
            ],
          ),
          const SizedBox(height: 14),
          _label('상호 (이름)'),
          _field(_name, '예: 넴느엉 담반쿠옌'),
          const SizedBox(height: 14),
          _label('위치 (정확한 지도용)'),
          OutlinedButton.icon(
            onPressed: _openMap,
            icon: const Icon(Icons.map_outlined, size: 18),
            label: Text(_coords == null ? '지도에서 위치 선택' : '위치 다시 선택'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
            ),
          ),
          if (_coords != null)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '위치 지정됨 (${_coordLabel ?? ''}) '
                      '${_coords!.$1.toStringAsFixed(4)}, ${_coords!.$2.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() {
                      _coords = null;
                      _coordLabel = null;
                    }),
                    child: const Icon(Icons.close,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          _field(_loc, '또는 구글지도 링크/좌표 붙여넣기'),
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 2),
            child: Text(
              '지도를 눌러 핀을 놓거나, 구글지도 → 공유 → «링크 복사»를 붙여넣어도 됩니다.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
          ),
          const SizedBox(height: 14),
          _label('누가 가는 곳인가요? (선택)'),
          Row(
            children: [
              _seg('현지인', _audience == 'local',
                  () => setState(() => _audience = _audience == 'local' ? null : 'local'),
                  color: AppColors.success),
              const SizedBox(width: 8),
              _seg('관광객', _audience == 'tourist',
                  () => setState(() => _audience = _audience == 'tourist' ? null : 'tourist'),
                  color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 14),
          _label('가격대 (선택)'),
          _field(_price, '예: ₫ 3~5만 / ฿ 60~80'),
          const SizedBox(height: 14),
          _label('한줄평 (선택)'),
          _field(_note, '예: 현지인이 아침에 줄 서는 쌀국수 노포', maxLines: 3),
          const SizedBox(height: 16),
          // 필수: 직접 가봤음
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _visited = !_visited),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _visited
                    ? AppColors.success.withValues(alpha: 0.10)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _visited ? AppColors.success : AppColors.line),
              ),
              child: Row(
                children: [
                  Icon(_visited ? Icons.check_circle : Icons.circle_outlined,
                      color: _visited ? AppColors.success : AppColors.textMuted),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('직접 가봤어요 (필수)',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(_submitting ? '등록 중…' : '제보 등록',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          '별점을 위한 홍보가 아니라, 이 앱을 쓰는 여행자에게 나누는 «찐 정보»예요. '
          '직접 가본 곳만 올려주세요. 링크·연락처·홍보는 자동 차단되고, '
          '다른 여행자의 “가봤어요”가 쌓이면 «검증됨»으로 승격됩니다.',
          style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.ink),
        ),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      );

  Widget _field(TextEditingController c, String hint,
          {int maxLines = 1, ValueChanged<String>? onChanged}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );

  Widget _seg(String label, bool active, VoidCallback onTap,
      {Color color = AppColors.primary}) {
    return Expanded(
      child: Material(
        color: active ? color : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(label,
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textMuted)),
            ),
          ),
        ),
      ),
    );
  }
}
