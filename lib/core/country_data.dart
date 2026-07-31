import 'package:flutter/material.dart';
import 'models.dart';

/// 원화 (앱의 기준/홈 통화)
const krw = Currency(
  code: 'KRW',
  name: '대한민국 원',
  symbol: '₩',
  flag: '🇰🇷',
  decimalDigits: 0,
);

/// 미국 달러 — 동남아 등에서 현지통화와 이중가격으로 많이 쓰여 비교용으로 포함
const usd = Currency(
  code: 'USD',
  name: '미국 달러',
  symbol: '\$',
  flag: '🇺🇸',
  decimalDigits: 2,
);

/// 외교부 영사콜센터 (해외 24시간, 무료 통화 가능) — 모든 나라 공통
const consularCallCenter = '+82-2-3210-0404';

/// 환율 오프라인 초기 시드값: "1 KRW 당 해당 통화 단위"
/// (open.er-api.com 응답 포맷과 동일 — 온라인 시 실시간 값으로 덮어씀)
const Map<String, double> seedRatesPerKrw = {
  'KRW': 1.0,
  'USD': 0.000725, // 1원 ≈ 0.000725달러 (1달러 ≈ 1,380원)
  'VND': 18.0,
  'JPY': 0.11,
  'TWD': 0.0238,
  'THB': 0.025,
};

/// 여행 대상 4개국
const List<Country> countries = [
  // ═══════════════════════════ 베트남 ═══════════════════════════
  Country(
    code: 'VN',
    nameKo: '베트남',
    flag: '🇻🇳',
    currency: Currency(
        code: 'VND', name: '베트남 동', symbol: '₫', flag: '🇻🇳'),
    emergencyGeneral: '113 (경찰)',
    emergencyContacts: [
      EmergencyContact(label: '경찰', number: '113', icon: '🚓'),
      EmergencyContact(label: '소방', number: '114', icon: '🚒'),
      EmergencyContact(label: '구급', number: '115', icon: '🚑'),
    ],
    embassy: Embassy(
      name: '주베트남 대한민국 대사관 (하노이)',
      address: 'SQ4 Diplomatic Complex, Do Nhuan St, Xuan Tao, Bac Tu Liem, Hanoi',
      phone: '+84-24-3831-5110',
      emergencyPhone: '+84-90-402-6126',
      lat: 21.0645,
      lng: 105.7823,
    ),
    phrases: [
      PhraseCard(ko: '도와주세요!', local: 'Giúp tôi với!', pron: '지웁 또이 버이'),
      PhraseCard(ko: '경찰을 불러주세요', local: 'Hãy gọi cảnh sát', pron: '하이 고이 까잉 삳'),
      PhraseCard(ko: '병원에 가야 해요', local: 'Tôi cần đến bệnh viện', pron: '또이 껀 덴 벤 비엔'),
      PhraseCard(ko: '여권을 잃어버렸어요', local: 'Tôi bị mất hộ chiếu', pron: '또이 비 멋 호 찌에우'),
      PhraseCard(ko: '이거 얼마예요?', local: 'Cái này bao nhiêu tiền?', pron: '까이 나이 바오 니에우 띠엔'),
    ],
    phrasebook: [
      PhraseGroup(title: '기본 · 인사', icon: Icons.waving_hand, items: [
        PhraseCard(ko: '안녕하세요', local: 'Xin chào', pron: '신 짜오'),
        PhraseCard(ko: '감사합니다', local: 'Cảm ơn', pron: '깜 언'),
        PhraseCard(ko: '네 / 아니요', local: 'Vâng / Không', pron: '벙 / 콤'),
        PhraseCard(ko: '미안합니다', local: 'Xin lỗi', pron: '신 로이'),
        PhraseCard(
            ko: '영어 할 줄 아세요?',
            local: 'Bạn nói tiếng Anh được không?',
            pron: '반 노이 띠엥 아잉 드억 콤'),
      ]),
      PhraseGroup(title: '쇼핑 · 흥정', icon: Icons.shopping_bag, items: [
        PhraseCard(
            ko: '이거 얼마예요?',
            local: 'Cái này bao nhiêu tiền?',
            pron: '까이 나이 바오 니에우 띠엔'),
        PhraseCard(ko: '너무 비싸요', local: 'Đắt quá', pron: '닫 꾸아'),
        PhraseCard(ko: '깎아주세요', local: 'Giảm giá đi', pron: '지암 자 디'),
        PhraseCard(
            ko: '이거 주세요', local: 'Cho tôi cái này', pron: '쩌 또이 까이 나이'),
        PhraseCard(
            ko: '카드 되나요?',
            local: 'Có nhận thẻ không?',
            pron: '꺼 년 테 콤'),
      ]),
      PhraseGroup(title: '식당 · 주문', icon: Icons.restaurant, items: [
        PhraseCard(
            ko: '메뉴 주세요',
            local: 'Cho tôi xem thực đơn',
            pron: '쩌 또이 셈 특 던'),
        PhraseCard(
            ko: '이거 주세요', local: 'Cho tôi món này', pron: '쩌 또이 몬 나이'),
        PhraseCard(ko: '계산할게요', local: 'Tính tiền', pron: '띤 띠엔'),
        PhraseCard(ko: '안 맵게 해주세요', local: 'Đừng cay', pron: '등 까이'),
        PhraseCard(ko: '맛있어요', local: 'Ngon quá', pron: '응온 꾸아'),
      ]),
      PhraseGroup(title: '길 · 교통', icon: Icons.directions, items: [
        PhraseCard(
            ko: '화장실 어디예요?',
            local: 'Nhà vệ sinh ở đâu?',
            pron: '냐 베 신 어 더우'),
        PhraseCard(
            ko: '여기 어떻게 가요?',
            local: 'Đi đến đây thế nào?',
            pron: '디 덴 더이 테 나오'),
        PhraseCard(
            ko: '미터기 켜주세요', local: 'Bật đồng hồ đi', pron: '벗 동 호 디'),
        PhraseCard(
            ko: '여기 세워주세요',
            local: 'Cho tôi xuống đây',
            pron: '쩌 또이 쑤옹 더이'),
      ]),
      PhraseGroup(title: '숙소', icon: Icons.hotel, items: [
        PhraseCard(
            ko: '체크인 할게요',
            local: 'Tôi muốn nhận phòng',
            pron: '또이 무온 년 퐁'),
        PhraseCard(
            ko: '와이파이 비밀번호가 뭐예요?',
            local: 'Mật khẩu wifi là gì?',
            pron: '멋 커우 와이파이 라 지'),
        PhraseCard(
            ko: '짐 맡길 수 있어요?',
            local: 'Tôi gửi hành lý được không?',
            pron: '또이 그이 하잉 리 드억 콤'),
      ]),
    ],
    cashTips: [
      'ATM은 Vietcombank·BIDV·Techcombank 등 대형은행이 안전. 인출 수수료·한도 먼저 확인',
      '공항 환전보다 시내 금은방(vàng)·환전소가 환율이 유리',
      '10만동과 1만동 지폐 색이 비슷 — 0 개수 꼭 확인(바가지 주의)',
      '택시는 Grab 앱 이용이 바가지 방지에 최선',
    ],
    plug: PlugInfo(
      voltage: '220V · 50Hz',
      types: ['A', 'C'],
      note: 'C형 콘센트가 흔해 한국 플러그가 대체로 꽂힘. 멀티 어댑터 있으면 안심',
    ),
    cheatsheet: [
      CheatSection(title: '통신 · 인터넷', icon: Icons.sim_card, items: [
        'Viettel·Vinaphone 관광 유심이 저렴, eSIM도 가능(여권 필요)',
        '무료 와이파이 흔하지만 속도 편차 큼 — 데이터 유심 권장',
        '관광지 밖은 영어 잘 안 통함 → 번역앱 준비',
      ]),
      CheatSection(title: '교통 · 이동', icon: Icons.local_taxi, items: [
        'Grab(차·오토바이) 필수 — 미터 조작·바가지 방지',
        '오토바이 물결이 심함. 길 건널 땐 멈추지 말고 천천히 일정 속도로',
        '공항→시내는 Grab 또는 공식 택시 카운터 이용',
      ]),
      CheatSection(title: '결제 · 팁', icon: Icons.payments, items: [
        '대도시는 카드 되지만 소액·시장은 현금',
        '팁 문화는 약한 편(고급 식당·스파 정도)',
      ]),
      CheatSection(title: '물 · 음식', icon: Icons.restaurant, items: [
        '수돗물 X, 생수만. 얼음은 관광 식당은 대체로 안전',
        '붐비는 노점이 회전이 빨라 오히려 신선',
      ]),
      CheatSection(title: '문화 · 예절', icon: Icons.volunteer_activism, items: [
        '사원·능묘에선 노출 심한 옷 자제',
        '어른 머리 만지기 실례, 물건은 두 손으로 주고받기',
      ]),
      CheatSection(title: '치안 · 사기 주의', icon: Icons.shield, items: [
        '오토바이 날치기(가방·휴대폰) 주의 — 인도 안쪽으로 걷기',
        '택시 사칭·거스름돈 사기 → Grab 이용이 안전',
        '환전은 은행·공식 환전소에서만',
      ]),
    ],
  ),

  // ═══════════════════════════ 일본 ═══════════════════════════
  Country(
    code: 'JP',
    nameKo: '일본',
    flag: '🇯🇵',
    currency: Currency(
        code: 'JPY', name: '일본 엔', symbol: '¥', flag: '🇯🇵'),
    emergencyGeneral: '110 (경찰) / 119 (구급·소방)',
    emergencyContacts: [
      EmergencyContact(label: '경찰', number: '110', icon: '🚓'),
      EmergencyContact(label: '구급·소방', number: '119', icon: '🚑'),
      EmergencyContact(label: '해상긴급', number: '118', icon: '⛴️'),
    ],
    embassy: Embassy(
      name: '주일본 대한민국 대사관 (도쿄)',
      address: '1-2-5 Minami-Azabu, Minato-ku, Tokyo',
      phone: '+81-3-3452-7611',
      emergencyPhone: '+81-90-1693-5773',
      lat: 35.6512,
      lng: 139.7305,
    ),
    phrases: [
      PhraseCard(ko: '도와주세요!', local: '助けてください', pron: '다스케테 쿠다사이'),
      PhraseCard(ko: '경찰을 불러주세요', local: '警察を呼んでください', pron: '케이사츠오 욘데 쿠다사이'),
      PhraseCard(ko: '병원에 가야 해요', local: '病院に行きたいです', pron: '뵤-인니 이키타이데스'),
      PhraseCard(ko: '여권을 잃어버렸어요', local: 'パスポートをなくしました', pron: '파스포-토오 나쿠시마시타'),
      PhraseCard(ko: '이거 얼마예요?', local: 'これはいくらですか', pron: '코레와 이쿠라데스카'),
    ],
    phrasebook: [
      PhraseGroup(title: '기본 · 인사', icon: Icons.waving_hand, items: [
        PhraseCard(ko: '안녕하세요', local: 'こんにちは', pron: '곤니치와'),
        PhraseCard(
            ko: '감사합니다', local: 'ありがとうございます', pron: '아리가토- 고자이마스'),
        PhraseCard(ko: '네 / 아니요', local: 'はい / いいえ', pron: '하이 / 이이에'),
        PhraseCard(ko: '실례합니다 / 미안해요', local: 'すみません', pron: '스미마셍'),
        PhraseCard(
            ko: '영어 되세요?', local: '英語できますか', pron: '에이고 데키마스카'),
      ]),
      PhraseGroup(title: '쇼핑 · 계산', icon: Icons.shopping_bag, items: [
        PhraseCard(
            ko: '이거 얼마예요?', local: 'これはいくらですか', pron: '코레와 이쿠라데스카'),
        PhraseCard(ko: '이거 주세요', local: 'これください', pron: '코레 쿠다사이'),
        PhraseCard(
            ko: '카드 되나요?', local: 'カードは使えますか', pron: '카-도와 츠카에마스카'),
        PhraseCard(ko: '봉투 주세요', local: '袋ください', pron: '후쿠로 쿠다사이'),
        PhraseCard(
            ko: '면세 되나요?', local: '免税できますか', pron: '멘제이 데키마스카'),
      ]),
      PhraseGroup(title: '식당 · 주문', icon: Icons.restaurant, items: [
        PhraseCard(ko: '메뉴 주세요', local: 'メニューください', pron: '메뉴- 쿠다사이'),
        PhraseCard(
            ko: '이거 주세요', local: 'これをお願いします', pron: '코레오 오네가이시마스'),
        PhraseCard(
            ko: '계산할게요',
            local: 'お会計お願いします',
            pron: '오카이케- 오네가이시마스'),
        PhraseCard(ko: '물 주세요', local: 'お水ください', pron: '오미즈 쿠다사이'),
        PhraseCard(ko: '맛있어요', local: 'おいしいです', pron: '오이시이데스'),
      ]),
      PhraseGroup(title: '길 · 교통', icon: Icons.directions, items: [
        PhraseCard(
            ko: '화장실 어디예요?', local: 'トイレはどこですか', pron: '토이레와 도코데스카'),
        PhraseCard(ko: '역이 어디예요?', local: '駅はどこですか', pron: '에키와 도코데스카'),
        PhraseCard(
            ko: '여기 어떻게 가요?',
            local: 'ここへはどう行きますか',
            pron: '코코에와 도- 이키마스카'),
        PhraseCard(
            ko: '여기 세워주세요',
            local: 'ここで止めてください',
            pron: '코코데 토메테 쿠다사이'),
      ]),
      PhraseGroup(title: '숙소', icon: Icons.hotel, items: [
        PhraseCard(
            ko: '체크인 할게요',
            local: 'チェックインお願いします',
            pron: '체쿠인 오네가이시마스'),
        PhraseCard(
            ko: '와이파이 비밀번호가 뭐예요?',
            local: 'WiFiのパスワードは何ですか',
            pron: '와이화이노 파스와-도와 난데스카'),
        PhraseCard(
            ko: '짐 맡길 수 있어요?',
            local: '荷物を預けられますか',
            pron: '니모츠오 아즈케라레마스카'),
      ]),
    ],
    cashTips: [
      '세븐일레븐(세븐뱅크) ATM이 해외카드 인출에 가장 무난',
      '아직 현금 많이 쓰는 나라 — 소액 현금 필수',
      'IC카드(Suica/Pasmo)로 교통·편의점 결제가 편리',
      '면세(Tax free) 받으려면 여권 지참',
    ],
    plug: PlugInfo(
      voltage: '100V · 50/60Hz',
      types: ['A'],
      note: '한국 플러그 안 맞음 → 어댑터 필수. 전압도 100V로 낮아 고전력 기기 주의',
    ),
    cheatsheet: [
      CheatSection(title: '통신 · 인터넷', icon: Icons.sim_card, items: [
        '공항 유심·eSIM 편리, 관광객용 데이터 유심 다양',
        '무료 와이파이는 제한적 — 데이터 준비 권장',
      ]),
      CheatSection(title: '교통 · 이동', icon: Icons.train, items: [
        'Suica/Pasmo(IC카드)로 전철·버스·편의점 결제',
        '장거리는 JR패스 검토(구간·기간 계산 필수)',
        '막차가 빠른 편(자정 전후) — 시간 확인',
        '차량·보행 좌측통행. 에스컬레이터 서는 쪽 지역마다 다름(도쿄 왼쪽/오사카 오른쪽)',
      ]),
      CheatSection(title: '결제 · 팁', icon: Icons.payments, items: [
        '현금 여전히 중요 — 소액 지참',
        '팁 문화 없음(놓고 가면 돌려주려 함)',
      ]),
      CheatSection(title: '물 · 음식', icon: Icons.local_drink, items: [
        '수돗물 음용 가능',
        '식당서 큰 소리 통화 자제, 남기지 않는 문화',
      ]),
      CheatSection(title: '문화 · 예절', icon: Icons.volunteer_activism, items: [
        '줄서기·정숙 철저, 실내 신발 벗는 곳 많음',
        '길거리 쓰레기통 적음 — 쓰레기 되가져가기',
        '계산은 돈 트레이에 올려놓기',
      ]),
      CheatSection(title: '치안 · 안전', icon: Icons.shield, items: [
        '치안 매우 좋음(분실물도 잘 돌아오는 편)',
        '지진 대비 — 흔들리면 머리 보호, 엘리베이터 이용 금지',
      ]),
    ],
  ),

  // ═══════════════════════════ 대만 ═══════════════════════════
  Country(
    code: 'TW',
    nameKo: '대만',
    flag: '🇹🇼',
    currency: Currency(
        code: 'TWD', name: '신 대만 달러', symbol: 'NT\$', flag: '🇹🇼'),
    emergencyGeneral: '110 (경찰) / 119 (구급·소방)',
    emergencyContacts: [
      EmergencyContact(label: '경찰', number: '110', icon: '🚓'),
      EmergencyContact(label: '구급·소방', number: '119', icon: '🚑'),
      EmergencyContact(label: '관광안내', number: '0800-011-765', icon: 'ℹ️'),
    ],
    embassy: Embassy(
      name: '주타이베이 대한민국 대표부',
      address: '15F, No. 333, Sec. 1, Keelung Rd, Xinyi Dist, Taipei',
      phone: '+886-2-2758-8320',
      emergencyPhone: '+886-912-069-482',
      lat: 25.0328,
      lng: 121.5645,
    ),
    phrases: [
      PhraseCard(ko: '도와주세요!', local: '請幫幫我', pron: '칭 빵빵 워'),
      PhraseCard(ko: '경찰을 불러주세요', local: '請幫我叫警察', pron: '칭 빵 워 지아오 징차'),
      PhraseCard(ko: '병원에 가야 해요', local: '我需要去醫院', pron: '워 쉬야오 취 이위엔'),
      PhraseCard(ko: '여권을 잃어버렸어요', local: '我的護照不見了', pron: '워더 후자오 부지엔러'),
      PhraseCard(ko: '이거 얼마예요?', local: '這個多少錢', pron: '저거 둬사오 치엔'),
    ],
    phrasebook: [
      PhraseGroup(title: '기본 · 인사', icon: Icons.waving_hand, items: [
        PhraseCard(ko: '안녕하세요', local: '你好', pron: '니 하오'),
        PhraseCard(ko: '감사합니다', local: '謝謝', pron: '씨에씨에'),
        PhraseCard(ko: '네 / 아니요', local: '是 / 不是', pron: '스 / 부스'),
        PhraseCard(ko: '미안합니다', local: '對不起', pron: '뚜이부치'),
        PhraseCard(
            ko: '영어 되세요?', local: '你會說英文嗎', pron: '니 후이 슈어 잉원 마'),
      ]),
      PhraseGroup(title: '쇼핑 · 흥정', icon: Icons.shopping_bag, items: [
        PhraseCard(ko: '이거 얼마예요?', local: '這個多少錢', pron: '저거 둬사오 치엔'),
        PhraseCard(ko: '너무 비싸요', local: '太貴了', pron: '타이 꾸이 러'),
        PhraseCard(
            ko: '깎아주세요',
            local: '可以便宜一點嗎',
            pron: '커이 피엔이 이디엔 마'),
        PhraseCard(ko: '이거 주세요', local: '我要這個', pron: '워 야오 저거'),
        PhraseCard(ko: '카드 되나요?', local: '可以刷卡嗎', pron: '커이 슈아 카 마'),
      ]),
      PhraseGroup(title: '식당 · 주문', icon: Icons.restaurant, items: [
        PhraseCard(ko: '메뉴 주세요', local: '給我菜單', pron: '게이 워 차이단'),
        PhraseCard(ko: '이거 주세요', local: '我要這個', pron: '워 야오 저거'),
        PhraseCard(ko: '계산할게요', local: '買單', pron: '마이 단'),
        PhraseCard(ko: '안 맵게 해주세요', local: '不要辣', pron: '부야오 라'),
        PhraseCard(ko: '맛있어요', local: '很好吃', pron: '헌 하오츠'),
      ]),
      PhraseGroup(title: '길 · 교통', icon: Icons.directions, items: [
        PhraseCard(
            ko: '화장실 어디예요?', local: '廁所在哪裡', pron: '처수어 짜이 나리'),
        PhraseCard(ko: '여기 어떻게 가요?', local: '這裡怎麼走', pron: '저리 전머 저우'),
        PhraseCard(
            ko: 'MRT역 어디예요?',
            local: '捷運站在哪裡',
            pron: '지에윈 잔 짜이 나리'),
        PhraseCard(ko: '여기 세워주세요', local: '在這裡停', pron: '짜이 저리 팅'),
      ]),
      PhraseGroup(title: '숙소', icon: Icons.hotel, items: [
        PhraseCard(ko: '체크인 할게요', local: '我要辦理入住', pron: '워 야오 반리 루주'),
        PhraseCard(
            ko: '와이파이 비밀번호가 뭐예요?',
            local: 'WiFi密碼是多少',
            pron: '와이화이 미마 스 둬사오'),
        PhraseCard(
            ko: '짐 맡길 수 있어요?',
            local: '可以寄放行李嗎',
            pron: '커이 지팡 싱리 마'),
      ]),
    ],
    cashTips: [
      '편의점(세븐일레븐/패밀리마트) ATM 또는 대형은행 이용',
      '悠遊卡(이지카드) 충전해 교통·편의점 결제 편리',
      '야시장은 현금만 받는 곳 많음 — 소액권 준비',
      '대형 상점 외엔 카드 안 되는 곳 많음',
    ],
    plug: PlugInfo(
      voltage: '110V · 60Hz',
      types: ['A'],
      note: '한국 플러그 안 맞음 → 어댑터 필요. 전압 110V',
    ),
    cheatsheet: [
      CheatSection(title: '통신 · 인터넷', icon: Icons.sim_card, items: [
        '공항 유심(무제한 데이터)이 저렴, eSIM 가능',
        '무료 와이파이(iTaiwan) 있으나 데이터 유심이 편함',
      ]),
      CheatSection(title: '교통 · 이동', icon: Icons.directions_subway, items: [
        '悠遊卡(요요카/EasyCard)로 MRT·버스·편의점 결제',
        'MRT 안에서 음식·음료·껌 금지(벌금 부과)',
        '시내는 MRT+버스로 충분, 택시도 저렴한 편',
      ]),
      CheatSection(title: '결제 · 팁', icon: Icons.payments, items: [
        '야시장·소상점은 현금 위주 — 소액권 준비',
        '팁 문화 거의 없음',
      ]),
      CheatSection(title: '물 · 음식', icon: Icons.local_drink, items: [
        '수돗물은 끓여 마시는 게 일반적 — 생수 권장',
        '야시장 먹거리 천국(굴전·버블티·지파이)',
      ]),
      CheatSection(title: '문화 · 안전', icon: Icons.shield, items: [
        '치안 양호, 소매치기 드문 편',
        '스콜·태풍 시즌 우산·일정 여유 두기',
        '양안(정치) 화제는 조심스럽게',
      ]),
    ],
  ),

  // ═══════════════════════════ 태국 ═══════════════════════════
  Country(
    code: 'TH',
    nameKo: '태국',
    flag: '🇹🇭',
    currency: Currency(
        code: 'THB', name: '태국 밧', symbol: '฿', flag: '🇹🇭'),
    emergencyGeneral: '191 (경찰) / 1155 (관광경찰)',
    emergencyContacts: [
      EmergencyContact(label: '경찰', number: '191', icon: '🚓'),
      EmergencyContact(label: '관광경찰', number: '1155', icon: '🛂'),
      EmergencyContact(label: '구급', number: '1669', icon: '🚑'),
      EmergencyContact(label: '소방', number: '199', icon: '🚒'),
    ],
    embassy: Embassy(
      name: '주태국 대한민국 대사관 (방콕)',
      address: '23 Thiam-Ruammit Rd, Ratchadapisek, Huai Khwang, Bangkok',
      phone: '+66-2-247-7537',
      emergencyPhone: '+66-81-914-5803',
      lat: 13.7842,
      lng: 100.5745,
    ),
    phrases: [
      PhraseCard(ko: '도와주세요!', local: 'ช่วยด้วย', pron: '추어이 두어이'),
      PhraseCard(ko: '경찰을 불러주세요', local: 'ช่วยเรียกตำรวจ', pron: '추어이 리약 땀루엇'),
      PhraseCard(ko: '병원에 가야 해요', local: 'ฉันต้องไปโรงพยาบาล', pron: '찬 떵 빠이 롱파야반'),
      PhraseCard(ko: '여권을 잃어버렸어요', local: 'ฉันทำพาสปอร์ตหาย', pron: '찬 탐 파-사폿 하이'),
      PhraseCard(ko: '이거 얼마예요?', local: 'อันนี้เท่าไหร่', pron: '안니 타올라이'),
    ],
    phrasebook: [
      PhraseGroup(title: '기본 · 인사', icon: Icons.waving_hand, items: [
        PhraseCard(
            ko: '안녕하세요', local: 'สวัสดี (ครับ/ค่ะ)', pron: '사왓디 (캅/카)'),
        PhraseCard(ko: '감사합니다', local: 'ขอบคุณ (ครับ/ค่ะ)', pron: '컵쿤 (캅/카)'),
        PhraseCard(ko: '네 / 아니요', local: 'ใช่ / ไม่', pron: '차이 / 마이'),
        PhraseCard(ko: '실례합니다 / 미안해요', local: 'ขอโทษ', pron: '커톳'),
        PhraseCard(
            ko: '영어 되세요?',
            local: 'พูดภาษาอังกฤษได้ไหม',
            pron: '풋 파사 앙끄릿 다이 마이'),
      ]),
      PhraseGroup(title: '쇼핑 · 흥정', icon: Icons.shopping_bag, items: [
        PhraseCard(ko: '이거 얼마예요?', local: 'อันนี้เท่าไหร่', pron: '안니 타올라이'),
        PhraseCard(ko: '너무 비싸요', local: 'แพงไป', pron: '팽 빠이'),
        PhraseCard(ko: '깎아주세요', local: 'ลดได้ไหม', pron: '롯 다이 마이'),
        PhraseCard(ko: '이거 주세요', local: 'เอาอันนี้', pron: '아오 안니'),
        PhraseCard(ko: '카드 되나요?', local: 'รับบัตรไหม', pron: '랍 밧 마이'),
      ]),
      PhraseGroup(title: '식당 · 주문', icon: Icons.restaurant, items: [
        PhraseCard(ko: '메뉴 주세요', local: 'ขอเมนู', pron: '커 메누'),
        PhraseCard(ko: '계산할게요', local: 'เช็คบิล', pron: '첵 빈'),
        PhraseCard(ko: '안 맵게 해주세요', local: 'ไม่เผ็ด', pron: '마이 펫'),
        PhraseCard(ko: '물 주세요', local: 'ขอน้ำ', pron: '커 남'),
        PhraseCard(ko: '맛있어요', local: 'อร่อย', pron: '아러이'),
      ]),
      PhraseGroup(title: '길 · 교통', icon: Icons.directions, items: [
        PhraseCard(
            ko: '화장실 어디예요?',
            local: 'ห้องน้ำอยู่ที่ไหน',
            pron: '헝남 유 티나이'),
        PhraseCard(
            ko: '여기 어떻게 가요?',
            local: 'ไปที่นี่ยังไง',
            pron: '빠이 티니 양응아이'),
        PhraseCard(
            ko: '미터기 켜주세요',
            local: 'เปิดมิเตอร์ด้วย',
            pron: '뻣 미떠 두어이'),
        PhraseCard(ko: '여기 세워주세요', local: 'จอดตรงนี้', pron: '쩟 뜨롱니'),
      ]),
      PhraseGroup(title: '숙소', icon: Icons.hotel, items: [
        PhraseCard(ko: '체크인 할게요', local: 'เช็คอิน', pron: '첵인'),
        PhraseCard(
            ko: '와이파이 비밀번호가 뭐예요?',
            local: 'รหัสไวไฟอะไร',
            pron: '라핫 와이파이 아라이'),
        PhraseCard(
            ko: '짐 맡길 수 있어요?',
            local: 'ฝากกระเป๋าได้ไหม',
            pron: '확 끄라빠오 다이 마이'),
      ]),
    ],
    cashTips: [
      'ATM 인출 시 현지 수수료 약 220밧 부과 — 한 번에 크게 인출이 유리',
      '공항보다 시내 Superrich 등 환전소 환율이 좋음',
      '택시는 미터기(meter) 요구, 안 되면 Grab 이용',
      '소액권(20·100밧)은 팁·시장용으로 챙겨두기',
    ],
    plug: PlugInfo(
      voltage: '220V · 50Hz',
      types: ['A', 'C'],
      note: 'C형 콘센트가 있어 한국 플러그가 대체로 꽂힘. A형 전용엔 어댑터',
    ),
    cheatsheet: [
      CheatSection(title: '통신 · 인터넷', icon: Icons.sim_card, items: [
        '공항 AIS·TrueMove 관광 유심 저렴, eSIM 가능',
        '관광지는 영어 통함, 외곽은 번역앱',
      ]),
      CheatSection(title: '교통 · 이동', icon: Icons.local_taxi, items: [
        '방콕은 BTS/MRT + Grab 조합이 편리',
        '택시는 미터기 요구, 툭툭·택시 흥정 바가지 잦음 → Grab 권장',
        '국내 이동은 저가항공·야간버스가 저렴',
      ]),
      CheatSection(title: '결제 · 팁', icon: Icons.payments, items: [
        '관광지는 카드, 노점·시장은 현금',
        '팁 문화 있음 — 20밧 내외(동전 잔돈은 팁으로 안 함)',
      ]),
      CheatSection(title: '물 · 음식', icon: Icons.restaurant, items: [
        '수돗물 X, 생수. 길거리 음식은 위생 보고 선택',
        '안 맵게: "마이 펫"이라고 말하기',
      ]),
      CheatSection(title: '문화 · 예절', icon: Icons.temple_buddhist, items: [
        '★왕실 모독 엄금(법적 처벌) — 지폐·초상 훼손 금지',
        '사원 복장(어깨·무릎 가리기)·신발 벗기, 발로 물건 가리키기 금기',
        '머리 만지지 않기, 승려와 여성의 신체 접촉 주의',
      ]),
      CheatSection(title: '치안 · 사기 주의', icon: Icons.shield, items: [
        '보석·투어 호객, "사원 문 닫았다" 유도 사기 주의',
        '제트스키·오토바이 렌트 파손 클레임 사기 흔함 — 대여 전 사진 촬영',
        '환전은 Superrich 등 공식 환전소',
      ]),
    ],
  ),
];

/// 홈(KRW)·USD 포함 전체 통화 목록
final List<Currency> allCurrencies = [
  krw,
  usd,
  ...countries.map((c) => c.currency),
];

/// 코드로 통화 찾기
Currency currencyByCode(String code) =>
    allCurrencies.firstWhere((c) => c.code == code, orElse: () => krw);

/// 국가 코드 → TTS(음성 합성) 로케일. 기기 내장 음성 엔진에 넘겨 현지어를 읽어준다.
String ttsLocaleOf(String countryCode) {
  switch (countryCode) {
    case 'VN':
      return 'vi-VN';
    case 'JP':
      return 'ja-JP';
    case 'TW':
      return 'zh-TW';
    case 'TH':
      return 'th-TH';
    default:
      return 'en-US';
  }
}
