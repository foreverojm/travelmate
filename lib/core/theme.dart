import 'package:flutter/material.dart';

/// 앱 전역 색/타이포. 여행 앱이지만 '신뢰감 있는 도구' 느낌을 목표로
/// 채도 낮은 딥 잉크 + 포인트 앰버(현금/환율의 연상)로 절제되게 구성.
class AppColors {
  static const ink = Color(0xFF13233A); // 메인 텍스트/헤더
  static const primary = Color(0xFF1E5B8F); // 브랜드 블루
  static const accent = Color(0xFFE8A13A); // 포인트(환율/현금)
  static const danger = Color(0xFFD8493B); // 긴급/경고
  static const success = Color(0xFF2E9E6B);

  static const bg = Color(0xFFF6F7F9); // 배경
  static const surface = Color(0xFFFFFFFF); // 카드
  static const surfaceAlt = Color(0xFFEDF0F4); // 보조 표면
  static const line = Color(0xFFE1E5EB); // 구분선
  static const textMuted = Color(0xFF6B7686); // 보조 텍스트
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    fontFamily: 'Roboto',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: AppColors.ink),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
