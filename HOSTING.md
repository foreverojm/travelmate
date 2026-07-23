# 맛집·명소 데이터 원격 호스팅 (GitHub) — 연결 가이드

목표: 재수집한 `assets/data/osm_places.json` 을 GitHub에 올려 **raw URL**로 서빙 →
앱은 그 URL에서 데이터를 받아 갱신(앱 업데이트 불필요).

로컬 저장소는 이미 `git init` + 커밋까지 되어 있습니다. 아래 **GitHub 로그인이 필요한 3단계**만
사장님 계정으로 진행하면 됩니다.

---

## 1) GitHub에 빈 레포 만들기
- https://github.com/new 접속
- Repository name: 예) `travelmate`
- **Public** 선택 (raw URL을 앱이 자유롭게 받으려면 공개여야 함. 코드에 비밀정보 없음)
- "Add a README" 등 **체크하지 말 것** (이미 커밋이 있음)
- Create repository

## 2) 이 프로젝트를 push (D:\TravelMate 에서)
> 아래 `<USERNAME>` 를 본인 GitHub 아이디로 바꾸세요.
> 처음 push 때 브라우저 로그인 창(Git Credential Manager)이 뜨면 로그인하면 됩니다.

```powershell
cd D:\TravelMate
git remote add origin https://github.com/<USERNAME>/travelmate.git
git push -u origin main
```

## 3) 자동 재수집(Actions) 권한 켜기
- 레포 → **Settings → Actions → General → Workflow permissions**
- **"Read and write permissions"** 선택 후 저장
  (매주 자동 재수집한 JSON을 봇이 커밋할 수 있게 하기 위함)
- Actions 탭에서 `Refresh OSM places` → **Run workflow** 로 지금 한 번 수동 실행도 가능

---

## 그러면 데이터 URL은:
```
https://raw.githubusercontent.com/<USERNAME>/travelmate/main/assets/data/osm_places.json
```

## 앱에 URL 연결 (빌드 시)
```powershell
flutter build apk --release --dart-define=PLACES_URL=https://raw.githubusercontent.com/<USERNAME>/travelmate/main/assets/data/osm_places.json
```
- 또는 매번 플래그 없이 쓰고 싶으면 `lib/features/places/places_repository.dart` 의
  `remoteUrl` 기본값에 URL을 박아두면 됩니다. (아이디만 알려주시면 제가 넣어드릴게요.)

## 동작 확인
- 앱 맛집·명소 탭 → 새로고침(⟳) 또는 당겨서 새로고침 → 원격 최신 데이터 반영
- 이후 재수집(수동/주간자동)으로 JSON만 바뀌면 **사용자는 앱 업데이트 없이** 최신 맛집·명소 수신

---

## 참고
- raw URL은 CDN 캐시가 있어 갱신이 수 분 지연될 수 있음(정상).
- 코드는 공개해도 되지만 원치 않으면: 데이터용 **별도 공개 레포**에 JSON만 올리고
  앱 코드는 비공개로 둬도 됩니다(그 경우 워크플로도 데이터 레포에 둠). 필요하면 도와드릴게요.
