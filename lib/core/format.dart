import 'package:intl/intl.dart';
import 'models.dart';

/// 통화 표시 포맷 모음.
class Fmt {
  /// 금액을 천단위 구분 + 통화별 소수 자릿수로 표기.
  static String amount(num value, Currency c) {
    final pattern = c.decimalDigits > 0
        ? '#,##0.${'0' * c.decimalDigits}'
        : '#,##0';
    return NumberFormat(pattern).format(value);
  }

  /// 입력 중인 원문 문자열(사용자가 친 그대로)을 천단위만 입혀 표시.
  /// 소수점 입력 중(예: "12.")도 자연스럽게 유지.
  static String liveInput(String raw) {
    if (raw.isEmpty) return '0';
    final neg = raw.startsWith('-');
    final s = neg ? raw.substring(1) : raw;
    final parts = s.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final grouped =
        NumberFormat('#,##0').format(int.tryParse(intPart) ?? 0);
    String out = grouped;
    if (parts.length > 1) out = '$grouped.${parts[1]}';
    return neg ? '-$out' : out;
  }

  /// 단가 표기: 아주 작은 값이면 유효숫자를 더 보여준다.
  static String rate(num value) {
    if (value == 0) return '0';
    if (value >= 100) return NumberFormat('#,##0.##').format(value);
    if (value >= 1) return NumberFormat('0.###').format(value);
    if (value >= 0.01) return NumberFormat('0.####').format(value);
    return NumberFormat('0.000000').format(value);
  }

  /// "3분 전 / 2시간 전 / 어제" 형태의 상대 시각.
  static String relativeTime(DateTime t, DateTime now) {
    if (t.millisecondsSinceEpoch == 0) return '갱신 전';
    final d = now.difference(t);
    if (d.inSeconds < 60) return '방금 갱신';
    if (d.inMinutes < 60) return '${d.inMinutes}분 전';
    if (d.inHours < 24) return '${d.inHours}시간 전';
    if (d.inDays == 1) return '어제';
    return '${d.inDays}일 전';
  }
}
