import 'package:flutter/material.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import 'exchange_guide.dart';

/// 국가별 환전 가이드 바텀시트. "어디서 바꾸는 게 유리한가"를 정직하게 보여준다.
Future<void> showExchangeGuide(BuildContext context, {String initial = 'VN'}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _ExchangeGuideSheet(initial: initial),
  );
}

class _ExchangeGuideSheet extends StatefulWidget {
  final String initial;
  const _ExchangeGuideSheet({required this.initial});

  @override
  State<_ExchangeGuideSheet> createState() => _ExchangeGuideSheetState();
}

class _ExchangeGuideSheetState extends State<_ExchangeGuideSheet> {
  late String _cc = widget.initial;

  @override
  Widget build(BuildContext context) {
    final guide = exchangeGuides[_cc];
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scroll) => Column(
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.currency_exchange, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('환전 가이드',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          // 나라 선택
          SizedBox(
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
                  selected: c.code == _cc,
                  leading: CountryFlag(code: c.code, height: 15),
                  onTap: () => setState(() => _cc = c.code),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: guide == null
                ? const Center(child: Text('가이드 준비 중'))
                : ListView(
                    controller: scroll,
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(guide.summary,
                            style: const TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 14),
                      const _Label('환전 장소별 유불리'),
                      const SizedBox(height: 8),
                      ...guide.spots.map((s) => _SpotRow(spot: s)),
                      const SizedBox(height: 16),
                      const _Label('실전 팁'),
                      const SizedBox(height: 8),
                      ...guide.tips.map((t) => _Bullet(text: t)),
                      const SizedBox(height: 16),
                      const Text(
                        '※ 환율은 매매기준율 기준이며 실제 환전소 제시가와 차이가 있습니다. 참고용으로 사용하세요.',
                        style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.5),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textMuted));
}

class _SpotRow extends StatelessWidget {
  final ExchangeSpot spot;
  const _SpotRow({required this.spot});

  @override
  Widget build(BuildContext context) {
    final color = ratingColor(spot.rating);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Text(spot.rating,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w900, fontSize: 15)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(spot.place,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 2),
                Text(spot.note,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet({required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6, right: 8),
            child: Icon(Icons.circle, size: 5, color: AppColors.textMuted),
          ),
          Expanded(
              child: Text(text,
                  style: const TextStyle(height: 1.45, fontSize: 13.5))),
        ],
      ),
    );
  }
}
