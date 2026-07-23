# TravelMate — 다른 PC로 이전 & 셋업 가이드

이 프로젝트는 **`D:\TravelMate` 폴더 하나에 전부 들어있습니다.** 이 폴더를 복사해
아래 준비물만 갖추면 다른 PC에서 그대로 이어서 개발할 수 있습니다.

---

## 1. 무엇을 옮기나 — 폴더 전체 복사

`TravelMate` 폴더를 통째로 복사하면 됩니다. 단, 아래 폴더는 **자동 생성물**이라
복사에서 빼도 되고(용량↓·복사 빠름), 새 PC에서 `flutter pub get` 하면 다시 생깁니다.

**빼도 되는 것(재생성됨):**
```
build/                 # 빌드 결과(APK 등) — 매우 큼
.dart_tool/            # pub 캐시 참조
android/.gradle/       # Gradle 캐시
android/app/build/
ios/Pods/  ios/.symlinks/
.idea/  *.iml          # IDE 설정
```
> `.gitignore` 에 위 목록이 정의돼 있으니, git으로 옮기면 자동으로 제외됩니다.

**반드시 있어야 하는 것(실제 프로젝트):**
```
lib/                   # 앱 소스코드 전체
assets/                # 사이렌 음원(audio), 장소 데이터(data/osm_places.json)
test/
tools/fetch_osm.py     # OSM 무료 수집 스크립트
android/  ios/  web/    # 플랫폼 폴더(위 build/.gradle 제외)
pubspec.yaml  pubspec.lock
.github/               # 재수집 자동화 워크플로
TECH_REPORT.md  SETUP.md
```

> ⚠️ 이 앱 자체와 무관한 것: Claude의 메모리 파일(`~/.claude/...`)은 프로젝트가 아니라
> 개발 보조 기록입니다. 앱 이전에는 필요 없습니다.

---

## 2. 새 PC 준비물

1. **Flutter SDK** (이 프로젝트 기준 3.27.x, Dart 3.6+)
   - https://docs.flutter.dev/get-started/install/windows
   - 예: `C:\flutter` 에 풀고, `C:\flutter\bin` 을 시스템 PATH 에 추가
2. **JDK 17** (안드로이드 빌드용)
   - 예: `C:\jdk-17...` 에 설치 후 Flutter에 지정:
     ```
     flutter config --jdk-dir "C:\path\to\jdk-17"
     ```
3. **Android SDK** (APK 빌드/에뮬레이터) — Android Studio 설치 시 함께 옴
   - `flutter doctor` 로 부족한 항목 확인

---

## 3. 새 PC에서 실행

```powershell
cd C:\경로\TravelMate
flutter pub get         # 의존성 복원 (.dart_tool 등 재생성)
flutter analyze         # 코드 점검 (0 issues 여야 정상)
flutter test            # 스모크 테스트
flutter run             # 연결된 기기/에뮬레이터에서 실행
flutter build apk --release   # 배포용 APK
```
빌드 결과: `build\app\outputs\flutter-apk\app-release.apk`

편의를 위해 `tools\setup.ps1` 을 실행하면 pub get + doctor 를 한 번에 돌립니다.

---

## 4. 데이터 갱신은 앱 업데이트가 필요 없음 (중요)

장소(OSM) 데이터는 앱에 **하드코딩하지 않고** `assets/data/osm_places.json` 을
런타임에 읽고, 원격 URL이 설정돼 있으면 그걸 받아 **오프라인 캐싱**합니다.

- 재수집: `python tools/fetch_osm.py` → `assets/data/osm_places.json` 갱신
- 원격 URL 설정 시(빌드 옵션): `flutter build apk --dart-define=PLACES_URL=<json 주소>`
- 그 URL의 JSON만 새로 올리면 **사용자는 앱 업데이트 없이** 최신 데이터를 받음
- 자동화: `.github/workflows/refresh-places.yml` (매주 자동 재수집·커밋)

---

## 5. 현재 상태 / 다음 작업
- 진행 상황과 스토어 체크리스트는 `TECH_REPORT.md` 참고.
