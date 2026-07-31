import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// 더보기 탭. 앱 정보 + 향후 수익화(프리미엄/광고) 진입점을 구조적으로 잡아둔다.
/// 지금은 대부분 '준비 중' 상태지만, 배포 후 이 자리에 기능을 붙인다.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('더보기')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // 프리미엄 전환 진입점(수익화 A안)
          _PremiumTeaser(),
          const SizedBox(height: 16),

          _group('앱 정보'),
          _tile(Icons.info_outline, '버전', trailing: '1.3.0'),
          _tile(Icons.flag_outlined, '지원 국가', trailing: '베트남·일본·대만·태국'),
          const SizedBox(height: 16),

          _group('약관 · 정책'),
          _tile(Icons.privacy_tip_outlined, '개인정보처리방침', trailing: '준비 중'),
          _tile(Icons.description_outlined, '이용약관', trailing: '준비 중'),
          const SizedBox(height: 16),

          _group('안내'),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              '본 앱의 환율은 참고용이며 실제 환전·결제 금액과 차이가 있을 수 있습니다. '
              '긴급전화·대사관 정보는 변동될 수 있으니 출발 전 최신 정보를 확인하세요.\n\n'
              '지도 정보(POI) 일부는 © OpenStreetMap 기여자 (ODbL)의 데이터를 사용합니다.',
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textMuted, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(String t) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(t,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
      );

  Widget _tile(IconData icon, String title,
      {String? trailing, VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing != null
            ? Text(trailing,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13))
            : const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}

/// 프리미엄 안내 배너(수익화 A안: 무료→유료 전환).
/// 실제 결제 연동 전까지는 '준비 중' 상태로 자리만 잡아둔다.
class _PremiumTeaser extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.ink, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.workspace_premium_outlined, color: Colors.white),
              SizedBox(width: 8),
              Text('프리미엄 (준비 중)',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '광고 제거 · 오프라인 지도 · 도시별 프리미엄 큐레이션을 준비하고 있어요.',
            style: TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
