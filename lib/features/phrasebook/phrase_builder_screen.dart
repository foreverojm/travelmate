import 'package:flutter/material.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/models.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import 'phrase_builder_data.dart';
import 'phrase_tts.dart';
import 'phrase_widgets.dart';

/// 조합형 문구 만들기: 동작 + 대상을 골라 검증된 현지어 문장을 만든다.
/// (자유 번역이 아니라 안전한 패턴 조합 → 오프라인·정확한 발음·상대에게 큰 글씨)
class PhraseBuilderScreen extends StatefulWidget {
  final String initialCountry;
  const PhraseBuilderScreen({super.key, required this.initialCountry});

  @override
  State<PhraseBuilderScreen> createState() => _PhraseBuilderScreenState();
}

class _PhraseBuilderScreenState extends State<PhraseBuilderScreen> {
  late String _cc = widget.initialCountry;
  int _tpl = 0;
  int _item = 0;

  @override
  Widget build(BuildContext context) {
    final tpl = builderTemplates[_tpl];
    final item = tpl.items[_item];
    final locale = ttsLocaleOf(_cc);

    final card = PhraseCard(
      ko: tpl.koFor(item),
      local: tpl.localFor(_cc, item),
      pron: tpl.pronFor(_cc, item),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('문구 만들기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 나라
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
                  onTap: () => setState(() => _cc = c.code),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          const _Label('1. 무엇을 말할까요?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < builderTemplates.length; i++)
                SelectPill(
                  label: builderTemplates[i].ko.replaceFirst('{x}', '…'),
                  selected: i == _tpl,
                  onTap: () => setState(() {
                    _tpl = i;
                    _item = 0; // 동작 바꾸면 대상 초기화
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),

          const _Label('2. 대상을 고르세요'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < tpl.items.length; i++)
                SelectPill(
                  label: tpl.items[i].ko,
                  selected: i == _item,
                  activeColor: AppColors.accent,
                  onTap: () => setState(() => _item = i),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // 미리보기
          _PreviewCard(card: card, localeTag: locale),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final PhraseCard card;
  final String localeTag;
  const _PreviewCard({required this.card, required this.localeTag});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.ko,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14)),
            const SizedBox(height: 8),
            Text(card.local,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
            const SizedBox(height: 6),
            Text('[${card.pron}]',
                style: const TextStyle(color: AppColors.primary, fontSize: 15)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () =>
                        PhraseTts.instance.speak(card.local, localeTag),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.volume_up, size: 20),
                    label: const Text('발음 듣기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        showPhraseFullscreen(context, card, localeTag),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    icon: const Icon(Icons.fullscreen, size: 20),
                    label: const Text('크게 보여주기',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800));
}
