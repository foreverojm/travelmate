import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/format.dart';
import '../../core/launcher.dart';
import '../../core/models.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import '../contrib/contrib_form.dart';
import '../contrib/contrib_provider.dart';
import '../contrib/user_place.dart';
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
    final pp = context.watch<PlacesProvider>();
    final cp = context.watch<ContribProvider>();
    // 기본 도시 + 사용자가 제보로 추가한 새 도시
    final baseCities = citiesByCountry[_country.code] ?? const <String>[];
    final extraCities = cp.all
        .where((u) =>
            u.countryCode == _country.code &&
            u.city.isNotEmpty &&
            !baseCities.contains(u.city))
        .map((u) => u.city)
        .toSet()
        .toList()
      ..sort();
    final cities = [...baseCities, ...extraCities];
    final list = pp.all.where((p) {
      if (p.countryCode != _country.code) return false;
      if (_city != null && p.city != _city) return false;
      if (_audience != null && p.audience != _audience) return false;
      if (_kind != null && p.kind != _kind) return false;
      return true;
    }).toList();
    // 여행자 제보(커뮤니티) — 같은 필터 적용
    final contribs = cp.all.where((u) {
      if (u.countryCode != _country.code) return false;
      if (_city != null && u.city != _city) return false;
      if (_kind != null && u.kind != _kind!.name) return false;
      if (_audience != null && u.audience != _audience!.name) return false;
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
                    onRefresh: () async {
                      final placesP = context.read<PlacesProvider>();
                      final contribP = context.read<ContribProvider>();
                      await placesP.refresh();
                      await contribP.refresh();
                    },
                    child: (list.isEmpty && contribs.isEmpty)
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 120),
                              _Empty(),
                            ],
                          )
                        : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            children: [
                              if (contribs.isNotEmpty) ...[
                                const _SectionLabel('여행자 제보 · 찐 정보'),
                                const SizedBox(height: 8),
                                for (final u in contribs) ...[
                                  _ContribCard(place: u),
                                  const SizedBox(height: 10),
                                ],
                                const SizedBox(height: 6),
                                const _SectionLabel('가이드 · 지도'),
                                const SizedBox(height: 8),
                              ],
                              for (int i = 0; i < list.length; i++) ...[
                                _PlaceCard(place: list[i]),
                                if (i != list.length - 1)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
                  ),
          ),
        ],
      ),
      floatingActionButton: (cp.enabled && !_showPrices)
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ContribForm(initialCountry: _country.code),
              )),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('제보'),
            )
          : null,
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted));
}

/// 여행자 제보 카드. 별점이 아니라 '가봤어요' 수로 신뢰가 쌓인다.
class _ContribCard extends StatefulWidget {
  final UserPlace place;
  const _ContribCard({required this.place});

  @override
  State<_ContribCard> createState() => _ContribCardState();
}

class _ContribCardState extends State<_ContribCard> {
  bool _confirmed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context
        .read<ContribProvider>()
        .alreadyConfirmed(widget.place.id)
        .then((v) {
      if (mounted) setState(() => _confirmed = v);
    });
  }

  Future<void> _confirm() async {
    if (_confirmed || _busy) return;
    final prov = context.read<ContribProvider>();
    setState(() => _busy = true);
    final ok = await prov.confirm(widget.place.id);
    if (mounted) setState(() { _busy = false; _confirmed = ok || _confirmed; });
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.place;
    final aud = u.audience;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Tag(
                  text: u.isVerified ? '검증됨' : '미검증',
                  color: u.isVerified ? AppColors.success : AppColors.textMuted,
                ),
                const SizedBox(width: 6),
                if (aud != null)
                  _Tag(
                    text: aud == 'local' ? '현지인' : '관광객',
                    color: aud == 'local'
                        ? AppColors.success
                        : AppColors.primary,
                    outlined: true,
                  ),
                const SizedBox(width: 6),
                _Tag(
                  text: u.kind == 'food' ? '맛집' : '명소',
                  color: AppColors.textMuted,
                  outlined: true,
                ),
                const Spacer(),
                Text('여행자 제보',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 8),
            Text(u.name,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            if (u.note.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(u.note,
                  style: const TextStyle(color: AppColors.ink, height: 1.4)),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (u.priceHint.isNotEmpty) ...[
                  const Icon(Icons.payments_outlined,
                      size: 15, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text(u.priceHint,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 13)),
                ],
                const Spacer(),
                Text(u.city,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
            const Divider(height: 18),
            Row(
              children: [
                // 내 제보면 자기추천 불가 → '내 제보' 표시, 아니면 '나도 가봤어요'
                if (context.read<ContribProvider>().isMine(u.id))
                  Row(
                    children: [
                      const Icon(Icons.person_pin_circle_outlined,
                          size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text('내 제보 · 가봤어요 ${u.confirms}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textMuted)),
                    ],
                  )
                else
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _confirmed ? null : _confirm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            _confirmed
                                ? Icons.check_circle
                                : Icons.emoji_people_outlined,
                            size: 18,
                            color: _confirmed
                                ? AppColors.success
                                : AppColors.primary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _confirmed
                                ? '가봤어요 ${u.confirms}'
                                : '나도 가봤어요 ${u.confirms}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _confirmed
                                    ? AppColors.success
                                    : AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                const Spacer(),
                if (u.lat != null && u.lng != null)
                  TextButton.icon(
                    onPressed: () =>
                        AppLauncher.openMap(context, u.lat!, u.lng!, u.name),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('지도'),
                  )
                else
                  TextButton.icon(
                    onPressed: () => AppLauncher.openMapSearch(
                        context, '${u.name} ${u.city}'),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('지도 검색'),
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
