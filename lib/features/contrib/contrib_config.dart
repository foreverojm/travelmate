/// 여행자 제보(커뮤니티 공유) 백엔드 설정.
/// Supabase REST를 http로 직접 호출 → 네이티브 플러그인 불필요.
///
/// 사용법: Supabase 프로젝트를 만든 뒤 아래 두 값을 채우면 기능이 켜진다.
/// (anon 키는 클라이언트 공개용 키로, Row Level Security로 보호되므로 앱에 넣어도 안전)
/// 빌드 시 --dart-define 으로도 덮어쓸 수 있다.
library;

class ContribConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '', // 예: https://xxxx.supabase.co
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// 두 값이 채워져 있으면 제보 기능 활성화.
  static bool get enabled =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  /// «검증됨»으로 승격되는 최소 "가봤어요" 수.
  static const int verifyThreshold = 3;

  /// 기기당 하루 최대 제보 수(스팸 방지).
  static const int dailySubmitLimit = 5;
}
