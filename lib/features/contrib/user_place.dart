/// 여행자 제보(커뮤니티) 장소 모델.
/// 별점이 아니라 "직접 가봤다 + 다른 여행자의 '가봤어요' 수"로 신뢰를 쌓는다.
library;

enum ContribStatus { pending, verified, hidden }

class UserPlace {
  final String id;
  final String type; // 'place'(맛집·명소) | 'price'(시세)
  final String countryCode;
  final String city;
  final String name; // 시세면 품목명
  final String kind; // 'food' | 'sight' | 'price'
  final String? audience; // 'local' | 'tourist' | null
  final String priceHint; // 시세면 지불 가격
  final String note; // 한줄평
  final double? lat;
  final double? lng;
  final int confirms; // '가봤어요'/'저도 그 가격' 수
  final String status; // pending | verified | hidden
  final DateTime? createdAt;

  const UserPlace({
    required this.id,
    this.type = 'place',
    required this.countryCode,
    required this.city,
    required this.name,
    required this.kind,
    this.audience,
    this.priceHint = '',
    this.note = '',
    this.lat,
    this.lng,
    this.confirms = 0,
    this.status = 'pending',
    this.createdAt,
  });

  bool get isVerified => status == 'verified';

  factory UserPlace.fromJson(Map<String, dynamic> j) {
    final created = j['created_at'];
    return UserPlace(
      id: '${j['id']}',
      type: (j['type'] as String?) ?? 'place',
      countryCode: (j['country_code'] as String?) ?? '',
      city: (j['city'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      kind: (j['kind'] as String?) ?? 'food',
      audience: j['audience'] as String?,
      priceHint: (j['price_hint'] as String?) ?? '',
      note: (j['note'] as String?) ?? '',
      lat: (j['lat'] as num?)?.toDouble(),
      lng: (j['lng'] as num?)?.toDouble(),
      confirms: (j['confirms'] as num?)?.toInt() ?? 0,
      status: (j['status'] as String?) ?? 'pending',
      createdAt: created is String ? DateTime.tryParse(created)?.toLocal() : null,
    );
  }

  /// 제출용 payload (id/confirms/status 등은 서버가 관리)
  Map<String, dynamic> toInsert(String deviceId) => {
        // type='place'는 컬럼 없어도 동작하도록 생략(기본값), price만 명시
        if (type != 'place') 'type': type,
        'country_code': countryCode,
        'city': city,
        'name': name,
        'kind': kind,
        'audience': audience,
        'price_hint': priceHint,
        'note': note,
        'lat': lat,
        'lng': lng,
        'device_id': deviceId,
      };
}
