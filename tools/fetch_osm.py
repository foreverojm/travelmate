# -*- coding: utf-8 -*-
"""
OpenStreetMap Overpass에서 도시별 명소·음식점을 무료로 수집해
lib/features/places/osm_places.dart 를 생성한다.

- 영문명(name:en)이 있는 항목만 수집(한국인 가독성)
- 관광객/현지인 구분은 OSM에 없으므로 audience 미지정(앱에서 '지도 정보'로 표시)
- 예의상 요청 간 sleep, 실패 시 미러로 재시도

사용: python tools/fetch_osm.py
"""
import urllib.request, urllib.parse, json, time, sys, os, datetime

ENDPOINTS = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
]

# (한글도시명, 위도, 경도, 반경m)
CITIES = {
    'VN': [
        ('하노이', 21.0287, 105.8524, 6000),
        ('호치민', 10.7769, 106.7009, 6000),
        ('다낭', 16.0678, 108.2208, 7000),
        ('호이안', 15.8801, 108.3380, 4000),
        ('나트랑', 12.2388, 109.1967, 6000),
        ('푸꾸옥', 10.2270, 103.9670, 8000),
    ],
    'JP': [
        ('도쿄', 35.6812, 139.7671, 7000),
        ('오사카', 34.6937, 135.5023, 6000),
        ('교토', 35.0116, 135.7681, 6000),
        ('후쿠오카', 33.5902, 130.4017, 6000),
        ('삿포로', 43.0618, 141.3545, 6000),
        ('오키나와', 26.2124, 127.6809, 8000),
    ],
    'TW': [
        ('타이베이', 25.0330, 121.5654, 7000),
        ('타이중', 24.1477, 120.6736, 7000),
        ('가오슝', 22.6273, 120.3014, 7000),
        ('화롄', 23.9871, 121.6015, 8000),
    ],
    'TH': [
        ('방콕', 13.7563, 100.5018, 7000),
        ('치앙마이', 18.7883, 98.9853, 6000),
        ('푸켓', 7.8804, 98.3923, 9000),
        ('파타야', 12.9236, 100.8825, 7000),
    ],
}

SIGHT_CAP = 14
FOOD_CAP = 9

CAT = {
    'attraction': '명소', 'museum': '박물관', 'viewpoint': '전망 포인트',
    'gallery': '갤러리', 'zoo': '동물원', 'theme_park': '테마파크',
    'monument': '기념물', 'memorial': '기념관',
    'castle': '성', 'ruins': '유적',
    'restaurant': '음식점', 'cafe': '카페',
}


def q_sights(lat, lng, r):
    # artwork(조형물) 제외 — 좌표·설명 부정확 사례가 많아 신뢰도 저하
    return f'''[out:json][timeout:60];
(
 node["tourism"~"^(attraction|museum|viewpoint|gallery|zoo|theme_park)$"]["name:en"](around:{r},{lat},{lng});
 way["tourism"~"^(attraction|museum|viewpoint|gallery|zoo|theme_park)$"]["name:en"](around:{r},{lat},{lng});
 node["historic"~"^(monument|memorial|castle|ruins)$"]["name:en"](around:{r},{lat},{lng});
);
out center {SIGHT_CAP*6};'''


# 신뢰 가능한 명소 기준: 위키데이터/위키백과 등재 or 확실한 시설(박물관·미술관·동물원·테마파크·성)
STRONG_TOURISM = {'museum', 'gallery', 'zoo', 'theme_park'}


def sight_is_quality(tags):
    if 'wikidata' in tags or 'wikipedia' in tags:
        return True
    if tags.get('tourism') in STRONG_TOURISM:
        return True
    if tags.get('historic') == 'castle':
        return True
    return False


def q_food(lat, lng, r):
    return f'''[out:json][timeout:60];
node["amenity"~"^(restaurant|cafe)$"]["name:en"](around:{r},{lat},{lng});
out {FOOD_CAP*8};'''


# 음식점 신뢰 필터: 웹사이트(또는 위키데이터)가 있는 곳만.
# = 실제로 존재·운영이 검증 가능한 업소. 이름만 있고 폐업 가능성 있는 곳 제외.
FOOD_TRUST_TAGS = ['website', 'contact:website', 'wikidata']


def food_is_quality(tags):
    return any(t in tags for t in FOOD_TRUST_TAGS)


# ── 큐레이션 보강 ──────────────────────────────────────────────
# OSM 자동수집이 빈약한 도시(나트랑·푸꾸옥 등)를 위해 직접 검증한 장소를 덧붙인다.
# 랜드마크는 좌표 포함(지도 핀), 식당은 좌표를 비워 이름 검색으로 연결(핀 오차로 인한 신뢰 저하 방지).
# 매주 자동 재수집 시에도 이 목록은 스크립트에 있으므로 항상 유지된다.
# 형식: (도시, 이름, kind, audience, note, price, lat, lng)  — lat/lng None 이면 이름 검색.
CURATED = {
    'VN': [
        ('나트랑', '롱선사 (Long Son Pagoda)', 'sight', 'tourist',
         '언덕 위 거대 백색 와불. 시내 전망 좋음', '무료', 12.2523, 109.1809),
        ('나트랑', '나트랑 대성당 (Stone Church)', 'sight', 'tourist',
         '프랑스풍 석조 성당. 언덕 위 랜드마크', '무료', 12.2470, 109.1897),
        ('나트랑', '혼쫑곶 (Hon Chong)', 'sight', 'tourist',
         '바다 위 기암괴석 전망 포인트', '₫ 2만', 12.2711, 109.2054),
        ('나트랑', '탑바 머드온천 (Thap Ba Hot Spring)', 'sight', 'tourist',
         '진흙 스파. 가족·커플 인기', '₫ 15~30만', 12.2717, 109.1876),
        ('나트랑', '빈원더스 나트랑 (VinWonders)', 'sight', 'tourist',
         '케이블카로 가는 혼째섬 테마파크', '입장권', 12.2119, 109.2107),
        ('나트랑', '넴느엉 담반쿠옌 (Nem Nướng)', 'food', 'local',
         '숯불 돼지고기 쌈. 나트랑 대표 먹거리', '₫ 5~8만', None, None),
        ('나트랑', '담 시장 (Chợ Đầm) 먹자골목', 'food', 'local',
         '현지 재래시장. 아침 쌀국수·해산물', '무료입장', 12.2489, 109.1925),
        ('나트랑', '루이지애나 브루하우스', 'food', 'tourist',
         '해변 수제맥주·씨푸드', '₫ 15~30만', None, None),
    ],
    'VN_PQ': [
        ('푸꾸옥', '혼탐 케이블카 (Hon Thom)', 'sight', 'tourist',
         '세계 최장급 해상 케이블카', '왕복권', 10.0092, 104.0169),
        ('푸꾸옥', '빈원더스 푸꾸옥 (VinWonders)', 'sight', 'tourist',
         '북부 대형 테마파크. 그랜드월드 인접', '입장권', 10.3369, 104.0184),
        ('푸꾸옥', '코코넛 수용소 (Phu Quoc Prison)', 'sight', 'tourist',
         '전쟁기 수용소 역사관', '무료', 10.0433, 104.0142),
        ('푸꾸옥', '쩐 폭포 (Suoi Tranh)', 'sight', 'tourist',
         '트레킹·물놀이 계곡', '₫ 1만', 10.2160, 104.0230),
        ('푸꾸옥', '함닌 어촌마을 (Ham Ninh)', 'food', 'local',
         '선착장 해산물. 게·성게가 유명', '₫ 시가', None, None),
        ('푸꾸옥', '선셋 사나토 비치클럽', 'sight', 'tourist',
         '조형물·일몰 명소', '음료 이용', 10.1745, 103.9613),
    ],
    'TH': [
        ('방콕', '제이파이 (Jay Fai)', 'food', 'local',
         '미쉐린 크랩 오믈렛. 대기 길다', '฿ 800~1500', None, None),
        ('방콕', '팁사마이 팟타이', 'food', 'tourist',
         '오렌지주스로 유명한 팟타이 노포', '฿ 60~120', None, None),
    ],
}


def curated_rows():
    rows = []
    for group in CURATED.values():
        for (city, name, kind, aud, note, price, la, lo) in group:
            rows.append({
                'cc': 'VN' if city in ('나트랑', '푸꾸옥') else
                      'TH' if city in ('방콕', '치앙마이', '푸켓', '파타야') else
                      'JP' if city in ('도쿄', '오사카', '교토', '후쿠오카', '삿포로', '오키나와') else 'TW',
                'city': city, 'name': name, 'kind': kind, 'note': f'{note}',
                'lat': la, 'lng': lo, 'audience': aud, 'price': price, 'src': 'curated',
            })
    return rows


def fetch(query):
    data = urllib.parse.urlencode({'data': query}).encode()
    last = None
    for ep in ENDPOINTS:
        for attempt in range(2):
            try:
                req = urllib.request.Request(
                    ep, data=data, headers={'User-Agent': 'TravelMate-dev/1.0'})
                with urllib.request.urlopen(req, timeout=90) as r:
                    return json.load(r).get('elements', [])
            except Exception as ex:
                last = ex
                time.sleep(5)
    print('  ! fetch failed:', last)
    return []


def cat_of(tags):
    for k in ('tourism', 'historic', 'amenity'):
        v = tags.get(k)
        if v in CAT:
            return CAT[v], ('food' if k == 'amenity' else 'sight')
    return None, None


def esc(s):
    return s.replace('\\', '\\\\').replace("'", "\\'").replace('$', '\\$').strip()


def collect(cc, city, lat, lng, r):
    out = []
    seen = set()

    def add(elements, kind_filter, cap):
        cnt = 0
        for e in elements:
            if cnt >= cap:
                break
            tags = e.get('tags', {})
            name = tags.get('name:en')
            if not name:
                continue
            label, kind = cat_of(tags)
            if not kind or kind != kind_filter:
                continue
            if kind == 'food' and not food_is_quality(tags):
                continue  # 품질 필터: 태그 빈약한 식당 제외
            if kind == 'sight' and not sight_is_quality(tags):
                continue  # 품질 필터: 위키데이터/확실한 시설만
            key = name.lower().strip()
            if key in seen:
                continue
            la = e.get('lat') or (e.get('center') or {}).get('lat')
            lo = e.get('lon') or (e.get('center') or {}).get('lon')
            if la is None or lo is None:
                continue
            local = tags.get('name')
            desc = tags.get('description:en') or tags.get('description')
            if desc and len(desc) > 70:
                desc = desc[:67].rstrip() + '…'
            if desc:
                note = f'{label} · {desc}'
            elif local and local != name:
                note = f'{label} · {local}'
            else:
                note = label
            seen.add(key)
            out.append({
                'cc': cc, 'city': city, 'name': name, 'kind': kind,
                'note': note, 'lat': round(la, 6), 'lng': round(lo, 6),
                'audience': None, 'price': '', 'src': 'osm',
            })
            cnt += 1

    add(fetch(q_sights(lat, lng, r)), 'sight', SIGHT_CAP)
    time.sleep(2)
    add(fetch(q_food(lat, lng, r)), 'food', FOOD_CAP)
    return out


def main():
    all_rows = []
    for cc, cities in CITIES.items():
        for (city, lat, lng, r) in cities:
            print(f'[{cc}] {city} …', flush=True)
            rows = collect(cc, city, lat, lng, r)
            print(f'    +{len(rows)}', flush=True)
            all_rows.extend(rows)
            time.sleep(2)

    # 검증된 큐레이션 보강분을 합친다(작은 도시 커버리지 + 신뢰도).
    extra = curated_rows()
    all_rows.extend(extra)
    print(f'[curated] +{len(extra)}', flush=True)

    # 앱 내장(오프라인 기본) + 원격 호스팅용으로 동일한 JSON 하나를 생성.
    out_path = os.path.join('assets', 'data', 'osm_places.json')
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    payload = {
        'source': 'OpenStreetMap contributors (ODbL)',
        'generatedAt': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
        'count': len(all_rows),
        'places': [
            {
                'countryCode': x['cc'], 'city': x['city'], 'name': x['name'],
                'kind': x['kind'], 'note': x['note'],
                'lat': x['lat'], 'lng': x['lng'],
                'audience': x.get('audience'),
                'priceHint': x.get('price', ''),
                'source': x.get('src', 'osm'),
            } for x in all_rows
        ],
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print('\nWROTE ' + out_path + ' - ' + str(len(all_rows)) + ' places')


if __name__ == '__main__':
    main()
