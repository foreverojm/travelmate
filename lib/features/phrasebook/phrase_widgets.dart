import 'package:flutter/material.dart';
import '../../core/models.dart';
import '../../core/theme.dart';
import 'phrase_tts.dart';

/// 현지어 한 줄 카드. 탭하면 전체화면(세로 초대형)으로 확대해 상대에게 보여준다.
/// 우측 스피커로 그 자리에서 현지어 발음을 바로 재생할 수도 있다.
class PhraseTile extends StatelessWidget {
  final PhraseCard phrase;
  final String localeTag; // TTS 로케일 (예: 'vi-VN')
  const PhraseTile({super.key, required this.phrase, required this.localeTag});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => showPhraseFullscreen(context, phrase, localeTag),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(phrase.ko,
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(phrase.local,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('[${phrase.pron}]',
                          style: const TextStyle(
                              color: AppColors.primary, fontSize: 13)),
                    ],
                  ),
                ),
                // 바로 듣기
                IconButton(
                  tooltip: '발음 듣기',
                  icon: const Icon(Icons.volume_up, color: AppColors.primary),
                  onPressed: () =>
                      PhraseTts.instance.speak(phrase.local, localeTag),
                ),
                // 확대해서 보여주기
                IconButton(
                  tooltip: '크게 보여주기',
                  icon: const Icon(Icons.fullscreen, color: AppColors.textMuted),
                  onPressed: () =>
                      showPhraseFullscreen(context, phrase, localeTag),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상대에게 보여주는 전체화면 카드(세로 초대형 글자 + 발음 재생).
void showPhraseFullscreen(
    BuildContext context, PhraseCard phrase, String localeTag) {
  showDialog(
    context: context,
    barrierColor: Colors.black87,
    builder: (_) => _PhraseFullscreen(phrase: phrase, localeTag: localeTag),
  );
}

class _PhraseFullscreen extends StatefulWidget {
  final PhraseCard phrase;
  final String localeTag;
  const _PhraseFullscreen({required this.phrase, required this.localeTag});

  @override
  State<_PhraseFullscreen> createState() => _PhraseFullscreenState();
}

class _PhraseFullscreenState extends State<_PhraseFullscreen> {
  bool _speaking = false;
  bool? _voiceMissing; // true면 기기에 해당 언어 음성 없음(무음 가능)

  @override
  void initState() {
    super.initState();
    _check();
    // 열자마자 한 번 읽어준다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  Future<void> _check() async {
    final ok = await PhraseTts.instance.isAvailable(widget.localeTag);
    if (mounted) setState(() => _voiceMissing = !ok);
  }

  Future<void> _speak() async {
    if (!mounted) return;
    setState(() => _speaking = true);
    await PhraseTts.instance.speak(widget.phrase.local, widget.localeTag);
    if (mounted) setState(() => _speaking = false);
  }

  @override
  void dispose() {
    PhraseTts.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ph = widget.phrase;
    return Dialog(
      insetPadding: const EdgeInsets.all(10),
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            // 한국어(작게)
            Text(ph.ko,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 17)),
            // 현지어(화면폭 가득 세로 초대형)
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      ph.local,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 76,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // 발음(한글)
            Text('[${ph.pron}]',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.accent, fontSize: 20)),
            if (_voiceMissing == true)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Text(
                  '이 기기에 해당 언어 음성이 없어 무음일 수 있어요.\n설정 > 언어·입력 > 음성에서 추가하면 들립니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.4),
                ),
              ),
            const SizedBox(height: 18),
            // 발음 듣기(크게)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _speaking ? null : _speak,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                icon: Icon(_speaking ? Icons.volume_up : Icons.play_arrow),
                label: Text(_speaking ? '재생 중…' : '발음 듣기',
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }
}
