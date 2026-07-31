import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import 'currency_picker.dart';
import 'currency_provider.dart';
import 'exchange_guide_sheet.dart';
import 'keypad.dart';

/// 통화별 자주 쓰는 권종(치트시트용). 시장에서 "이 지폐 얼마?"를 한 번에.
const Map<String, List<int>> _denominations = {
  'VND': [10000, 50000, 100000, 500000],
  'JPY': [100, 500, 1000, 5000],
  'TWD': [100, 500, 1000],
  'THB': [20, 100, 500, 1000],
  'KRW': [1000, 5000, 10000, 50000],
  'USD': [1, 5, 20, 50, 100],
};

class CurrencyScreen extends StatelessWidget {
  const CurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CurrencyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('환율 계산기'),
        actions: [
          IconButton(
            tooltip: '환전 가이드',
            onPressed: () => showExchangeGuide(context),
            icon: const Icon(Icons.currency_exchange, color: AppColors.primary),
          ),
          _StatusChip(p: p),
        ],
      ),
      body: Column(
        children: [
          // ── 입력 카드 + 권종 + 동시 환산 (작은 화면이면 이 영역만 스크롤) ──
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: _InputCard(p: p),
                  ),
                  const SizedBox(height: 10),
                  _DenominationStrip(p: p),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _MultiCurrencyPanel(p: p),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _ExchangeGuideEntry(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          // ── 숫자패드 (항상 하단 고정) ──
          SafeArea(
            top: false,
            child: Keypad(
              onDigit: p.tapDigit,
              onBackspace: p.backspace,
              onClear: p.clear,
            ),
          ),
        ],
      ),
    );
  }
}

/// 온라인/오프라인 + 갱신시각 표시. 탭하면 수동 새로고침.
class _StatusChip extends StatelessWidget {
  final CurrencyProvider p;
  const _StatusChip({required this.p});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final live = p.isLive;
    final color = live ? AppColors.success : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: p.refreshing ? null : p.refresh,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              if (p.refreshing)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
              const SizedBox(width: 7),
              Text(
                p.refreshing
                    ? '갱신 중'
                    : '${live ? '실시간' : '오프라인'} · ${Fmt.relativeTime(p.updatedAt ?? now, now)}',
                style: TextStyle(
                    fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 입력 카드: 기준 통화 선택 + 입력 금액. (변환 결과는 아래 '동시 환산'에서 전 통화로)
class _InputCard extends StatelessWidget {
  final CurrencyProvider p;
  const _InputCard({required this.p});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          children: [
            // 기준 통화 선택
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final c = await showCurrencyPicker(context, current: p.from);
                if (c != null) p.setFrom(c);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    CountryFlag(code: p.from.code, height: 16),
                    const SizedBox(width: 6),
                    Text(p.from.code,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Icon(Icons.expand_more,
                        size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  Fmt.liveInput(p.input),
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 입력 금액을 여러 통화로 동시에 보여주는 패널.
/// (예: 베트남에서 달러·동 이중가격일 때 어느 쪽이 이득인지 한눈에 비교)
class _MultiCurrencyPanel extends StatelessWidget {
  final CurrencyProvider p;
  const _MultiCurrencyPanel({required this.p});

  String _valueText(Currency c) {
    final v = p.amountInCurrency(c);
    final num = (v < 0.01 && v > 0) ? Fmt.rate(v) : Fmt.amount(v, c);
    return '$num ${c.symbol}';
  }

  @override
  Widget build(BuildContext context) {
    // from 통화를 제외한 전 통화를 동시에 환산 (줄 탭 → 그 통화로 입력 전환)
    final others = allCurrencies.where((c) => c.code != p.from.code).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 4, 14, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < others.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              _row(others[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(Currency c) {
    final highlight = c.code == 'KRW' || c.code == 'USD';
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => p.setFrom(c), // 이 통화로 입력 전환
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
        child: Row(
          children: [
            CountryFlag(code: c.code, height: 15),
            const SizedBox(width: 8),
            Text(c.code,
                style: TextStyle(
                    fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.ink)),
            const SizedBox(width: 6),
            Expanded(
              child: Text(c.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ),
            Text(
              _valueText(c),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: highlight ? AppColors.primary : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 환전 가이드 진입 행: "공항보다 유리한 환전처는?" 국가별 실전 안내로.
class _ExchangeGuideEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showExchangeGuide(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: AppColors.primary),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('환전 어디서 유리할까? · 국가별 환전 가이드',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 자주 쓰는 권종을 칩으로. 탭하면 그 금액이 바로 입력된다.
class _DenominationStrip extends StatelessWidget {
  final CurrencyProvider p;
  const _DenominationStrip({required this.p});

  @override
  Widget build(BuildContext context) {
    final denoms = _denominations[p.from.code] ?? const [];
    if (denoms.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: denoms.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final v = denoms[i];
          return ActionChip(
            backgroundColor: AppColors.surface,
            side: const BorderSide(color: AppColors.line),
            label: Text('${Fmt.amount(v, p.from)}${p.from.symbol}'),
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 13),
            onPressed: () => p.setAmount(v),
          );
        },
      ),
    );
  }
}
