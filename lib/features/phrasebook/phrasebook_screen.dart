import 'package:flutter/material.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/models.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import 'phrase_widgets.dart';

/// 상황별 현지어 탭. 나라 선택 → 카테고리(위급/쇼핑/식당/교통/숙소…)별 회화.
/// 카드를 탭하면 상대에게 세로 초대형으로 보여주고, 🔊로 현지어 발음을 들려준다.
class PhrasebookScreen extends StatefulWidget {
  const PhrasebookScreen({super.key});

  @override
  State<PhrasebookScreen> createState() => _PhrasebookScreenState();
}

class _PhrasebookScreenState extends State<PhrasebookScreen> {
  Country _country = countries.first;

  @override
  Widget build(BuildContext context) {
    final c = _country;
    final locale = ttsLocaleOf(c.code);

    // 위급상황을 맨 앞 그룹으로(SOS의 긴급 현지어 재사용).
    final groups = <PhraseGroup>[
      PhraseGroup(
          title: '위급상황', icon: Icons.emergency_share, items: c.phrases),
      ...c.phrasebook,
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('현지어')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          _CountrySelector(
            selected: _country,
            onChanged: (v) => setState(() => _country = v),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.record_voice_over,
                    size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '카드를 누르면 크게 보여주고, 🔊로 현지어 발음을 들려줄 수 있어요.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...groups.asMap().entries.map((e) => _GroupCard(
                group: e.value,
                localeTag: locale,
                initiallyExpanded: e.key == 0, // 위급상황만 펼친 상태
              )),
        ],
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final PhraseGroup group;
  final String localeTag;
  final bool initiallyExpanded;
  const _GroupCard({
    required this.group,
    required this.localeTag,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final danger = group.title == '위급상황';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: initiallyExpanded,
            leading: Icon(group.icon,
                color: danger ? AppColors.danger : AppColors.primary),
            title: Text(group.title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            tilePadding: const EdgeInsets.symmetric(horizontal: 16),
            childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            children: group.items
                .map((ph) => PhraseTile(phrase: ph, localeTag: localeTag))
                .toList(),
          ),
        ),
      ),
    );
  }
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
