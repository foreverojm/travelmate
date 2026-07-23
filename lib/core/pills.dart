import 'package:flutter/material.dart';
import 'theme.dart';

/// 선택형 알약 버튼. Material ChoiceChip/FilterChip이 가로 스크롤에서
/// 한글 라벨을 잘라먹는 문제가 있어, 라벨이 항상 온전히 보이도록 직접 만든다.
class SelectPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Color activeColor;

  const SelectPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.leading,
    this.activeColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? activeColor : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.ink;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? activeColor : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(fontWeight: FontWeight.w700, color: fg),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
