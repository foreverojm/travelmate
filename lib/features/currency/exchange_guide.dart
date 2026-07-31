import 'package:flutter/material.dart';

/// 환전 장소 한 곳의 평가.
/// rating: '◎'(유리) / '○'(보통) / '△'(불리)
class ExchangeSpot {
  final String place;
  final String rating;
  final String note;
  const ExchangeSpot(this.place, this.rating, this.note);
}

/// 국가별 환전 실전 가이드. "어디서 바꾸는 게 유리한가"를 정직하게 안내.
class ExchangeGuide {
  final String summary; // 한 줄 핵심
  final List<ExchangeSpot> spots;
  final List<String> tips;
  const ExchangeGuide({
    required this.summary,
    required this.spots,
    required this.tips,
  });
}

/// 색: 유리=초록, 보통=파랑, 불리=회색
Color ratingColor(String r) {
  switch (r) {
    case '◎':
      return const Color(0xFF1DAA6B); // success
    case '○':
      return const Color(0xFF2E6BE6); // primary
    default:
      return const Color(0xFF8A94A6); // muted
  }
}

const Map<String, ExchangeGuide> exchangeGuides = {
  'VN': ExchangeGuide(
    summary: '공항 환전은 손해. 시내 금은방(tiệm vàng)·환전소가 가장 유리해요.',
    spots: [
      ExchangeSpot('공항 환전소', '△', '급한 소액만. 환율이 가장 불리'),
      ExchangeSpot('은행(Vietcombank·BIDV)', '○', '여권 필요, 안전하지만 환율은 평범'),
      ExchangeSpot('금은방(tiệm vàng)·시내 환전소', '◎',
          '나트랑 등 금은방이 환율 좋음. 두세 곳 비교 후 환전'),
      ExchangeSpot('ATM 인출', '○', '대형은행 ATM. 인출 수수료·한도 먼저 확인'),
    ],
    tips: [
      '10만동·1만동 지폐 색이 비슷 → 0 개수 꼭 확인(바가지 주의)',
      '큰 금액은 100달러 신권이 환율 유리(구권·손상권은 거부되기도)',
      '환전 직후 그 자리에서 금액을 세어 확인',
    ],
  ),
  'TH': ExchangeGuide(
    summary: '공항보다 시내 Superrich·Vasu 같은 사설환전소가 훨씬 유리해요.',
    spots: [
      ExchangeSpot('공항 환전소', '△', '급한 소액만'),
      ExchangeSpot('은행', '○', '환율 평범, 여권 필요'),
      ExchangeSpot('Superrich(오렌지/그린)·시내 환전소', '◎',
          'BTS역 인근에 많음. 여권 지참, 환율 최상급'),
      ExchangeSpot('ATM 인출', '△', '인출 수수료 약 220밧 고정 → 한 번에 크게'),
    ],
    tips: [
      '100달러 신권이 환율 최상. 소액 달러권은 환율이 낮음',
      '소액권(20·100밧)은 팁·시장용으로 확보',
      '환전소마다 고시환율 다름 → 표지판 비교',
    ],
  ),
  'JP': ExchangeGuide(
    summary: '환전보다 세븐뱅크 ATM 해외카드 인출이 무난. 현금사회라 소액 필수.',
    spots: [
      ExchangeSpot('공항·시내 환전소', '△', '환율·수수료 손해가 큼'),
      ExchangeSpot('은행 환전', '△', '외화 환전 절차가 번거로움'),
      ExchangeSpot('세븐일레븐(세븐뱅크) ATM', '◎', '해외카드 인출이 가장 무난, 24시간'),
      ExchangeSpot('IC카드(Suica/Pasmo)', '○', '교통·편의점 결제로 현금 절약'),
    ],
    tips: [
      '아직 현금 많이 쓰는 편 → 소액 현금 필수',
      '면세(Tax free)는 여권 지참',
      '고액 인출보다 필요한 만큼 나눠 인출이 안전',
    ],
  ),
  'TW': ExchangeGuide(
    summary: '공항·은행 환율 차이가 작은 편. 은행 환전 또는 ATM 인출이 무난해요.',
    spots: [
      ExchangeSpot('공항 은행 환전', '○', '대만은행 등 카운터. 환율 무난'),
      ExchangeSpot('시내 은행(타이완은행 등)', '◎', '수수료 저렴, 환율 유리'),
      ExchangeSpot('편의점·은행 ATM', '○', '해외카드 인출 가능'),
      ExchangeSpot('悠遊卡(이지카드)', '○', '교통·편의점 결제로 편리'),
    ],
    tips: [
      '야시장·소상점은 현금 위주 → 소액권 준비',
      '환전 영수증 보관(남은 돈 재환전 시 유리)',
      '대형 상점 외에는 카드 안 되는 곳 많음',
    ],
  ),
};
