# TravelMate(가칭) 프로젝트 인수인계 · 이어가기 문서

> 이 문서 하나 + GitHub 리포 + Supabase(클라우드) 만 있으면 다른 PC(N100 등)에서 그대로 이어서 개발할 수 있습니다.
> 최종 업데이트 기준 버전: **v1.10.1 (+17)**

---

## 0. 30초 요약 / 다른 PC에서 이어가기
```bash
git clone https://github.com/foreverojm/travelmate.git
cd travelmate
flutter pub get
flutter build apk --release        # 첫 빌드는 Gradle 다운로드로 느림
```
- **백엔드(Supabase)·원격 데이터·개인정보처리방침은 클라우드/깃허브에 있어 그대로 동작**합니다.
- 새 PC엔 **Flutter 3.27.4 + JDK 17 + Android SDK**만 설치하면 됩니다(아래 5장).
- 시크릿 따로 없음: Supabase anon 키는 공개용이라 코드에 포함(RLS로 보호).

---

## 1. 앱 개요
- **정체성**: 한국인 해외여행자용 **올인원 여행 비서**. "이 앱 하나 = 앱 5~6개".
- **대상 4개국**: 베트남·일본·대만·태국.
- **차별화(미션)**: 블로그·별점 조작에 맞서 **진짜 저렴한 현지 정보·실제 지불가**를 정직하게 안내. 리뷰 수가 아니라 "가봤어요/실제 가격" 기반 신뢰.
- **탭 구성**: ①환율 ②맛집·명소·시세 ③현지어 ④긴급(SOS) ⑤더보기

## 2. 기술 스택
- **Flutter 3.27.4 / Dart 3.6.2**, 상태관리 **Provider**(ChangeNotifier)
- 주요 패키지: provider, http, shared_preferences, intl, url_launcher, audioplayers, **flutter_tts(3.8.5 고정)**, **flutter_map + latlong2**(지도 피커)
- 백엔드: **Supabase**(REST를 http로 직접 호출 — 네이티브 SDK 없음)
- 데이터 파이프라인: Python(Overpass, Wikivoyage) + GitHub Actions 크론
- 리포: **github.com/foreverojm/travelmate** (main 브랜치)

## 3. 기능 현황(완성)
- **환율**: 실시간 환율(오프라인 시드+온라인 갱신), 동시환산, **통화 편집**(여행지 프리셋+개별 on/off), **환전 가이드**(국가별 금은방>은행>공항 유불리), 권종 칩.
- **맛집·명소**: 큐레이션 seed + OSM + **Wikivoyage** 합본(현지인/관광객 태그, 가격, 지도). 상단 토글로 **쇼핑·시세**(음식 로컬물가 vs 관광가, 감각품 부르는값→흥정가) 전환.
- **여행자 제보(커뮤니티)**: 맛집·명소/시세 둘 다. 지도 핀 위치 지정, 새 도시 직접 추가, "가봤어요/저도 이 가격" 신뢰, 내 제보 수정·삭제, 신고.
- **현지어**: 상황별 카테고리(위급/쇼핑/식당/교통/숙소/메뉴주문), **TTS 발음**, 확대 팝업(세로 초대형), **문구 만들기**(조합형+내장사전+온라인번역 하이브리드).
- **긴급(SOS)**: 긴급번호 원터치, 영사콜센터/대사관, 사이렌, 콘센트 모양, 치트시트.
- **더보기**: 버전, 개인정보처리방침 링크, 프리미엄(준비중 — 수익화 미연동).

## 4. 백엔드(Supabase) — 여행자 제보
- **URL**: `https://ntvhifxijeybqzuefwro.supabase.co`
- **anon 키**: `lib/features/contrib/contrib_config.dart` 에 하드코딩(공개용, RLS 보호로 안전).
- **테이블/정책/함수 SQL**: `docs/supabase_setup.sql` (신규 설치 시 이거 실행).
- **테이블**: `contributions` (type=place|price, 좌표, confirms, reports, status=pending/verified/hidden, device_id)
- **보안 모델(중요)**:
  - RLS는 **select/insert만** 허용. update/delete/confirm/report는 전부 **SECURITY DEFINER RPC**로만.
  - `force_pending` 트리거: 삽입 시 status=pending, confirms=0 강제(조작 방지).
  - **device_id는 컬럼 권한으로 anon SELECT 차단**(본인만 수정/삭제하는 근거값 보호).
    → 그래서 앱의 insert는 반드시 `?select=id`로 반환컬럼 한정(안 하면 return=representation이 401).
  - 신고 `report_contribution`: 3건 누적 시 자동 status='hidden'.
  - "가봤어요" `confirm_contribution`: 3건이면 status='verified' 승격.
- **관리(운영자 = 사장님)**: Supabase **Table Editor** 에서
  - 부적절 제보: `status`='hidden'(앱에서 즉시 사라짐) / 삭제
  - 수동 승격: `status`='verified'
  - 신고 많은 것: `reports` 내림차순 정렬로 확인

## 5. 빌드 환경(현재 Windows PC 기준)
- **Flutter**: `C:\flutter\bin` (PATH 없어서 매번 앞에 추가): `$env:Path="C:\flutter\bin;"+$env:Path`
- **JDK 17**: `C:\jdk-17.0.13+11`. 지정됨: `flutter config --jdk-dir "C:\jdk-17.0.13+11"`.
  빌드 시 `$env:JAVA_HOME="C:\jdk-17.0.13+11"` 도 주면 확실.
- **SDK**: compileSdk=35, targetSdk=35(플레이 요건 충족), minSdk=21.
- **주의**: `flutter_tts`는 **3.8.5 고정**(4.x는 compileSdk36/Kotlin2.2 요구 → 현재 툴체인 충돌).
- **빌드**: `flutter build apk --release` → `build\app\outputs\flutter-apk\app-release.apk`
- **분석**: `flutter analyze lib`
- **N100로 옮길 때**: N100이 Linux면 위 경로를 Linux Flutter/JDK 경로로 바꾸면 됨. Android SDK 필요. 저전력이라 빌드는 느릴 수 있음(개발은 성능 좋은 PC 권장, N100은 웹/브랜드 호스팅 권장).

## 6. 데이터 파이프라인(맛집·명소·시세)
- **원격 데이터 URL**(앱이 여기서 로드 → 앱 업데이트 없이 갱신):
  - 장소: `raw.githubusercontent.com/foreverojm/travelmate/main/assets/data/osm_places.json`
  - 시세: `.../assets/data/prices.json`
- **수집 스크립트**:
  - `tools/fetch_osm.py`: Overpass(OSM) 명소·맛집 + 큐레이션 보강 + Wikivoyage 병합, 근접중복 제거.
  - `tools/fetch_wikivoyage.py`: Wikivoyage See/Do/Eat 파싱(좌표·가격·설명).
  - 시세 `prices.json`은 **수동 큐레이션**(음식 로컬물가, 감각품 시세) + 여행자 제보(Supabase, 별도).
- **자동화**: `.github/workflows/refresh-places.yml` — 매주 월 03:00 UTC 재수집·커밋(GitHub Actions, 무료). push 경쟁 방지 rebase+재시도 포함.

## 7. 배포 프로세스
1. `flutter build apk --release`
2. APK를 구글드라이브 폴더로 복사(사장님 폰이 여기서 설치):
   `G:\내 드라이브\2. 제이소프트(JEsoft)\8. Project\여행 앱\TravelMate_v버전.apk`
3. `pubspec.yaml` version + `more_screen.dart` 버전 라벨 함께 올림.
- **APK는 설치 시 "덮어쓰기"**(먼저 삭제 X) 해야 기기 소유기록(device_id) 유지 → 내 제보 수정/삭제 계속 됨.

## 8. 브랜딩 / 앱 이름 (미결 · 출시 전 확정 필요)
- 현재 **가칭 "TravelMate"** — 사용 불가 수준: 플레이에 동명 앱 다수 + **Acer 등록상표**.
- **"여비"**: 여(행)비(교) 축약, 도메인 `yeobi.kr` 보유. 그러나 **"여비" 앱이 이미 존재**(com.yeobee, 여행경비 앱) + **특허청 상표 등록**되어 못 씀.
- 현재 웹 브랜드는 **"여행비교"**(yeobi.kr, N100에서 운영). 단 "여행비교"는 서술적이고 비교앱(스카이스캐너 등)과 결이 달라, 우리(현지비서)와는 포지셔닝이 다름.
- **할 일**: 고유 앱 이름 확정 → `applicationId` 변경(현재 `com.travelmate.travel_mate` → 최종 이름 기반, **최초 출시 후엔 변경 불가**) → 스토어 등록.

## 9. 남은 일 (출시 준비)
- [ ] 앱 이름·아이콘·`applicationId` 확정
- [ ] **릴리스 서명키 생성**(현재 debug 서명 → 플레이 업로드용 keystore 필요)
- [ ] 개인정보처리방침 최종 호스팅: `docs/privacy.html` → 현재 GitHub Pages(main/docs). **yeobi.kr로 옮겨도 됨**. 앱 링크는 `more_screen.dart`의 `_privacyUrl` 수정.
- [ ] 플레이 콘솔: 데이터안전 설문, 콘텐츠등급(IARC), 스크린샷/설명
- [ ] 수익화(AdMob/프리미엄) 연동 — 현재 미연동(자리만)
- [ ] (권장) confirm/report 서버측 기기별 중복방지(confirmations 테이블) — 트래픽 늘면

## 10. 알려진 이슈 / 주의
- **C: 디스크 상습 부족**: 드라이브 복사가 "not enough space"로 실패하면 `Remove-Item "$env:USERPROFILE\.gradle\caches" -Recurse -Force`(약 3GB, 다음 빌드 때 재생성).
- **제보 소유권은 설치본 단위**: 앱 재설치(데이터 삭제)하면 device_id·내 제보 기록이 초기화 → 이전 글 수정/삭제 불가. 운영자는 Supabase 대시보드에서 직접 처리.
- **옛 버전으로 올린 제보**(v1.6.0 이전)는 "내 것" 기록이 없어 앱에서 수정/삭제 안 됨 → 대시보드에서 삭제.

## 11. 확장성 / 서버 이전 (규모 커질 때)

**핵심 결론**: Supabase는 확장에 문제없고, **데이터가 표준 PostgreSQL이라 이전도 자유롭습니다**(Firebase처럼 독자포맷 락인 없음). 진짜 손볼 곳은 플랫폼이 아니라 **우리 앱의 조회 방식**입니다.

### Supabase 자체 확장성
- **표준 Postgres 기반** → 텍스트 제보 수백만 건도 인덱스만 있으면 문제없음(우리 데이터는 텍스트라 매우 가벼움, <1GB에 수십만~수백만 행).
- **요금 단계**: Free(500MB DB·5GB 전송/월) → Pro($25/월, 8GB DB·읽기 복제·커넥션 풀링) → Team/Enterprise. **같은 프로젝트에서 수직 확장** 가능.
- **읽기 부하**: Pro부터 **읽기 복제본 + 커넥션 풀러(Supavisor)** 제공. 조회 많은 앱에 유리.

### 서버 이전(탈-Supabase)이 필요할 때
- **`pg_dump` → 아무 Postgres(AWS RDS/Aurora, 자체호스팅, 다른 Supabase)로 복원**. 데이터 락인 없음.
- 앱은 REST(PostgREST)로 통신하는데, **API 호출이 `contrib_service.dart` 한 곳에 모여** 있어 이전 시 base URL/헤더만 바꾸면 됨(교체 범위 작음).
- 즉 **"클라우드 종속" 리스크가 낮음** — Firebase였다면 훨씬 어려웠을 부분.

### 규모 커지면 손봐야 할 것(우리 코드 쪽 — 지금은 OK, 나중에)
1. **조회 페이지네이션·서버필터**: 현재 앱은 제보를 `limit=500`으로 **전부 받아 클라에서 필터**함. 수천 건 넘어가면 느려짐 → **국가·도시별 서버 필터 + 페이지네이션(keyset/offset)** 으로 전환, DB **인덱스**(country_code, city, status, type, created_at) 추가.
2. **모더레이션 자동화**: 지금은 운영자 수동(대시보드) + 신고 3건 자동숨김. 대규모면 자동필터·신뢰점수 강화 필요.
3. **조작 방지**: confirm/report 서버측 기기별 중복방지(현재 클라 로컬만) → `confirmations` 테이블 or 익명인증 도입.
4. **이미지**: 사진 도입 시 전송량(egress)·저장 폭증 주의 → CDN·압축 필수(현재는 의도적으로 텍스트만).

### 단계별 권장
| 규모 | 조치 |
|---|---|
| 지금(소규모) | Free 티어로 충분 |
| 중규모(수천 사용자/행) | Pro($25) + 인덱스 + 서버 페이지네이션(앱 코드 보완) + 풀링 |
| 대규모 | 읽기 복제본 + 캐시(CDN/Redis), 필요 시 Postgres를 전용 인스턴스로 이전 |

**요약**: 확장성·이전성 모두 양호. 지금 구조로 출시해도 되고, 커지면 **"앱의 조회를 페이지네이션으로 바꾸고 인덱스 추가"** 가 핵심 작업(플랫폼 교체 아님).

## 12. Claude로 이어서 작업할 경우
- 이 문서(`docs/HANDOFF.md`)가 핵심 컨텍스트. 새 환경에서 Claude Code를 열면 이 문서를 먼저 읽히면 됨.
- (선택) 이 세션의 누적 메모리는 원래 PC의 `C:\Users\Administrator\.claude\projects\D--Project\memory\` 에 있음. 같은 맥락을 유지하려면 그 폴더도 옮길 수 있음(필수 아님 — 이 문서로 충분).
