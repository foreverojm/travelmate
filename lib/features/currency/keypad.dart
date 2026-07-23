import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

/// 계산기 전용 숫자패드.
/// 시스템 키보드는 뜨는 속도·레이아웃이 들쭉날쭉해서
/// 시장에서 빠르게 두드리는 상황엔 전용 패드가 훨씬 쾌적하다.
class Keypad extends StatelessWidget {
  final void Function(String digit) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const Keypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
      child: Column(
        children: [
          _row(['1', '2', '3']),
          _row(['4', '5', '6']),
          _row(['7', '8', '9']),
          Row(
            children: [
              // 전체 삭제
              _key(
                child: const Text('C',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.danger)),
                onTap: onClear,
              ),
              _key(label: '0', onTap: () => onDigit('0')),
              _key(
                child: const Icon(Icons.backspace_outlined, size: 22),
                onTap: onBackspace,
                onLongPress: onClear, // 길게 눌러도 전체 삭제
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<String> digits) =>
      Row(children: digits.map((d) => _key(label: d, onTap: () => onDigit(d))).toList());

  Widget _key({
    String? label,
    Widget? child,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            onLongPress: onLongPress == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onLongPress();
                  },
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: child ??
                  Text(
                    label ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
