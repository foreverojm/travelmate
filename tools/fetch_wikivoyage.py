# -*- coding: utf-8 -*-
"""
Wikivoyage(무료 여행가이드)의 도시별 See/Do/Eat/Drink 리스팅을 수집한다.
- 편집된 여행가이드라 OSM보다 맥락(설명·가격)이 좋다.
- 좌표가 있는 항목만 수집(지도 정확도 + 잡항목 제거).
- 결과는 fetch_osm.py 에서 OSM 수집분과 합쳐 하나의 JSON으로 출력.

사용(단독): python tools/fetch_wikivoyage.py
"""
import urllib.request, urllib.parse, urllib.error, json, re, time

# 한글 도시명 -> (국가코드, Wikivoyage 영문 페이지)
WV_PAGES = [
    ('VN', '하노이', 'Hanoi'),
    ('VN', '호치민', 'Ho Chi Minh City'),
    ('VN', '다낭', 'Da Nang'),
    ('VN', '호이안', 'Hoi An'),
    ('VN', '나트랑', 'Nha Trang'),
    ('VN', '푸꾸옥', 'Phu Quoc'),
    ('JP', '도쿄', 'Tokyo'),
    ('JP', '오사카', 'Osaka'),
    ('JP', '교토', 'Kyoto'),
    ('JP', '후쿠오카', 'Fukuoka'),
    ('JP', '삿포로', 'Sapporo'),
    ('JP', '오키나와', 'Naha'),
    ('TW', '타이베이', 'Taipei'),
    ('TW', '타이중', 'Taichung'),
    ('TW', '가오슝', 'Kaohsiung'),
    ('TW', '화롄', 'Hualien'),
    ('TH', '방콕', 'Bangkok'),
    ('TH', '치앙마이', 'Chiang Mai'),
    ('TH', '푸켓', 'Phuket Town'),
    ('TH', '파타야', 'Pattaya'),
]

SIGHT_CAP_WV = 12  # 도시당 명소 최대
FOOD_CAP_WV = 10   # 도시당 맛집 최대
API = 'https://en.wikivoyage.org/w/api.php'


def _wikitext(page):
    u = API + '?' + urllib.parse.urlencode({
        'action': 'parse', 'page': page, 'prop': 'wikitext',
        'format': 'json', 'redirects': 1,
    })
    # 429(Too Many Requests) 대비 재시도 + 백오프
    for attempt in range(4):
        try:
            req = urllib.request.Request(
                u, headers={'User-Agent': 'TravelMate-dev/1.0 (travel app POI)'})
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r).get('parse', {}).get(
                    'wikitext', {}).get('*', '')
        except urllib.error.HTTPError as ex:
            if ex.code == 429 and attempt < 3:
                time.sleep(8 * (attempt + 1))
                continue
            raise
    return ''


def _find_templates(wt):
    res = []
    i, n = 0, len(wt)
    while i < n - 1:
        if wt[i] == '{' and wt[i + 1] == '{':
            depth, j = 1, i + 2
            while j < n - 1 and depth > 0:
                if wt[j] == '{' and wt[j + 1] == '{':
                    depth += 1; j += 2; continue
                if wt[j] == '}' and wt[j + 1] == '}':
                    depth -= 1; j += 2; continue
                j += 1
            res.append(wt[i:j]); i = j
        else:
            i += 1
    return res


def _split_params(body):
    parts, buf, d, b = [], '', 0, 0
    k = 0
    while k < len(body):
        if body[k:k + 2] == '{{':
            d += 1; buf += '{{'; k += 2; continue
        if body[k:k + 2] == '}}':
            d -= 1; buf += '}}'; k += 2; continue
        if body[k:k + 2] == '[[':
            b += 1; buf += '[['; k += 2; continue
        if body[k:k + 2] == ']]':
            b -= 1; buf += ']]'; k += 2; continue
        if body[k] == '|' and d == 0 and b == 0:
            parts.append(buf); buf = ''; k += 1; continue
        buf += body[k]; k += 1
    parts.append(buf)
    return parts


def _clean(v):
    v = re.sub(r'<ref.*?</ref>', '', v, flags=re.S)
    v = re.sub(r'<[^>]+>', '', v)
    # [[a|b]] -> b, [[a]] -> a
    v = re.sub(r'\[\[[^\]|]*\|([^\]]*)\]\]', r'\1', v)
    v = v.replace('[[', '').replace(']]', '')
    v = re.sub(r'\{\{[^{}]*\}\}', '', v)
    v = v.replace("'''", '').replace("''", '')
    return re.sub(r'\s+', ' ', v).strip()


def _num(s):
    s = _clean(s)
    try:
        return round(float(s), 6)
    except Exception:
        return None


def _price(s):
    s = _clean(s)
    if not s:
        return ''
    if s.lower() in ('free', 'free.', 'no charge'):
        return '무료'
    # 잘린 통화기호만 남은 경우(예: 'US', '$') 제거
    if len(s) <= 2 and s.isalpha():
        return ''
    if len(s) > 24:
        s = s[:22].rstrip() + '…'
    return s


def collect_wikivoyage():
    rows = []
    for cc, city, page in WV_PAGES:
        try:
            wt = _wikitext(page)
        except Exception as ex:
            print(f'  ! wv {city}: {ex}', flush=True)
            time.sleep(1)
            continue
        seen = set()
        n_sight = n_food = 0
        for t in _find_templates(wt):
            if n_sight >= SIGHT_CAP_WV and n_food >= FOOD_CAP_WV:
                break
            parts = _split_params(t[2:-2])
            tname = parts[0].strip().lower()
            kv = {}
            for p in parts[1:]:
                if '=' in p:
                    key, _, val = p.partition('=')
                    kv[key.strip().lower()] = val
            typ = kv.get('type', '').strip().lower() if tname == 'listing' else tname
            if typ not in ('see', 'do', 'eat', 'drink'):
                continue
            name = _clean(kv.get('name', ''))
            if not name or len(name) > 60:
                continue
            lat = _num(kv.get('lat', ''))
            lng = _num(kv.get('long', ''))
            if lat is None or lng is None:
                continue  # 좌표 있는 항목만(지도 정확도 + 잡항목 제거)
            key = name.lower()
            if key in seen:
                continue
            kind = 'food' if typ in ('eat', 'drink') else 'sight'
            # 종류별 캡(명소·맛집 균형)
            if kind == 'sight' and n_sight >= SIGHT_CAP_WV:
                continue
            if kind == 'food' and n_food >= FOOD_CAP_WV:
                continue
            seen.add(key)
            if kind == 'sight':
                n_sight += 1
            else:
                n_food += 1
            desc = _clean(kv.get('content', ''))
            if len(desc) > 70:
                desc = desc[:67].rstrip() + '…'
            note = desc if desc else ('맛집' if kind == 'food' else '명소')
            rows.append({
                'cc': cc, 'city': city, 'name': name, 'kind': kind,
                'note': note, 'lat': lat, 'lng': lng,
                'audience': None, 'price': _price(kv.get('price', '')),
                'src': 'wikivoyage',
            })
        print(f'[wv] {city}: +{n_sight + n_food} (명소{n_sight}/맛집{n_food})',
              flush=True)
        time.sleep(4)  # rate limit 예방
    return rows


if __name__ == '__main__':
    rows = collect_wikivoyage()
    print('TOTAL wikivoyage:', len(rows))
