import 'package:flutter/material.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/models.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import 'builder_dictionary.dart';
import 'phrase_builder_data.dart';
import 'phrase_tts.dart';
import 'phrase_widgets.dart';
import 'word_translator.dart';

/// 조합형 문구 만들기: 동작 + 대상을 골라 검증된 현지어 문장을 만든다.
/// 대상은 (1) 프리셋, (2) 내장 단어사전 검색(오프라인·정확 발음),
/// (3) 사전에 없으면 온라인 자동번역(발음은 🔊로) 중에서 고른다.
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

  // 직접 입력(커스텀 단어)
  bool _showCustom = false;
  BuilderItem? _custom; // 선택된 커스텀 단어
  bool _customIsAuto = false; // 온라인 자동번역 여부(발음 없음)
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _translating = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  BuilderItem get _activeItem =>
      _custom ?? builderTemplates[_tpl].items[_item];

  void _pickPreset(int i) => setState(() {
        _item = i;
        _custom = null;
        _customIsAuto = false;
      });

  void _pickDictionary(BuilderItem it) => setState(() {
        _custom = it;
        _customIsAuto = false;
        _showCustom = false;
        _query = '';
        _searchCtrl.clear();
      });

  Future<void> _translateOnline() async {
    final q = _query.trim();
    if (q.isEmpty) return;
    setState(() => _translating = true);
    final local = await WordTranslator.translate(q, _cc);
    if (!mounted) return;
    setState(() {
      _translating = false;
      if (local != null) {
        _custom = BuilderItem(q, {_cc: local}, {_cc: ''}); // 발음은 비움(🔊로)
        _customIsAuto = true;
        _showCustom = false;
        _query = '';
        _searchCtrl.clear();
      }
    });
    if (local == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('번역을 가져오지 못했어요. 인터넷 연결을 확인해 주세요.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tpl = builderTemplates[_tpl];
    final item = _activeItem;
    final locale = ttsLocaleOf(_cc);

    final card = PhraseCard(
      ko: tpl.koFor(item),
      local: tpl.localFor(_cc, item),
      pron: tpl.pronFor(_cc, item),
    );

    final matches = _query.trim().isEmpty
        ? const <BuilderItem>[]
        : builderDictionary
            .where((d) => d.ko.contains(_query.trim()))
            .take(10)
            .toList();

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
                  onTap: () => setState(() {
                    _cc = c.code;
                    // 자동번역 단어는 언어별이므로 나라 바뀌면 해제
                    if (_customIsAuto) {
                      _custom = null;
                      _customIsAuto = false;
                    }
                  }),
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
                    _item = 0;
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
                  selected: _custom == null && i == _item,
                  activeColor: AppColors.accent,
                  onTap: () => _pickPreset(i),
                ),
              // 직접 입력 진입 칩
              SelectPill(
                label: _custom != null ? '✓ ${_custom!.ko}' : '＋ 직접 입력',
                selected: _custom != null,
                activeColor: AppColors.primary,
                onTap: () => setState(() => _showCustom = !_showCustom),
              ),
            ],
          ),

          // 직접 입력 패널
          if (_showCustom) ...[
            const SizedBox(height: 12),
            _CustomPanel(
              controller: _searchCtrl,
              onQuery: (v) => setState(() => _query = v),
              matches: matches,
              onPickDict: _pickDictionary,
              query: _query,
              translating: _translating,
              onTranslate: _translateOnline,
            ),
          ],

          const SizedBox(height: 20),
          _PreviewCard(
            card: card,
            localeTag: locale,
            isAuto: _customIsAuto,
          ),
        ],
      ),
    );
  }
}

/// 직접 입력 패널: 검색(사전) → 없으면 온라인 번역.
class _CustomPanel extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onQuery;
  final List<BuilderItem> matches;
  final ValueChanged<BuilderItem> onPickDict;
  final String query;
  final bool translating;
  final VoidCallback onTranslate;
  const _CustomPanel({
    required this.controller,
    required this.onQuery,
    required this.matches,
    required this.onPickDict,
    required this.query,
    required this.translating,
    required this.onTranslate,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: '한국어 단어 입력 (예: 우산, 계란)',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('사전에서 선택 (발음 정확)',
                style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: matches
                  .map((m) => SelectPill(
                        label: m.ko,
                        selected: false,
                        onTap: () => onPickDict(m),
                      ))
                  .toList(),
            ),
          ],
          if (hasQuery && matches.isEmpty) ...[
            const SizedBox(height: 10),
            Text('‘${query.trim()}’ 은(는) 사전에 없어요.',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: translating ? null : onTranslate,
                icon: translating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.translate, size: 18),
                label: Text(translating ? '번역 중…' : '온라인 번역으로 만들기 (인터넷)'),
              ),
            ),
            const SizedBox(height: 4),
            const Text('자동번역은 발음 표기가 없어요. 🔊로 발음을 확인하세요.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final PhraseCard card;
  final String localeTag;
  final bool isAuto;
  const _PreviewCard(
      {required this.card, required this.localeTag, required this.isAuto});

  @override
  Widget build(BuildContext context) {
    final hasPron = card.pron.trim().isNotEmpty;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(card.ko,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 14)),
                ),
                if (isAuto)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('자동번역',
                        style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent)),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(card.local,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w800, height: 1.25)),
            const SizedBox(height: 6),
            if (hasPron)
              Text('[${card.pron}]',
                  style: const TextStyle(color: AppColors.primary, fontSize: 15))
            else
              const Text('발음 표기 없음 · 🔊로 들어보세요',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
