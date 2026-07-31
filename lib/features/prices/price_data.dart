/// 도시별 물품 시세 모델.
/// 관광객이 자주 사는 품목의 "부르는 값(asking) → 흥정 후 적정가(fair)"와
/// 원화 대략(krw), 흥정 팁(note)을 담아 실전 구매·흥정 기준을 제공한다.
/// 정찰(흥정 없는) 품목은 fair 를 '정찰'로 표기한다.
library;

class PriceItem {
  final String countryCode;
  final String city;
  final String spot; // 시장·매장, 예: '담시장'
  final String category; // 의류/신발/가방·잡화/기념품/식품
  final String item; // 품목명
  final String asking; // 부르는 값(관광가). 정찰이면 이 값이 곧 정가
  final String fair; // 흥정 후 적정가 또는 '정찰'
  final String krw; // 원화 대략 환산
  final String note; // 흥정·구매 팁

  const PriceItem({
    required this.countryCode,
    required this.city,
    required this.spot,
    required this.category,
    required this.item,
    required this.asking,
    required this.fair,
    required this.krw,
    required this.note,
  });

  bool get isFixed => fair == '정찰';

  factory PriceItem.fromJson(Map<String, dynamic> j) {
    return PriceItem(
      countryCode: (j['countryCode'] as String?) ?? '',
      city: (j['city'] as String?) ?? '',
      spot: (j['spot'] as String?) ?? '',
      category: (j['category'] as String?) ?? '',
      item: (j['item'] as String?) ?? '',
      asking: (j['asking'] as String?) ?? '',
      fair: (j['fair'] as String?) ?? '',
      krw: (j['krw'] as String?) ?? '',
      note: (j['note'] as String?) ?? '',
    );
  }
}
