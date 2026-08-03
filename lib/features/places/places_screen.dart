import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/format.dart';
import '../../core/launcher.dart';
import '../../core/models.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import '../prices/prices_view.dart';
import 'place_data.dart';
import 'places_provider.dart';

/// 맛집·명소 탭. 나라를 고르고 '관광객 / 현지인' + '맛집 / 명소'로 걸러 본다.
/// 상단 토글로 '쇼핑·시세'(관광객 구매 품목·음식 로컬 물가)로 전환할 수 있다.
class PlacesScreen extends StatefulWidget {
  const PlacesScreen({super.key});

  @override
  State<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends State<PlacesScreen> {
  Country _country = countries.first;
  String? _city; // null = 전체 도시
  Audience? _audience; // null = 전체
  PlaceKind? _kind; // null = 전체
  bool _showPrices = false; // false=맛집·명소, true=쇼핑·시세

  void _selectCountry(Country c) {
    setState(() {
      _country = c;
      _city = null; // 나라 바꾸면 도시 필터 초기화
    });
  }

  @override
  Widget build(BuildContext context) {
    final cities = citiesByCountry[_country.code] ?? const [];
    final pp = context.watch<PlacesProvider>();
    final list = pp.all.where((p) {
      if (p.countryCode != _country.code) return false;
      if (_city != null && p.city != _city) return false;
      if (_audience != null && p.audience != _audience) return false;
      if (_kind != null && p.kind != _kind) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('맛집 · 명소 · 시세')),
      body: Column(
        children: [
          _ModeToggle(
            showPrices: _showPrices,
            onChanged: (v) => setState(() => _showPrices = v),
          ),
          if (!_showPrices) _DataBar(p: pp),
          const SizedBox(height: 8),
          _CountryRow(selected: _country, onChanged: _selectCountry),
          const SizedBox(height: 8),
          // 도시 필터
          _CityRow(
            cities: cities,
            selected: _city,
            onChanged: (c) => setState(() => _city = c),
          ),
          if (!_showPrices) ...[
            const SizedBox(height: 8),
            _FilterRow(
              audience: _audience,
              kind: _kind,
              onAudience: (a) => setState(() => _audience = a),
              onKind: (k) => setState(() => _kind = k),
            ),
          ],
          const SizedBox(height: 4),
          Expanded(
            child: _showPrices
                ? PricesView(countryCode: _country.code, city: _city)
                : RefreshIndicator(
                    onRefresh: () => context.read<PlacesProvider>().refresh(),
                    child: list.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              _Empty(),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) => _PlaceCard(place: list[i]),
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// 맛집·명소 ↔ 쇼핑·시세 전환 토글.
class _ModeToggle extends StatelessWidget {
  final bool showPrices;
  final ValueChanged<bool> onChanged;
  const _ModeToggle({required this.showPrices, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Expanded(child: _seg('맛집 · 명소', Icons.restaurant, !showPrices, () => onChanged(false))),
          const SizedBox(width: 8),
          Expanded(child: _seg('쇼핑 · 시세', Icons.sell_outlined, showPrices, () => onChanged(true))),
        ],
      ),
    );
  }

  Widget _seg(String label, IconData icon, bool active, VoidCallback onTap) {
    return Material(
      color: active ? AppColors.primary : AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 17,
                  color: active ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 도시 필터 (전체 + 나라별 주요 도시)
class _CityRow extends StatelessWidget {
  final List<String> cities;
  final String? selected;
  final ValueChanged<String?> onChanged;
  const _CityRow(
      {required this.cities, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cities.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return SelectPill(
              label: '전체',
              selected: selected == null,
              onTap: () => onChanged(null),
            );
          }
          final city = cities[i - 1];
          return SelectPill(
            label: city,
            selected: selected == city,
            onTap: () => onChanged(city),
          );
        },
      ),
    );
  }
}

/// 최근 업데이트 시각 + 새로고침. (아래로 당겨서도 새로고침 가능)
class _DataBar extends StatelessWidget {
  final PlacesProvider p;
  const _DataBar({required this.p});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final when = p.updatedAt != null
        ? '최근 업데이트 ${Fmt.relativeTime(p.updatedAt!, now)}'
        : '주요 도시 큐레이션 · 당겨서 새로고침';
    return Container(
      width: double.infinity,
      color: AppColors.surfaceAlt,
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(when,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
          if (p.refreshing)
            const Padding(
              padding: EdgeInsets.all(8),
              child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            IconButton(
              visualDensity: VisualDensity.compact,
              iconSize: 18,
              color: AppColors.primary,
              tooltip: '새로고침',
              onPressed: p.refresh,
              icon: const Icon(Icons.refresh),
            ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  final Country selected;
  final ValueChanged<Country> onChanged;
  const _CountryRow({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: countries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = countries[i];
          return SelectPill(
            label: c.nameKo,
            selected: c.code == selected.code,
            leading: CountryFlag(code: c.code, height: 15),
            onTap: () => onChanged(c),
          );
        },
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  final Audience? audience;
  final PlaceKind? kind;
  final ValueChanged<Audience?> onAudience;
  final ValueChanged<PlaceKind?> onKind;
  const _FilterRow({
    required this.audience,
    required this.kind,
    required this.onAudience,
    required this.onKind,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _chip('현지인', audience == Audience.local,
              () => onAudience(audience == Audience.local ? null : Audience.local)),
          const SizedBox(width: 8),
          _chip('관광객', audience == Audience.tourist,
              () => onAudience(audience == Audience.tourist ? null : Audience.tourist)),
          const SizedBox(width: 16),
          _chip('맛집', kind == PlaceKind.food,
              () => onKind(kind == PlaceKind.food ? null : PlaceKind.food)),
          const SizedBox(width: 8),
          _chip('명소', kind == PlaceKind.sight,
              () => onKind(kind == PlaceKind.sight ? null : PlaceKind.sight)),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return SelectPill(
      label: label,
      selected: selected,
      activeColor: AppColors.accent,
      onTap: onTap,
    );
  }
}

class _PlaceCard extends StatelessWidget {
  final Place place;
  const _PlaceCard({required this.place});

  @override
  Widget build(BuildContext context) {
    final aud = place.audience;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // 현지인/관광객 배지 (큐레이션분만)
                if (aud != null)
                  _Tag(
                    text: aud == Audience.local ? '현지인' : '관광객',
                    color: aud == Audience.local
                        ? AppColors.success
                        : AppColors.primary,
                  )
                else if (place.source == PlaceSource.wikivoyage)
                  const _Tag(
                    text: '여행가이드',
                    color: AppColors.accent,
                    outlined: true,
                  )
                else
                  const _Tag(
                    text: '지도 정보',
                    color: AppColors.textMuted,
                    outlined: true,
                  ),
                const SizedBox(width: 6),
                _Tag(
                  text: place.kind == PlaceKind.food ? '맛집' : '명소',
                  color: AppColors.textMuted,
                  outlined: true,
                ),
                const Spacer(),
                Text(place.city,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            Text(place.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(place.note,
                style: const TextStyle(color: AppColors.ink, height: 1.4)),
            const SizedBox(height: 10),
            Row(
              children: [
                if (place.priceHint.isNotEmpty) ...[
                  const Icon(Icons.payments_outlined,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(place.priceHint,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
                const Spacer(),
                // 좌표 있으면 정확한 위치, 없으면 이름+도시로 지도 검색
                TextButton.icon(
                  onPressed: () {
                    if (place.lat != null && place.lng != null) {
                      AppLauncher.openMap(
                          context, place.lat!, place.lng!, place.name);
                    } else {
                      AppLauncher.openMapSearch(
                          context, '${place.name} ${place.city}');
                    }
                  },
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text(
                      place.lat != null && place.lng != null ? '지도' : '지도 검색'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  final bool outlined;
  const _Tag({required this.text, required this.color, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: outlined ? AppColors.line : Colors.transparent),
      ),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('조건에 맞는 장소가 아직 없어요',
          style: TextStyle(color: AppColors.textMuted)),
    );
  }
}
