import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme.dart';

/// 긴급 사이렌 버튼. 누르면 합성 사이렌음을 최대 음량으로 반복 재생해
/// 주변에 위험을 알린다. 다시 누르면 정지. (오작동 방지 위해 명확한 on/off)
class SirenButton extends StatefulWidget {
  const SirenButton({super.key});

  @override
  State<SirenButton> createState() => _SirenButtonState();
}

class _SirenButtonState extends State<SirenButton>
    with SingleTickerProviderStateMixin {
  final _player = AudioPlayer();
  late final AnimationController _pulse;
  bool _on = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    HapticFeedback.heavyImpact();
    if (_on) {
      await _player.stop();
      setState(() => _on = false);
    } else {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/siren.wav'));
      setState(() => _on = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glow = _on ? (0.25 + 0.35 * _pulse.value) : 0.0;
        return Material(
          color: _on ? AppColors.danger : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: _toggle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.danger, width: 1.5),
                boxShadow: _on
                    ? [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: glow),
                          blurRadius: 18,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(_on ? Icons.volume_up : Icons.campaign,
                      color: _on ? Colors.white : AppColors.danger),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_on ? '사이렌 끄기' : '사이렌 (주변에 알리기)',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _on ? Colors.white : AppColors.ink)),
                        Text(_on ? '재생 중… 다시 누르면 정지' : '큰 소리로 위험을 알립니다',
                            style: TextStyle(
                                fontSize: 12,
                                color: _on
                                    ? Colors.white70
                                    : AppColors.textMuted)),
                      ],
                    ),
                  ),
                  if (_on)
                    const Icon(Icons.stop_circle, color: Colors.white)
                  else
                    const Icon(Icons.play_circle_outline,
                        color: AppColors.danger),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
