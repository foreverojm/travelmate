/// 맛집·명소 데이터 모델 + 큐레이션 시드.
/// 차별화 핵심: 같은 도시라도 '관광객이 몰리는 곳'과 '현지인이 실제 가는 곳'을
/// 구분해서 보여준다. 랜드마크는 좌표를 넣어 지도 연동, 먹거리는 지역·설명 위주.
///
/// 데이터 확장 전략(무료): 직접 큐레이션 + (추후) OpenStreetMap Overwpass·Wikivoyage 등
/// 무료 오픈데이터로 좌표/기본정보 보강. '관광객/현지인' 태깅은 편집 큐레이션 유지.
///
/// OSM 수집분은 앱에 컴파일하지 않고 런타임에 JSON으로 로드(원격 갱신 → 앱 업데이트 불필요).
/// [PlacesRepository] 참고.
library;

enum PlaceKind { food, sight } // 맛집 / 명소

enum Audience { tourist, local } // 관광객 / 현지인

enum PlaceSource { curated, osm, wikivoyage } // 큐레이션 / OSM / Wikivoyage 가이드

class Place {
  final String countryCode;
  final String city;
  final String name;
  final PlaceKind kind;
  final Audience? audience; // OSM 수집분은 null(현지인/관광객 미분류)
  final String note;
  final String priceHint;
  final double? lat;
  final double? lng;
  final PlaceSource source;

  const Place({
    required this.countryCode,
    required this.city,
    required this.name,
    required this.kind,
    this.audience,
    required this.note,
    this.priceHint = '',
    this.lat,
    this.lng,
    this.source = PlaceSource.curated,
  });

  /// 원격/자산 JSON에서 파싱.
  /// OSM 수집분은 audience 미지정·source=osm, 큐레이션 보강분은 audience/가격/source=curated를
  /// JSON에 실어 보내므로 필드가 있으면 그대로 반영한다(하위 호환: 없으면 osm 취급).
  factory Place.fromJson(Map<String, dynamic> j) {
    final aud = j['audience'] as String?;
    final src = j['source'] as String?;
    return Place(
      countryCode: j['countryCode'] as String,
      city: j['city'] as String,
      name: j['name'] as String,
      kind: j['kind'] == 'food' ? PlaceKind.food : PlaceKind.sight,
      note: (j['note'] as String?) ?? '',
      priceHint: (j['priceHint'] as String?) ?? '',
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      audience: aud == 'tourist'
          ? Audience.tourist
          : aud == 'local'
              ? Audience.local
              : null,
      source: src == 'curated'
          ? PlaceSource.curated
          : src == 'wikivoyage'
              ? PlaceSource.wikivoyage
              : PlaceSource.osm,
    );
  }
}

/// 나라별 '한국인이 자주 가는 도시' 순서 (도시 필터에 사용)
const Map<String, List<String>> citiesByCountry = {
  'VN': ['하노이', '호치민', '다낭', '호이안', '나트랑', '푸꾸옥'],
  'JP': ['도쿄', '오사카', '교토', '후쿠오카', '삿포로', '오키나와'],
  'TW': ['타이베이', '타이중', '가오슝', '화롄'],
  'TH': ['방콕', '치앙마이', '푸켓', '파타야'],
};

/// 큐레이션 시드. (좌표가 있는 항목은 지도 버튼 노출)
const List<Place> seedPlaces = [
  // ═══════════════════════ 베트남 ═══════════════════════
  // ── 하노이 ──
  Place(countryCode: 'VN', city: '하노이', name: '호안끼엠 호수', kind: PlaceKind.sight, audience: Audience.tourist, note: '구시가지 중심 상징 호수. 주말 야간 보행자 거리', priceHint: '무료', lat: 21.0287, lng: 105.8524),
  Place(countryCode: 'VN', city: '하노이', name: '성 요셉 성당', kind: PlaceKind.sight, audience: Audience.tourist, note: '네오고딕 성당. 주변 카페 골목 인기', priceHint: '무료', lat: 21.0288, lng: 105.8489),
  Place(countryCode: 'VN', city: '하노이', name: '문묘 (Temple of Literature)', kind: PlaceKind.sight, audience: Audience.tourist, note: '베트남 최초의 대학. 정갈한 정원', priceHint: '₫ 3만', lat: 21.0294, lng: 105.8355),
  Place(countryCode: 'VN', city: '하노이', name: '기찻길 마을(Train Street)', kind: PlaceKind.sight, audience: Audience.tourist, note: '집 사이로 기차가 지나가는 명소. 통제되는 날 있음', priceHint: '카페 이용', lat: 21.0246, lng: 105.8467),
  Place(countryCode: 'VN', city: '하노이', name: '구시가 분짜(Bún chả) 골목', kind: PlaceKind.food, audience: Audience.local, note: '숯불 돼지고기+국수. 점심에 현지인이 몰리는 노포 밀집', priceHint: '₫ 4~7만'),
  Place(countryCode: 'VN', city: '하노이', name: '짜까(Chả cá) 생선요리', kind: PlaceKind.food, audience: Audience.local, note: '강황 생선구이를 테이블에서 볶아먹는 하노이 명물', priceHint: '₫ 12~20만'),
  Place(countryCode: 'VN', city: '하노이', name: '에그커피(Cà phê trứng)', kind: PlaceKind.food, audience: Audience.tourist, note: '달걀노른자 크림 커피. 구시가 노포 카페', priceHint: '₫ 3~5만'),
  // ── 호치민 ──
  Place(countryCode: 'VN', city: '호치민', name: '벤탄 시장', kind: PlaceKind.sight, audience: Audience.tourist, note: '기념품·먹거리 재래시장. 흥정 필수', priceHint: '무료입장', lat: 10.7721, lng: 106.6980),
  Place(countryCode: 'VN', city: '호치민', name: '중앙우체국 & 노트르담 성당', kind: PlaceKind.sight, audience: Audience.tourist, note: '프랑스 식민기 건축, 나란히 붙어 있음', priceHint: '무료', lat: 10.7797, lng: 106.6990),
  Place(countryCode: 'VN', city: '호치민', name: '통일궁', kind: PlaceKind.sight, audience: Audience.tourist, note: '옛 남베트남 대통령궁. 근현대사 현장', priceHint: '₫ 4만', lat: 10.7772, lng: 106.6958),
  Place(countryCode: 'VN', city: '호치민', name: '부이비엔 워킹스트리트', kind: PlaceKind.sight, audience: Audience.tourist, note: '배낭여행자 거리. 밤에 활기(소매치기 주의)', priceHint: '무료', lat: 10.7674, lng: 106.6931),
  Place(countryCode: 'VN', city: '호치민', name: '반미(Bánh mì) 노점', kind: PlaceKind.food, audience: Audience.local, note: '바게트 샌드위치. 출근길 현지인 노점이 가성비', priceHint: '₫ 2~4만'),
  Place(countryCode: 'VN', city: '호치민', name: '껌떰(Cơm tấm) 백반', kind: PlaceKind.food, audience: Audience.local, note: '부서진 쌀밥+숯불 돼지갈비. 현지인 대표 한 끼', priceHint: '₫ 4~6만'),
  // ── 다낭 ──
  Place(countryCode: 'VN', city: '다낭', name: '미케 비치', kind: PlaceKind.sight, audience: Audience.tourist, note: '길게 뻗은 백사장. 이른 아침·일몰이 좋음', priceHint: '무료', lat: 16.0596, lng: 108.2470),
  Place(countryCode: 'VN', city: '다낭', name: '용다리(Dragon Bridge)', kind: PlaceKind.sight, audience: Audience.tourist, note: '주말 밤 불·물 쇼(용머리 화염)', priceHint: '무료', lat: 16.0614, lng: 108.2277),
  Place(countryCode: 'VN', city: '다낭', name: '바나힐 & 골든브릿지', kind: PlaceKind.sight, audience: Audience.tourist, note: '손 얹은 황금 다리로 유명. 케이블카 필수', priceHint: '₫ 90만 내외', lat: 15.9977, lng: 107.9960),
  Place(countryCode: 'VN', city: '다낭', name: '한 시장(Han Market)', kind: PlaceKind.sight, audience: Audience.tourist, note: '시내 재래시장. 과일·건어물·기념품', priceHint: '무료입장', lat: 16.0678, lng: 108.2245),
  Place(countryCode: 'VN', city: '다낭', name: '미꽝(Mì Quảng)', kind: PlaceKind.food, audience: Audience.local, note: '중부 대표 비빔국수. 동네 국숫집이 진짜', priceHint: '₫ 3~5만'),
  Place(countryCode: 'VN', city: '다낭', name: '분짜까(Bún chả cá) 어묵국수', kind: PlaceKind.food, audience: Audience.local, note: '다낭식 어묵 쌀국수. 현지 아침 인기', priceHint: '₫ 3~4만'),
  // ── 호이안 ──
  Place(countryCode: 'VN', city: '호이안', name: '호이안 올드타운', kind: PlaceKind.sight, audience: Audience.tourist, note: '등불의 옛 도시. 야간 랜턴·소원배가 백미', priceHint: '통합권 ₫12만', lat: 15.8801, lng: 108.3280),
  Place(countryCode: 'VN', city: '호이안', name: '내원교(일본 다리)', kind: PlaceKind.sight, audience: Audience.tourist, note: '호이안 상징 다리. 지폐 도안에도 등장', priceHint: '통합권', lat: 15.8770, lng: 108.3260),
  Place(countryCode: 'VN', city: '호이안', name: '안방 비치', kind: PlaceKind.sight, audience: Audience.tourist, note: '올드타운 근교 해변. 한적하고 카페 많음', priceHint: '무료', lat: 15.9080, lng: 108.3390),
  Place(countryCode: 'VN', city: '호이안', name: '까오러우(Cao lầu)', kind: PlaceKind.food, audience: Audience.local, note: '호이안에서만 먹는 향토 면요리', priceHint: '₫ 3~5만'),
  // ── 나트랑 ──
  Place(countryCode: 'VN', city: '나트랑', name: '나트랑 비치', kind: PlaceKind.sight, audience: Audience.tourist, note: '시내 앞 긴 해변. 리조트·해양스포츠', priceHint: '무료', lat: 12.2388, lng: 109.1967),
  Place(countryCode: 'VN', city: '나트랑', name: '뽀나가 참탑', kind: PlaceKind.sight, audience: Audience.tourist, note: '참파 왕국 유적 사원', priceHint: '₫ 3만', lat: 12.2653, lng: 109.1954),
  Place(countryCode: 'VN', city: '나트랑', name: '분짜까 나트랑', kind: PlaceKind.food, audience: Audience.local, note: '해산물 육수 어묵국수. 항구도시 별미', priceHint: '₫ 3~5만'),
  // ── 푸꾸옥 ──
  Place(countryCode: 'VN', city: '푸꾸옥', name: '사오 비치(Sao Beach)', kind: PlaceKind.sight, audience: Audience.tourist, note: '하얀 모래의 대표 해변', priceHint: '무료', lat: 10.0430, lng: 104.0290),
  Place(countryCode: 'VN', city: '푸꾸옥', name: '푸꾸옥 야시장(Dinh Cau)', kind: PlaceKind.food, audience: Audience.tourist, note: '싱싱한 해산물 구이·씨푸드', priceHint: '₫ 10~30만'),

  // ═══════════════════════ 일본 ═══════════════════════
  // ── 도쿄 ──
  Place(countryCode: 'JP', city: '도쿄', name: '센소지(아사쿠사)', kind: PlaceKind.sight, audience: Audience.tourist, note: '도쿄 최고(最古) 사찰, 나카미세 상점가', priceHint: '무료', lat: 35.7148, lng: 139.7967),
  Place(countryCode: 'JP', city: '도쿄', name: '시부야 스크램블 교차로', kind: PlaceKind.sight, audience: Audience.tourist, note: '세계 최대급 교차로. 주변 쇼핑·야경', priceHint: '무료', lat: 35.6595, lng: 139.7005),
  Place(countryCode: 'JP', city: '도쿄', name: '도쿄타워', kind: PlaceKind.sight, audience: Audience.tourist, note: '도심 랜드마크, 야경 명소', priceHint: '전망대 ¥1,200~', lat: 35.6586, lng: 139.7454),
  Place(countryCode: 'JP', city: '도쿄', name: '츠키지 장외시장', kind: PlaceKind.food, audience: Audience.tourist, note: '신선한 초밥·해산물 아침 먹거리', priceHint: '¥ 1,000~3,000', lat: 35.6654, lng: 139.7707),
  Place(countryCode: 'JP', city: '도쿄', name: '다치구이 소바(서서 먹는 국수)', kind: PlaceKind.food, audience: Audience.local, note: '역 근처 서서 먹는 소바. 직장인 한 끼', priceHint: '¥ 400~700'),
  Place(countryCode: 'JP', city: '도쿄', name: '상점가(商店街) 노포 정식', kind: PlaceKind.food, audience: Audience.local, note: '주택가 상점가 현지인 단골 정식·라멘집', priceHint: '¥ 800~1,500'),
  // ── 오사카 ──
  Place(countryCode: 'JP', city: '오사카', name: '도톤보리', kind: PlaceKind.sight, audience: Audience.tourist, note: '글리코 간판·먹자골목의 대명사', priceHint: '무료', lat: 34.6687, lng: 135.5031),
  Place(countryCode: 'JP', city: '오사카', name: '오사카성', kind: PlaceKind.sight, audience: Audience.tourist, note: '천수각과 공원. 벚꽃·단풍철 인기', priceHint: '천수각 ¥600', lat: 34.6873, lng: 135.5259),
  Place(countryCode: 'JP', city: '오사카', name: '신세카이 & 쓰텐카쿠', kind: PlaceKind.sight, audience: Audience.tourist, note: '복고풍 거리, 쿠시카츠 발상지', priceHint: '무료', lat: 34.6525, lng: 135.5063),
  Place(countryCode: 'JP', city: '오사카', name: '구로몬 시장', kind: PlaceKind.food, audience: Audience.tourist, note: '오사카의 부엌. 해산물·과일 먹거리', priceHint: '¥ 500~2,000', lat: 34.6656, lng: 135.5060),
  Place(countryCode: 'JP', city: '오사카', name: '동네 이자카야·정식집', kind: PlaceKind.food, audience: Audience.local, note: '먹자골목 한 블록 뒤 현지인 단골집이 가성비', priceHint: '¥ 1,000~2,500'),
  // ── 교토 ──
  Place(countryCode: 'JP', city: '교토', name: '후시미 이나리 신사', kind: PlaceKind.sight, audience: Audience.tourist, note: '천 개의 붉은 도리이. 이른 아침이 한적', priceHint: '무료', lat: 34.9671, lng: 135.7727),
  Place(countryCode: 'JP', city: '교토', name: '기요미즈데라(청수사)', kind: PlaceKind.sight, audience: Audience.tourist, note: '절벽 위 본당과 전경. 주변 산넨자카', priceHint: '¥ 400', lat: 34.9949, lng: 135.7850),
  Place(countryCode: 'JP', city: '교토', name: '아라시야마 대나무 숲', kind: PlaceKind.sight, audience: Audience.tourist, note: '대숲길과 도게츠교', priceHint: '무료', lat: 35.0094, lng: 135.6737),
  Place(countryCode: 'JP', city: '교토', name: '니시키 시장', kind: PlaceKind.food, audience: Audience.tourist, note: '교토의 부엌. 먹거리 많으나 매우 붐빔', priceHint: '간식 ¥300~'),
  // ── 후쿠오카 ──
  Place(countryCode: 'JP', city: '후쿠오카', name: '다자이후 텐만구', kind: PlaceKind.sight, audience: Audience.tourist, note: '학문의 신 사당. 우메가에모찌 명물', priceHint: '무료', lat: 33.5218, lng: 130.5350),
  Place(countryCode: 'JP', city: '후쿠오카', name: '나카스 야타이(포장마차)', kind: PlaceKind.food, audience: Audience.tourist, note: '강변 포장마차 거리. 라멘·꼬치', priceHint: '¥ 1,000~3,000', lat: 33.5930, lng: 130.4060),
  Place(countryCode: 'JP', city: '후쿠오카', name: '하카타 돈코츠 라멘', kind: PlaceKind.food, audience: Audience.local, note: '진한 돼지뼈 육수. 면 추가(가에다마) 문화', priceHint: '¥ 600~1,000'),
  Place(countryCode: 'JP', city: '후쿠오카', name: '모츠나베(곱창전골)', kind: PlaceKind.food, audience: Audience.local, note: '후쿠오카 향토 전골. 현지인 회식 메뉴', priceHint: '¥ 1,500~2,500'),
  // ── 삿포로 ──
  Place(countryCode: 'JP', city: '삿포로', name: '오도리 공원', kind: PlaceKind.sight, audience: Audience.tourist, note: '도심 공원. 눈축제·맥주축제 무대', priceHint: '무료', lat: 43.0606, lng: 141.3565),
  Place(countryCode: 'JP', city: '삿포로', name: '스스키노', kind: PlaceKind.sight, audience: Audience.tourist, note: '홋카이도 최대 유흥·먹거리 거리', priceHint: '무료', lat: 43.0553, lng: 141.3536),
  Place(countryCode: 'JP', city: '삿포로', name: '수프카레', kind: PlaceKind.food, audience: Audience.local, note: '삿포로에서 시작된 향토 카레', priceHint: '¥ 1,200~1,800'),
  Place(countryCode: 'JP', city: '삿포로', name: '징기스칸(양고기 구이)', kind: PlaceKind.food, audience: Audience.local, note: '홋카이도 대표 양고기 요리', priceHint: '¥ 2,000~3,500'),
  // ── 오키나와 ──
  Place(countryCode: 'JP', city: '오키나와', name: '추라우미 수족관', kind: PlaceKind.sight, audience: Audience.tourist, note: '거대 고래상어 수조로 유명', priceHint: '¥ 2,180', lat: 26.6944, lng: 127.8779),
  Place(countryCode: 'JP', city: '오키나와', name: '국제거리(고쿠사이도리)', kind: PlaceKind.sight, audience: Audience.tourist, note: '나하 중심 상점·먹거리 거리', priceHint: '무료', lat: 26.2145, lng: 127.6870),
  Place(countryCode: 'JP', city: '오키나와', name: '오키나와 소바', kind: PlaceKind.food, audience: Audience.local, note: '돼지고기 올린 향토 국수', priceHint: '¥ 700~1,000'),

  // ═══════════════════════ 대만 ═══════════════════════
  // ── 타이베이 ──
  Place(countryCode: 'TW', city: '타이베이', name: '지우펀 옛 거리', kind: PlaceKind.sight, audience: Audience.tourist, note: '홍등 골목 대표 관광지. 주말 매우 혼잡', priceHint: '무료', lat: 25.1097, lng: 121.8447),
  Place(countryCode: 'TW', city: '타이베이', name: '타이베이 101', kind: PlaceKind.sight, audience: Audience.tourist, note: '랜드마크 초고층. 전망대·쇼핑몰', priceHint: '전망대 NT\$600', lat: 25.0339, lng: 121.5645),
  Place(countryCode: 'TW', city: '타이베이', name: '중정기념당', kind: PlaceKind.sight, audience: Audience.tourist, note: '위병 교대식으로 유명한 기념관', priceHint: '무료', lat: 25.0360, lng: 121.5219),
  Place(countryCode: 'TW', city: '타이베이', name: '용산사(龍山寺)', kind: PlaceKind.sight, audience: Audience.tourist, note: '타이베이 대표 사원. 현지 참배객도 많음', priceHint: '무료', lat: 25.0369, lng: 121.4999),
  Place(countryCode: 'TW', city: '타이베이', name: '스린 야시장', kind: PlaceKind.food, audience: Audience.tourist, note: '대표 야시장. 지파이·굴전(관광객 비중 높음)', priceHint: 'NT\$ 50~150', lat: 25.0879, lng: 121.5240),
  Place(countryCode: 'TW', city: '타이베이', name: '아침 두유집(豆漿)', kind: PlaceKind.food, audience: Audience.local, note: '단삥·유탸오에 두유. 현지인의 진짜 아침', priceHint: 'NT\$ 40~100'),
  Place(countryCode: 'TW', city: '타이베이', name: '동네 뉴러우몐(牛肉麵)', kind: PlaceKind.food, audience: Audience.local, note: '대만식 소고기국수. 동네 노포가 진국', priceHint: 'NT\$ 120~200'),
  // ── 타이중 ──
  Place(countryCode: 'TW', city: '타이중', name: '가오메이 습지', kind: PlaceKind.sight, audience: Audience.tourist, note: '일몰 반영이 아름다운 갯벌 습지', priceHint: '무료', lat: 24.3105, lng: 120.5490),
  Place(countryCode: 'TW', city: '타이중', name: '무지개 마을', kind: PlaceKind.sight, audience: Audience.tourist, note: '노병이 그린 알록달록 벽화 마을', priceHint: '무료', lat: 24.1341, lng: 120.6106),
  Place(countryCode: 'TW', city: '타이중', name: '펑지아 야시장', kind: PlaceKind.food, audience: Audience.tourist, note: '대만 최대급 야시장. 대학가라 저렴', priceHint: 'NT\$ 40~120'),
  // ── 가오슝 ──
  Place(countryCode: 'TW', city: '가오슝', name: '롄츠탄(연지담)', kind: PlaceKind.sight, audience: Audience.tourist, note: '용호탑이 있는 호수 명소', priceHint: '무료', lat: 22.6845, lng: 120.2930),
  Place(countryCode: 'TW', city: '가오슝', name: '보얼 예술특구', kind: PlaceKind.sight, audience: Audience.tourist, note: '옛 창고를 개조한 예술·카페 거리', priceHint: '무료', lat: 22.6203, lng: 120.2820),
  Place(countryCode: 'TW', city: '가오슝', name: '류허 야시장', kind: PlaceKind.food, audience: Audience.tourist, note: '해산물·먹거리 야시장', priceHint: 'NT\$ 50~200'),
  // ── 화롄 ──
  Place(countryCode: 'TW', city: '화롄', name: '타로코 협곡', kind: PlaceKind.sight, audience: Audience.tourist, note: '대리석 대협곡 국가공원(낙석 등 통제 확인)', priceHint: '무료', lat: 24.1580, lng: 121.4900),

  // ═══════════════════════ 태국 ═══════════════════════
  // ── 방콕 ──
  Place(countryCode: 'TH', city: '방콕', name: '왓 아룬(새벽 사원)', kind: PlaceKind.sight, audience: Audience.tourist, note: '강변 상징 사원. 강 건너 일몰 뷰', priceHint: '฿ 100 내외', lat: 13.7437, lng: 100.4889),
  Place(countryCode: 'TH', city: '방콕', name: '왕궁 & 왓 프라깨우', kind: PlaceKind.sight, audience: Audience.tourist, note: '에메랄드 불상 사원. 복장 규정 엄격', priceHint: '฿ 500', lat: 13.7500, lng: 100.4914),
  Place(countryCode: 'TH', city: '방콕', name: '왓 포(누워있는 불상)', kind: PlaceKind.sight, audience: Audience.tourist, note: '거대 와불과 태국 마사지 본산', priceHint: '฿ 200', lat: 13.7465, lng: 100.4927),
  Place(countryCode: 'TH', city: '방콕', name: '짜뚜짝 주말시장', kind: PlaceKind.sight, audience: Audience.tourist, note: '1만 점포 초대형 시장. 더위·인파 주의', priceHint: '무료입장', lat: 13.7999, lng: 100.5503),
  Place(countryCode: 'TH', city: '방콕', name: '오피스가 로컬 노점 점심', kind: PlaceKind.food, audience: Audience.local, note: '점심 현지 직장인이 줄 서는 노점이 가성비', priceHint: '฿ 50~80'),
  Place(countryCode: 'TH', city: '방콕', name: '보트누들(꾸어이띠여우 르아)', kind: PlaceKind.food, audience: Audience.local, note: '작은 그릇으로 여러 그릇. 진한 현지식', priceHint: '฿ 15~20/그릇'),
  // ── 치앙마이 ──
  Place(countryCode: 'TH', city: '치앙마이', name: '도이수텝 사원', kind: PlaceKind.sight, audience: Audience.tourist, note: '산 위 황금 사원. 치앙마이 전경 조망', priceHint: '฿ 30~50', lat: 18.8047, lng: 98.9217),
  Place(countryCode: 'TH', city: '치앙마이', name: '왓 체디루앙', kind: PlaceKind.sight, audience: Audience.tourist, note: '올드시티 중심의 거대 옛 불탑', priceHint: '฿ 40', lat: 18.7870, lng: 98.9860),
  Place(countryCode: 'TH', city: '치앙마이', name: '님만해민 카페거리', kind: PlaceKind.sight, audience: Audience.tourist, note: '감성 카페·편집숍 밀집 지역', priceHint: '카페 이용', lat: 18.7965, lng: 98.9670),
  Place(countryCode: 'TH', city: '치앙마이', name: '카오소이(북부 카레국수)', kind: PlaceKind.food, audience: Audience.local, note: '북부 대표 음식. 동네 전문점이 깊은 맛', priceHint: '฿ 50~70'),
  // ── 푸켓 ──
  Place(countryCode: 'TH', city: '푸켓', name: '파통 비치', kind: PlaceKind.sight, audience: Audience.tourist, note: '푸켓 대표 해변. 방라 야시장·나이트라이프', priceHint: '무료', lat: 7.8965, lng: 98.2960),
  Place(countryCode: 'TH', city: '푸켓', name: '빅 부다(Big Buddha)', kind: PlaceKind.sight, audience: Audience.tourist, note: '언덕 위 대형 백색 불상, 전망 좋음', priceHint: '무료', lat: 7.8276, lng: 98.3120),
  Place(countryCode: 'TH', city: '푸켓', name: '푸켓 올드타운', kind: PlaceKind.sight, audience: Audience.tourist, note: '시노-포르투갈 파스텔 거리, 카페·벽화', priceHint: '무료', lat: 7.8846, lng: 98.3880),
  // ── 파타야 ──
  Place(countryCode: 'TH', city: '파타야', name: '꼬란(산호섬)', kind: PlaceKind.sight, audience: Audience.tourist, note: '맑은 물의 근교 섬. 해양스포츠', priceHint: '왕복 배편', lat: 12.9200, lng: 100.7830),
  Place(countryCode: 'TH', city: '파타야', name: '농눅 빌리지', kind: PlaceKind.sight, audience: Audience.tourist, note: '열대 정원·전통 공연 테마파크', priceHint: '฿ 300~', lat: 12.7660, lng: 100.9350),
];
