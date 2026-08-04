import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import 'currency_provider.dart';

/// 표시 통화 편집 바텀시트.
/// 여행지 프리셋(원·달러 + 그 나라 통화)으로 한 번에 맞추거나, 개별 on/off.
Future<void> showCurrencyEditor(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _CurrencyEditSheet(),
  );
}

class _CurrencyEditSheet extends StatelessWidget {
  const _CurrencyEditSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();
    // 여행지 프리셋: 라벨 → 켤 통화들(원·달러는 자동 포함)
    final presets = <String, Set<String>>{
      '전체': allCurrencies.map((c) => c.code).toSet(),
      for (final c in countries) c.nameKo: {'USD', c.currency.code},
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text('표시 통화 편집',
                      style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            // 여행지 프리셋
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
                child: Text('여행지 프리셋',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final entry in presets.entries) ...[
                    SelectPill(
                      label: entry.key,
                      selected: false,
                      onTap: () =>
                          context.read<CurrencyProvider>().applyVisiblePreset(
                                entry.value,
                              ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            // 개별 통화 체크
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (final c in allCurrencies)
                    CheckboxListTile(
                      value: p.isVisible(c.code),
                      onChanged: c.code == 'KRW'
                          ? null // 기준 통화는 항상 표시
                          : (_) => context
                              .read<CurrencyProvider>()
                              .toggleVisible(c.code),
                      controlAffinity: ListTileControlAffinity.trailing,
                      secondary: CountryFlag(code: c.code, height: 18),
                      title: Text('${c.code} · ${c.name}',
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      subtitle: c.code == 'KRW'
                          ? const Text('기준 통화(항상 표시)',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted))
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
