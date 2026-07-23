import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// 외부 앱 연동(전화/지도) 헬퍼. 실패 시 스낵바로 조용히 안내.
class AppLauncher {
  /// 전화 걸기. 번호의 공백·하이픈은 그대로 둬도 됨(다이얼러가 처리).
  static Future<void> dial(BuildContext context, String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    await _launch(context, uri, '전화 앱을 열 수 없습니다: $number');
  }

  /// 좌표를 지도 앱에서 열기(라벨 포함). 플랫폼 기본 지도 앱으로.
  static Future<void> openMap(
      BuildContext context, double lat, double lng, String label) async {
    // geo: 스킴이 가장 범용적. 실패 시 구글맵 웹으로 폴백.
    final geo = Uri.parse('geo:$lat,$lng?q=$lat,$lng($label)');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    final web = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await _launch(context, web, '지도 앱을 열 수 없습니다');
  }

  /// 좌표가 없을 때: 이름+지역으로 지도 검색.
  static Future<void> openMapSearch(BuildContext context, String query) async {
    final geo = Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(geo)) {
      await launchUrl(geo, mode: LaunchMode.externalApplication);
      return;
    }
    if (!context.mounted) return;
    final web = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}');
    await _launch(context, web, '지도 앱을 열 수 없습니다');
  }

  static Future<void> _launch(
      BuildContext context, Uri uri, String errorMsg) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) _toast(context, errorMsg);
    } catch (_) {
      if (context.mounted) _toast(context, errorMsg);
    }
  }

  static void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
