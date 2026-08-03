import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../contrib/contrib_provider.dart';
import '../contrib/price_report_form.dart';
import '../contrib/user_place.dart';
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
    final cp = context.watch<ContribProvider>();
    final items = pp.all
        .where((p) => p.countryCode == countryCode)
        .where((p) => city == null || p.city == city)
        .toList();
    // 여행자 시세 제보(같은 나라·도시)
    final reports = cp.all
        .where((u) => u.type == 'price' && u.countryCode == countryCode)
        .where((u) => city == null || u.city == city)
        .toList();

    // 카테고리 순서: 음식 기준을 맨 위로(가장 실전 가치).
    const order = ['음식 기준', '의류', '신발', '가방·잡화', '기념품', '식품', '잡화'];
    final cats = items.map((e) => e.category).toSet().toList()
      ..sort((a, b) {
        final ia = order.indexOf(a), ib = order.indexOf(b);
        return (ia < 0 ? 99 : ia).compareTo(ib < 0 ? 99 : ib);
      });

    return RefreshIndicator(
      onRefresh: () async {
        final pricesP = context.read<PricesProvider>();
        final contribP = context.read<ContribProvider>();
        await pricesP.refresh();
        await contribP.refresh();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _TrustBanner(),
          const SizedBox(height: 10),
          // 여행자 시세 제보(실제 지불가) 먼저
          if (reports.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(2, 0, 2, 6),
              child: Text('여행자 제보 시세 · 실제 지불가',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMuted)),
            ),
            ...reports.map((u) => _UserPriceCard(report: u)),
            const SizedBox(height: 8),
          ],
          if (items.isEmpty && reports.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 60),
              child: Center(
                child: Text('이 도시의 시세가 아직 없어요. 아래 «시세 제보»로 첫 정보를 남겨주세요!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else if (items.isNotEmpty)
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
            '가격은 상점·수량·흥정·시기에 따라 달라집니다. 실제로 지불한 가격은 우하단 «시세 제보»로 남겨주세요.',
            style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// 여행자 시세 제보 카드(실제 지불가). '저도 이 가격' 수로 신뢰가 쌓인다.
class _UserPriceCard extends StatefulWidget {
  final UserPlace report;
  const _UserPriceCard({required this.report});
  @override
  State<_UserPriceCard> createState() => _UserPriceCardState();
}

class _UserPriceCardState extends State<_UserPriceCard> {
  bool _confirmed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context
        .read<ContribProvider>()
        .alreadyConfirmed(widget.report.id)
        .then((v) {
      if (mounted) setState(() => _confirmed = v);
    });
  }

  Future<void> _confirm() async {
    if (_confirmed || _busy) return;
    final prov = context.read<ContribProvider>();
    setState(() => _busy = true);
    final ok = await prov.confirm(widget.report.id);
    if (mounted) {
      setState(() {
        _busy = false;
        _confirmed = ok || _confirmed;
      });
    }
  }

  Future<void> _edit() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PriceReportForm(
          initialCountry: widget.report.countryCode, existing: widget.report),
    ));
  }

  Future<void> _delete() async {
    final prov = context.read<ContribProvider>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('시세 제보 삭제'),
        content: const Text('이 시세 제보를 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('삭제', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) {
      final done = await prov.deleteOwn(widget.report.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(done ? '삭제됐어요.' : '삭제에 실패했어요.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.report;
    final mine = context.watch<ContribProvider>().isMine(u.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _miniTag(u.isVerified ? '검증됨' : '미검증',
                    u.isVerified ? AppColors.success : AppColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(u.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Text('여행자 제보',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.payments_outlined,
                    size: 16, color: AppColors.success),
                const SizedBox(width: 6),
                Text(u.priceHint,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const Spacer(),
                Text(u.city,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
            if (u.note.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(u.note,
                  style: const TextStyle(
                      fontSize: 12.5, color: AppColors.ink, height: 1.4)),
            ],
            const Divider(height: 18),
            if (mine)
              Row(children: [
                const Icon(Icons.person_pin_circle_outlined,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 5),
                Text('내 제보 · 저도 이 가격 ${u.confirms}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted)),
                const Spacer(),
                TextButton.icon(
                  onPressed: _edit,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('수정'),
                ),
                TextButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline,
                      size: 16, color: AppColors.danger),
                  label: const Text('삭제',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ])
            else
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _confirmed ? null : _confirm,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                          _confirmed
                              ? Icons.check_circle
                              : Icons.thumb_up_alt_outlined,
                          size: 18,
                          color: _confirmed
                              ? AppColors.success
                              : AppColors.primary),
                      const SizedBox(width: 5),
                      Text(
                        _confirmed
                            ? '저도 이 가격 ${u.confirms}'
                            : '저도 이 가격이었어요 ${u.confirms}',
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
          ],
        ),
      ),
    );
  }

  Widget _miniTag(String t, Color c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(t,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: c)),
      );
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
