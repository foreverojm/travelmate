import 'package:flutter/material.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/launcher.dart';
import '../../core/models.dart';
import '../../core/pills.dart';
import '../../core/plug.dart';
import '../../core/theme.dart';
import 'siren_button.dart';

/// 긴급 SOS 화면. 나라를 고르면 그 나라의 긴급번호·대사관·현지 회화·현금 팁을
/// 한 화면에서 바로 쓸 수 있다. 모든 정보는 오프라인에서도 동작(정적 데이터).
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Country _country = countries.first;

  @override
  Widget build(BuildContext context) {
    final c = _country;
    return Scaffold(
      appBar: AppBar(title: const Text('긴급 SOS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _CountrySelector(
            selected: _country,
            onChanged: (v) => setState(() => _country = v),
          ),
          const SizedBox(height: 16),

          // 현지 긴급번호 (가장 크고 먼저)
          _sectionTitle('현지 긴급전화'),
          const SizedBox(height: 8),
          _EmergencyGrid(contacts: c.emergencyContacts),
          const SizedBox(height: 10),
          const SirenButton(),
          const SizedBox(height: 20),

          // 한국 영사 지원
          _sectionTitle('한국 영사 지원'),
          const SizedBox(height: 8),
          _ConsularCard(),
          const SizedBox(height: 12),
          _EmbassyCard(embassy: c.embassy),
          const SizedBox(height: 20),

          // 급할 때 크게 보여주는 긴급 현지어
          _sectionTitle('바로 보여주는 현지어 (긴급)'),
          const SizedBox(height: 8),
          ...c.phrases.map((ph) => _PhraseTile(phrase: ph)),
          const SizedBox(height: 20),

          // 일상 여행 회화
          _sectionTitle('알아두면 좋은 현지어'),
          const SizedBox(height: 8),
          ...c.usefulPhrases.map((ph) => _PhraseTile(phrase: ph)),
          const SizedBox(height: 20),

          // 전원 · 콘센트 (실제 모양)
          _sectionTitle('전원 · 콘센트'),
          const SizedBox(height: 8),
          _PlugCard(plug: c.plug),
          const SizedBox(height: 20),

          // 카테고리별 여행 치트시트
          _sectionTitle('${c.nameKo} 여행 치트시트'),
          const SizedBox(height: 8),
          ...c.cheatsheet.map((s) => _CheatCard(section: s)),
          const SizedBox(height: 10),
          _InfoExpansion(title: '현금·환전 팁', items: c.cashTips),
          const SizedBox(height: 16),
          const _Disclaimer(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700));
}

class _CountrySelector extends StatelessWidget {
  final Country selected;
  final ValueChanged<Country> onChanged;
  const _CountrySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
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

/// 큰 긴급전화 버튼들 (오탭 방지 위해 넉넉한 터치영역).
class _EmergencyGrid extends StatelessWidget {
  final List<EmergencyContact> contacts;
  const _EmergencyGrid({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: contacts.map((c) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: AppColors.danger,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => AppLauncher.dial(context, c.number),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk, color: Colors.white),
                    const SizedBox(width: 14),
                    Text(c.label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Text(c.number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ConsularCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.support_agent, color: AppColors.primary),
        title: const Text('외교부 영사콜센터',
            style: TextStyle(fontWeight: FontWeight.w700)),
        subtitle: const Text('24시간 · 사건사고·통역 지원'),
        trailing: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
          onPressed: () => AppLauncher.dial(context, consularCallCenter),
          icon: const Icon(Icons.call, size: 18),
          label: const Text('연결'),
        ),
      ),
    );
  }
}

class _EmbassyCard extends StatelessWidget {
  final Embassy embassy;
  const _EmbassyCard({required this.embassy});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(embassy.name,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 6),
            Text(embassy.address,
                style: const TextStyle(color: AppColors.textMuted, height: 1.4)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => AppLauncher.dial(context, embassy.phone),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('대표번호'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: const BorderSide(color: AppColors.danger)),
                    onPressed: () =>
                        AppLauncher.dial(context, embassy.emergencyPhone),
                    icon: const Icon(Icons.emergency, size: 18),
                    label: const Text('긴급'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: () => AppLauncher.openMap(
                    context, embassy.lat, embassy.lng, embassy.name),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('지도에서 길찾기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 화면에 크게 보여주는 현지어 카드. 탭하면 전체화면으로 확대(상대에게 보여주기).
class _PhraseTile extends StatelessWidget {
  final PhraseCard phrase;
  const _PhraseTile({required this.phrase});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showFullscreen(context),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phrase.ko,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(phrase.local,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('[${phrase.pron}]',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.fullscreen, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(12),
        backgroundColor: AppColors.ink,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(phrase.ko,
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              Text(phrase.local,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.3)),
              const SizedBox(height: 16),
              Text('[${phrase.pron}]',
                  style: const TextStyle(color: AppColors.accent, fontSize: 18)),
              const SizedBox(height: 28),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('닫기', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 전원·콘센트 카드: 실제 콘센트 모양 + 전압·주파수 + 한국 플러그 호환 안내.
class _PlugCard extends StatelessWidget {
  final PlugInfo plug;
  const _PlugCard({required this.plug});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 콘센트 도형들
            Row(
              children: plug.types
                  .map((t) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          children: [
                            PlugIcon(type: t, size: 44),
                            const SizedBox(height: 4),
                            Text('$t형',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bolt, size: 18, color: AppColors.accent),
                      const SizedBox(width: 4),
                      Text(plug.voltage,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(plug.note,
                      style: const TextStyle(
                          color: AppColors.textMuted, height: 1.45)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 치트시트 카테고리 카드(아이콘 + 접이식).
class _CheatCard extends StatelessWidget {
  final CheatSection section;
  const _CheatCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: Icon(section.icon, color: AppColors.primary, size: 22),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            title: Text(section.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            children: section.items
                .map((t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 8),
                            child: Icon(Icons.circle,
                                size: 5, color: AppColors.textMuted),
                          ),
                          Expanded(
                              child:
                                  Text(t, style: const TextStyle(height: 1.45))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

class _InfoExpansion extends StatelessWidget {
  final String title;
  final List<String> items;
  const _InfoExpansion({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: Text(title,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          children: items
              .map((t) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6, right: 8),
                          child: Icon(Icons.circle,
                              size: 5, color: AppColors.textMuted),
                        ),
                        Expanded(
                            child: Text(t,
                                style: const TextStyle(height: 1.45))),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();
  @override
  Widget build(BuildContext context) {
    return const Text(
      '※ 긴급번호·대사관 정보는 변동될 수 있습니다. 출발 전 외교부 해외안전여행'
      '(0404.go.kr) 및 현지 최신 정보를 함께 확인하세요.',
      style: TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.5),
    );
  }
}
