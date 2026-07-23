import 'package:flutter/material.dart';
import 'theme.dart';

/// 콘센트(소켓) 모양 아이콘. "A형/C형" 텍스트 대신 실제 구멍 배치를 그린다.
/// A: 납작한 세로 구멍 2개(일본·대만·북미형) / C: 둥근 구멍 2개(유럽·한국 호환)
/// B: A + 접지 원홀 / F: 둥근 구멍 2개 + 접지 클립 / O: 둥근 구멍(태국 혼용)
class PlugIcon extends StatelessWidget {
  final String type;
  final double size;
  const PlugIcon({super.key, required this.type, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _PlugPainter(type.toUpperCase())),
    );
  }
}

class _PlugPainter extends CustomPainter {
  final String type;
  _PlugPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final face = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.06, w * 0.88, h * 0.88),
      Radius.circular(w * 0.26),
    );
    // 소켓 면
    canvas.drawRRect(face, Paint()..color = const Color(0xFFEDEFF3));
    canvas.drawRRect(
      face,
      Paint()
        ..color = AppColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    final hole = Paint()..color = const Color(0xFF37404D);
    final cx = w / 2, cy = h / 2;

    void roundHole(double dx, double dy, double r) =>
        canvas.drawCircle(Offset(cx + dx, cy + dy), r, hole);

    void flatSlot(double dx) {
      final slot = RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx + dx, cy), width: w * 0.08, height: h * 0.32),
        Radius.circular(w * 0.03),
      );
      canvas.drawRRect(slot, hole);
    }

    switch (type) {
      case 'A':
        flatSlot(-w * 0.11);
        flatSlot(w * 0.11);
        break;
      case 'B':
        flatSlot(-w * 0.12);
        flatSlot(w * 0.12);
        roundHole(0, h * 0.22, w * 0.06); // 접지
        break;
      case 'C':
        roundHole(-w * 0.13, 0, w * 0.075);
        roundHole(w * 0.13, 0, w * 0.075);
        break;
      case 'F':
        roundHole(-w * 0.13, h * 0.02, w * 0.08);
        roundHole(w * 0.13, h * 0.02, w * 0.08);
        // 상·하 접지 클립
        final clip = Paint()..color = const Color(0xFFAAB2BD);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(cx, cy - h * 0.28),
                    width: w * 0.22,
                    height: h * 0.05),
                const Radius.circular(2)),
            clip);
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromCenter(
                    center: Offset(cx, cy + h * 0.28),
                    width: w * 0.22,
                    height: h * 0.05),
                const Radius.circular(2)),
            clip);
        break;
      default: // 'O' 및 기타 → 둥근 구멍으로 표기
        roundHole(-w * 0.13, 0, w * 0.075);
        roundHole(w * 0.13, 0, w * 0.075);
    }
  }

  @override
  bool shouldRepaint(covariant _PlugPainter old) => old.type != type;
}
