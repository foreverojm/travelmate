import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import 'price_data.dart';
import 'prices_provider.dart';

/// 시세 뷰: 선택된 나라·도시의 물품/음식 시세를 보여준다.
/// 핵심 가치 = 리뷰(별점 이벤트로 부풀려짐)에 휘둘리지 않도록
/// '음식 기준'의 로컬 물가와 비교해 바가지 여부를 판단하게 돕는다.
class PricesView extends StatelessWidget {
  final String countryCode;
  final String? city; // null = 전체 도시
  const PricesView({super.key, required this.countryCode, this.city});

  @override
  Widget build(BuildContext context) {
    final pp = context.watch<PricesProvider>();
    final items = pp.all
        .where((p) => p.countryCode == countryCode)
        .where((p) => city == null || p.city == city)
        .toList();

    // 카테고리 순서: 음식 기준을 맨 위로(가장 실전 가치).
    const order = ['음식 기준', '의류', '신발', '가방·잡화', '기념품', '식품', '잡화'];
    final cats = items.map((e) => e.category).toSet().toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });

    return RefreshIndicator(
      onRefresh: () => context.read<PricesProvider>().refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _TrustBanner(),
          const SizedBox(height: 10),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text('이 도시의 시세 데이터가 아직 없어요',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ...cats.expand((cat) {
              final rows = items.where((e) => e.category == cat).toList();
              return [
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 10, 2, 6),
                  child: Text(cat,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted)),
                ),
                ...rows.map((e) => _PriceCard(item: e)),
              ];
            }),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (pp.updatedAt != null)
            Text('시세 업데이트 ${Fmt.relativeTime(pp.updatedAt!, DateTime.now())} · 참고용',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(
            '출처: ${pp.source.isEmpty ? '블로그·현지 물가 조사·여행자 경험' : pp.source}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 2),
          const Text(
            '가격은 상점·수량·흥정·시기에 따라 달라집니다. 실제로 지불한 가격이 다르면 제보해 주세요(준비 중).',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// 리뷰·별점 신뢰도 주의 배너.
class _TrustBanner extends StatelessWidget {
  const _TrustBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.info_outline, size: 18, color: AppColors.accent),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              '별점·후기는 «좋은 리뷰 써주면 할인» 이벤트로 부풀려지기도 합니다. '
              '리뷰 수보다 아래 «음식 기준» 로컬 물가와 비교해 바가지인지 판단하세요.',
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.ink, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final PriceItem item;
  const _PriceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final isFood = item.category == '음식 기준';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.item,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Text('${item.city} · ${item.spot}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
            const SizedBox(height: 10),
            if (isFood)
              _foodPrices()
            else
              _goodsPrices(),
            if (item.krw.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.krw,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
            if (item.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(item.note,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.ink, height: 1.4)),
            ],
          ],
        ),
      ),
    );
  }

  /// 음식: 관광식당 vs 로컬 비교(로컬 강조).
  Widget _foodPrices() {
    return Row(
      children: [
        if (item.asking.isNotEmpty)
          _pricePill('관광·유명식당', item.asking, AppColors.textMuted, false),
        if (item.asking.isNotEmpty) const SizedBox(width: 8),
        _pricePill('로컬·현지인', item.fair, AppColors.success, true),
      ],
    );
  }

  /// 물품: 부르는 값 → 흥정 후 적정가. 정찰이면 정가만.
  Widget _goodsPrices() {
    if (item.isFixed) {
      return _pricePill('정찰가', item.asking, AppColors.primary, true);
    }
    return Row(
      children: [
        _pricePill('부르는 값', item.asking, AppColors.textMuted, false),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 16, color: AppColors.textMuted),
        ),
        _pricePill('흥정 후 적정가', item.fair, AppColors.success, true),
      ],
    );
  }

  Widget _pricePill(String label, String value, Color color, bool strong) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: strong ? color.withValues(alpha: 0.10) : AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: strong
                ? color.withValues(alpha: 0.35)
                : Colors.transparent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: strong ? color : AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: strong ? AppColors.ink : AppColors.textMuted)),
        ],
      ),
    );
  }
}
