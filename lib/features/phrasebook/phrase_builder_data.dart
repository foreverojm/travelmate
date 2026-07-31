import 'package:flutter/material.dart';

/// 조합형 문구 만들기 데이터.
/// 자유 번역(구글 번역)이 아니라, 검증된 «동작 패턴 + 대상» 조합으로
/// 오프라인에서도 문법이 안전한 현지어 문장과 한글 발음을 만든다.
/// 언어 키 = 국가 코드(VN/JP/TW/TH).

class BuilderItem {
  final String ko;
  final Map<String, String> local; // 국가코드 -> 현지어(대상)
  final Map<String, String> pron; // 국가코드 -> 한글 발음(대상)
  const BuilderItem(this.ko, this.local, this.pron);
}

class BuilderTemplate {
  final String ko; // '{x} 주세요'
  final IconData icon;
  final Map<String, String> pattern; // 국가코드 -> 'Cho tôi {x}'
  final Map<String, String> patternPron; // 국가코드 -> '쩌 또이 {x}'
  final List<BuilderItem> items;
  const BuilderTemplate({
    required this.ko,
    required this.icon,
    required this.pattern,
    required this.patternPron,
    required this.items,
  });

  String koFor(BuilderItem it) => ko.replaceFirst('{x}', it.ko);
  String localFor(String cc, BuilderItem it) =>
      (pattern[cc] ?? '{x}').replaceFirst('{x}', it.local[cc] ?? '');
  String pronFor(String cc, BuilderItem it) =>
      (patternPron[cc] ?? '{x}').replaceFirst('{x}', it.pron[cc] ?? '');
}

const List<BuilderTemplate> builderTemplates = [
  // ── 주세요 ─────────────────────────────
  BuilderTemplate(
    ko: '{x} 주세요',
    icon: Icons.add_shopping_cart,
    pattern: {
      'VN': 'Cho tôi {x}',
      'JP': '{x}をください',
      'TW': '我要{x}',
      'TH': 'ขอ{x}',
    },
    patternPron: {
      'VN': '쩌 또이 {x}',
      'JP': '{x}오 쿠다사이',
      'TW': '워 야오 {x}',
      'TH': '커 {x}',
    },
    items: [
      BuilderItem('커피',
          {'VN': 'cà phê', 'JP': 'コーヒー', 'TW': '咖啡', 'TH': 'กาแฟ'},
          {'VN': '카페', 'JP': '코-히-', 'TW': '카페이', 'TH': '까페'}),
      BuilderItem('물', {'VN': 'nước', 'JP': 'お水', 'TW': '水', 'TH': 'น้ำ'},
          {'VN': '느억', 'JP': '오미즈', 'TW': '슈이', 'TH': '남'}),
      BuilderItem('맥주', {'VN': 'bia', 'JP': 'ビール', 'TW': '啤酒', 'TH': 'เบียร์'},
          {'VN': '비아', 'JP': '비-루', 'TW': '피지우', 'TH': '비아'}),
      BuilderItem(
          '계산서',
          {'VN': 'tính tiền', 'JP': 'お会計', 'TW': '買單', 'TH': 'เช็คบิล'},
          {'VN': '띤 띠엔', 'JP': '오카이케-', 'TW': '마이단', 'TH': '첵빈'}),
      BuilderItem('봉투', {'VN': 'túi', 'JP': '袋', 'TW': '袋子', 'TH': 'ถุง'},
          {'VN': '뚜이', 'JP': '후쿠로', 'TW': '따이즈', 'TH': '퉁'}),
    ],
  ),

  // ── 빼주세요 ───────────────────────────
  BuilderTemplate(
    ko: '{x} 빼주세요',
    icon: Icons.remove_circle_outline,
    pattern: {
      'VN': 'Không {x}',
      'JP': '{x}抜きで',
      'TW': '不要{x}',
      'TH': 'ไม่ใส่{x}',
    },
    patternPron: {
      'VN': '콤 {x}',
      'JP': '{x} 누키데',
      'TW': '부야오 {x}',
      'TH': '마이 사이 {x}',
    },
    items: [
      BuilderItem('얼음', {'VN': 'đá', 'JP': '氷', 'TW': '冰', 'TH': 'น้ำแข็ง'},
          {'VN': '다', 'JP': '코-리', 'TW': '빙', 'TH': '남캥'}),
      BuilderItem(
          '고수',
          {'VN': 'rau mùi', 'JP': 'パクチー', 'TW': '香菜', 'TH': 'ผักชี'},
          {'VN': '자우 무이', 'JP': '파쿠치-', 'TW': '샹차이', 'TH': '팍치'}),
      BuilderItem('설탕',
          {'VN': 'đường', 'JP': '砂糖', 'TW': '糖', 'TH': 'น้ำตาล'},
          {'VN': '드엉', 'JP': '사토-', 'TW': '탕', 'TH': '남딴'}),
      BuilderItem(
          '땅콩',
          {'VN': 'đậu phộng', 'JP': 'ピーナッツ', 'TW': '花生', 'TH': 'ถั่ว'},
          {'VN': '더우 퐁', 'JP': '피-낫츠', 'TW': '화성', 'TH': '투아'}),
    ],
  ),

  // ── 어디예요? ──────────────────────────
  BuilderTemplate(
    ko: '{x} 어디예요?',
    icon: Icons.place_outlined,
    pattern: {
      'VN': '{x} ở đâu?',
      'JP': '{x}はどこですか',
      'TW': '{x}在哪裡',
      'TH': '{x}อยู่ที่ไหน',
    },
    patternPron: {
      'VN': '{x} 어 더우',
      'JP': '{x}와 도코데스카',
      'TW': '{x} 짜이 나리',
      'TH': '{x} 유 티나이',
    },
    items: [
      BuilderItem(
          '화장실',
          {'VN': 'nhà vệ sinh', 'JP': 'トイレ', 'TW': '廁所', 'TH': 'ห้องน้ำ'},
          {'VN': '냐 베 신', 'JP': '토이레', 'TW': '처수어', 'TH': '헝남'}),
      BuilderItem('역',
          {'VN': 'ga tàu', 'JP': '駅', 'TW': '車站', 'TH': 'สถานี'},
          {'VN': '가 따우', 'JP': '에키', 'TW': '처잔', 'TH': '사타니'}),
      BuilderItem(
          '편의점',
          {
            'VN': 'cửa hàng tiện lợi',
            'JP': 'コンビニ',
            'TW': '便利商店',
            'TH': 'ร้านสะดวกซื้อ'
          },
          {
            'VN': '끄어 항 띠엔 러이',
            'JP': '콤비니',
            'TW': '삐엔리 샹디엔',
            'TH': '란 사두억 쓰'
          }),
      BuilderItem('ATM',
          {'VN': 'máy ATM', 'JP': 'ATM', 'TW': '提款機', 'TH': 'ตู้เอทีเอ็ม'},
          {'VN': '마이 에이티엠', 'JP': '에이티-에무', 'TW': '티콴지', 'TH': '뚜 에티엠'}),
      BuilderItem('택시',
          {'VN': 'taxi', 'JP': 'タクシー', 'TW': '計程車', 'TH': 'แท็กซี่'},
          {'VN': '딱시', 'JP': '타쿠시-', 'TW': '지청처', 'TH': '택시'}),
    ],
  ),

  // ── 얼마예요? ──────────────────────────
  BuilderTemplate(
    ko: '{x} 얼마예요?',
    icon: Icons.sell_outlined,
    pattern: {
      'VN': '{x} bao nhiêu tiền?',
      'JP': '{x}はいくらですか',
      'TW': '{x}多少錢',
      'TH': '{x}เท่าไหร่',
    },
    patternPron: {
      'VN': '{x} 바오 니에우 띠엔',
      'JP': '{x}와 이쿠라데스카',
      'TW': '{x} 둬사오 치엔',
      'TH': '{x} 타올라이',
    },
    items: [
      BuilderItem('이거',
          {'VN': 'cái này', 'JP': 'これ', 'TW': '這個', 'TH': 'อันนี้'},
          {'VN': '까이 나이', 'JP': '코레', 'TW': '저거', 'TH': '안니'}),
      BuilderItem(
          '하룻밤(1박)',
          {'VN': 'một đêm', 'JP': '一泊', 'TW': '一晚', 'TH': 'หนึ่งคืน'},
          {'VN': '못 뎀', 'JP': '입파쿠', 'TW': '이 완', 'TH': '능 큰'}),
    ],
  ),
];
