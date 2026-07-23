import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 국기 위젯. Android는 시스템 폰트가 국기 이모지(🇰🇷 등)를 렌더하지 않아
/// "KR" 글자로 깨진다. 그래서 에셋/폰트 없이 CustomPaint로 직접 그린다.
/// 통화코드(KRW/VND/...) 또는 국가코드(KR/VN/...) 모두 받는다.
class CountryFlag extends StatelessWidget {
  final String code;
  final double height;

  const CountryFlag({super.key, required this.code, this.height = 18});

  String get _key {
    final c = code.toUpperCase();
    if (c.startsWith('KR')) return 'KR';
    if (c.startsWith('VN')) return 'VN';
    if (c.startsWith('JP')) return 'JP';
    if (c.startsWith('TW')) return 'TW';
    if (c.startsWith('TH')) return 'TH';
    if (c.startsWith('US')) return 'US';
    return '??';
  }

  @override
  Widget build(BuildContext context) {
    final w = height * 3 / 2; // 3:2 비율
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Container(
        width: w,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: const Color(0x22000000), width: 0.5),
        ),
        child: CustomPaint(
          size: Size(w, height),
          painter: _FlagPainter(_key),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  final String key;
  _FlagPainter(this.key);

  @override
  void paint(Canvas canvas, Size size) {
    switch (key) {
      case 'KR':
        _korea(canvas, size);
        break;
      case 'VN':
        _vietnam(canvas, size);
        break;
      case 'JP':
        _japan(canvas, size);
        break;
      case 'TW':
        _taiwan(canvas, size);
        break;
      case 'TH':
        _thailand(canvas, size);
        break;
      case 'US':
        _usa(canvas, size);
        break;
      default:
        _fallback(canvas, size);
    }
  }

  void _fill(Canvas c, Rect r, Color color) =>
      c.drawRect(r, Paint()..color = color);

  // ── 대한민국: 흰 바탕 + 태극(간략화, 4괘 생략) ──
  void _korea(Canvas c, Size s) {
    _fill(c, Offset.zero & s, Colors.white);
    final center = Offset(s.width / 2, s.height / 2);
    final r = s.height * 0.28;
    const red = Color(0xFFCD2E3A);
    const blue = Color(0xFF0047A0);
    // 위 절반 빨강, 아래 절반 파랑
    final top = Rect.fromCircle(center: center, radius: r);
    c.drawArc(top, math.pi, math.pi, true, Paint()..color = red);
    c.drawArc(top, 0, math.pi, true, Paint()..color = blue);
    // 태극의 S자 곡선용 작은 원 두 개
    final hr = r / 2;
    c.drawCircle(Offset(center.dx - hr, center.dy), hr, Paint()..color = red);
    c.drawCircle(Offset(center.dx + hr, center.dy), hr, Paint()..color = blue);
  }

  // ── 베트남: 빨강 바탕 + 노란 별 ──
  void _vietnam(Canvas c, Size s) {
    _fill(c, Offset.zero & s, const Color(0xFFDA251D));
    final star = _starPath(
      center: Offset(s.width / 2, s.height / 2),
      outer: s.height * 0.32,
      inner: s.height * 0.32 * 0.42,
      points: 5,
      rotation: -math.pi / 2,
    );
    c.drawPath(star, Paint()..color = const Color(0xFFFFFF00));
  }

  // ── 일본: 흰 바탕 + 빨간 원 ──
  void _japan(Canvas c, Size s) {
    _fill(c, Offset.zero & s, Colors.white);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.height * 0.3,
        Paint()..color = const Color(0xFFBC002D));
  }

  // ── 태국: 빨-흰-파(2배)-흰-빨 5줄 ──
  void _thailand(Canvas c, Size s) {
    const red = Color(0xFFA51931);
    const white = Colors.white;
    const blue = Color(0xFF2D2A4A);
    final unit = s.height / 6;
    _fill(c, Rect.fromLTWH(0, 0, s.width, unit), red);
    _fill(c, Rect.fromLTWH(0, unit, s.width, unit), white);
    _fill(c, Rect.fromLTWH(0, unit * 2, s.width, unit * 2), blue);
    _fill(c, Rect.fromLTWH(0, unit * 4, s.width, unit), white);
    _fill(c, Rect.fromLTWH(0, unit * 5, s.width, unit), red);
  }

  // ── 대만: 빨강 바탕 + 파란 칸톤 + 흰 태양(간략화) ──
  void _taiwan(Canvas c, Size s) {
    _fill(c, Offset.zero & s, const Color(0xFFFE0000));
    const blue = Color(0xFF000095);
    final canton = Rect.fromLTWH(0, 0, s.width / 2, s.height / 2);
    _fill(c, canton, blue);
    final center = canton.center;
    // 12광선 태양(24점 별로 근사)
    final sun = _starPath(
      center: center,
      outer: s.height * 0.2,
      inner: s.height * 0.13,
      points: 12,
      rotation: 0,
    );
    c.drawPath(sun, Paint()..color = Colors.white);
    c.drawCircle(center, s.height * 0.11, Paint()..color = blue);
    c.drawCircle(center, s.height * 0.075, Paint()..color = Colors.white);
  }

  // ── 미국: 13줄 홍백 줄무늬 + 파란 칸톤(별은 점으로 간략화) ──
  void _usa(Canvas c, Size s) {
    const red = Color(0xFFB22234);
    const blue = Color(0xFF3C3B6E);
    _fill(c, Offset.zero & s, Colors.white);
    final stripe = s.height / 13;
    for (var i = 0; i < 13; i += 2) {
      _fill(c, Rect.fromLTWH(0, stripe * i, s.width, stripe), red);
    }
    final canton = Rect.fromLTWH(0, 0, s.width * 0.4, stripe * 7);
    _fill(c, canton, blue);
    // 별을 작은 흰 점 격자로 근사
    final dot = Paint()..color = Colors.white;
    final r = s.height * 0.018;
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 5; col++) {
        final dx = canton.width * (col + 1) / 6;
        final dy = canton.height * (row + 1) / 5;
        c.drawCircle(Offset(dx, dy), r, dot);
      }
    }
  }

  void _fallback(Canvas c, Size s) =>
      _fill(c, Offset.zero & s, const Color(0xFFB0B7C0));

  /// N각 별 경로. points=꼭짓점 수, outer/inner 반지름.
  Path _starPath({
    required Offset center,
    required double outer,
    required double inner,
    required int points,
    required double rotation,
  }) {
    final path = Path();
    final total = points * 2;
    for (var i = 0; i < total; i++) {
      final r = i.isEven ? outer : inner;
      final a = rotation + math.pi * i / points;
      final p = Offset(center.dx + r * math.cos(a), center.dy + r * math.sin(a));
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _FlagPainter old) => old.key != key;
}
