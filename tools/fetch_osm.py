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


# 음식점 품질 필터: 정보가 풍부한 곳만(태그가 실하다 = 실제로 운영/문서화된 곳)
FOOD_QUALITY_TAGS = ['cuisine', 'opening_hours', 'website', 'contact:website',
                     'brand', 'phone', 'contact:phone', 'wikidata']


def food_is_quality(tags):
    return any(t in tags for t in FOOD_QUALITY_TAGS)


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
                'lat': x['lat'], 'lng': x['lng'], 'source': 'osm',
            } for x in all_rows
        ],
    }
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(payload, f, ensure_ascii=False, indent=1)
    print('\nWROTE ' + out_path + ' - ' + str(len(all_rows)) + ' places')


if __name__ == '__main__':
    main()
