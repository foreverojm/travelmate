/// 앱 전역에서 쓰는 핵심 데이터 모델들.
/// 국가 하나에 통화·긴급번호·대사관 정보가 모두 묶여 있어
/// 환율/SOS/맛집 기능이 여기서 데이터를 가져다 쓴다.
library;

import 'package:flutter/widgets.dart' show IconData;

/// 통화 정보
class Currency {
  final String code; // ISO 4217, 예: 'VND'
  final String name; // 한글 이름, 예: '베트남 동'
  final String symbol; // 기호, 예: '₫'
  final String flag; // 국기 이모지
  final int decimalDigits; // 표시 소수 자릿수 (VND/JPY는 0, KRW는 0)

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.flag,
    this.decimalDigits = 0,
  });
}

/// 긴급 연락처 (경찰/구급 등)
class EmergencyContact {
  final String label; // 예: '경찰'
  final String number; // 예: '113'
  final String icon; // 이모지

  const EmergencyContact({
    required this.label,
    required this.number,
    required this.icon,
  });
}

/// 한국 대사관/영사관 정보
class Embassy {
  final String name; // 예: '주베트남 대한민국 대사관'
  final String address; // 현지 주소
  final String phone; // 일반 전화
  final String emergencyPhone; // 긴급(사건사고) 전화
  final double lat;
  final double lng;

  const Embassy({
    required this.name,
    required this.address,
    required this.phone,
    required this.emergencyPhone,
    required this.lat,
    required this.lng,
  });
}

/// 전원·플러그 정보 (콘센트 모양은 types로 그려낸다)
class PlugInfo {
  final String voltage; // '220V · 50Hz'
  final List<String> types; // ['A', 'C'] 등 — 콘센트 도형 렌더용
  final String note; // 한국 플러그 호환 여부 등

  const PlugInfo({
    required this.voltage,
    required this.types,
    required this.note,
  });
}

/// 치트시트의 한 카테고리 (통신/교통/치안 등)
class CheatSection {
  final String title;
  final IconData icon;
  final List<String> items;

  const CheatSection({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// 현지에서 급할 때 화면에 크게 띄우는 회화 카드
class PhraseCard {
  final String ko; // 한국어
  final String local; // 현지어 표기
  final String pron; // 한글 발음

  const PhraseCard({required this.ko, required this.local, required this.pron});
}

/// 상황별 현지어 묶음 (인사·쇼핑·식당·교통·숙소 등)
class PhraseGroup {
  final String title; // 예: '쇼핑 · 흥정'
  final IconData icon;
  final List<PhraseCard> items;

  const PhraseGroup({
    required this.title,
    required this.icon,
    required this.items,
  });
}

/// 하나의 여행 대상 국가
class Country {
  final String code; // ISO 3166 alpha-2, 예: 'VN'
  final String nameKo; // '베트남'
  final String flag; // 국기 이모지
  final Currency currency;
  final String emergencyGeneral; // 통합 긴급번호(있으면), 표시용
  final List<EmergencyContact> emergencyContacts;
  final Embassy embassy;
  final List<PhraseCard> phrases; // 긴급용 현지어(SOS 화면에서 크게 보여주기)
  final List<PhraseGroup> phrasebook; // 상황별 여행 회화(현지어 탭)
  final List<String> cashTips; // 현금 인출/환전 팁
  final PlugInfo plug; // 전원·콘센트
  final List<CheatSection> cheatsheet; // 카테고리별 여행 치트시트

  const Country({
    required this.code,
    required this.nameKo,
    required this.flag,
    required this.currency,
    required this.emergencyGeneral,
    required this.emergencyContacts,
    required this.embassy,
    required this.phrases,
    required this.phrasebook,
    required this.cashTips,
    required this.plug,
    required this.cheatsheet,
  });
}
