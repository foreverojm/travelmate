# TravelMate 새 PC 셋업 도우미
# 사용: 프로젝트 루트에서  powershell -ExecutionPolicy Bypass -File tools\setup.ps1
# (flutter 가 PATH 에 있어야 함. 없으면 SETUP.md 참고해 먼저 설치)

Write-Host "== TravelMate setup ==" -ForegroundColor Cyan

$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $flutter) {
    Write-Host "flutter 를 PATH 에서 찾을 수 없습니다. SETUP.md 를 참고해 Flutter SDK 를 설치하고 PATH 에 추가하세요." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[1/3] flutter pub get" -ForegroundColor Green
flutter pub get

Write-Host "`n[2/3] flutter doctor (환경 점검)" -ForegroundColor Green
flutter doctor

Write-Host "`n[3/3] flutter analyze" -ForegroundColor Green
flutter analyze

Write-Host "`n완료. 실행: flutter run  /  배포 빌드: flutter build apk --release" -ForegroundColor Cyan
Write-Host "JDK 17 미설정 시:  flutter config --jdk-dir `"C:\path\to\jdk-17`"" -ForegroundColor DarkGray
