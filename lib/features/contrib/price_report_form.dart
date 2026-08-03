import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/pills.dart';
import '../../core/theme.dart';
import '../places/place_data.dart';
import 'contrib_provider.dart';
import 'user_place.dart';

/// 시세 제보 폼: 실제로 지불한 가격을 공유(별점 아닌 실제 가격 기반).
class PriceReportForm extends StatefulWidget {
  final String initialCountry;
  final UserPlace? existing; // 있으면 수정 모드
  const PriceReportForm(
      {super.key, required this.initialCountry, this.existing});

  @override
  State<PriceReportForm> createState() => _PriceReportFormState();
}

class _PriceReportFormState extends State<PriceReportForm> {
  late String _cc = widget.initialCountry;
  String? _city;
  bool _customCity = false;
  bool _paid = false;
  bool _submitting = false;

  final _item = TextEditingController();
  final _price = TextEditingController();
  final _note = TextEditingController();
  final _cityCtrl = TextEditingController();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _cc = e.countryCode;
      final known = citiesByCountry[e.countryCode] ?? const [];
      if (known.contains(e.city)) {
        _city = e.city;
      } else {
        _customCity = true;
        _cityCtrl.text = e.city;
        _city = e.city;
      }
      _item.text = e.name;
      _price.text = e.priceHint;
      _note.text = e.note;
      _paid = true;
    }
  }

  @override
  void dispose() {
    _item.dispose();
    _price.dispose();
    _note.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final item = _item.text.trim();
    final price = _price.text.trim();
    if (_city == null) return _toast('도시를 선택하거나 입력해 주세요.');
    if (item.isEmpty) return _toast('품목을 적어주세요.');
    if (price.isEmpty) return _toast('지불한 가격을 적어주세요.');
    if (!_paid) return _toast('“직접 사봤어요”를 체크해 주세요.');

    final prov = context.read<ContribProvider>();
    if (!_isEdit && !await prov.canSubmitToday()) {
      return _toast('오늘 제보 한도를 초과했어요. 내일 다시 부탁드려요.');
    }
    setState(() => _submitting = true);
    final data = UserPlace(
      id: widget.existing?.id ?? '',
      type: 'price',
      countryCode: _cc,
      city: _city!,
      name: item,
      kind: 'price',
      priceHint: price,
      note: _note.text.trim(),
    );
    final ok =
        _isEdit ? await prov.updateOwn(data) : (await prov.submit(data));
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      _toast(_isEdit ? '수정됐어요.' : '시세 제보 감사합니다! 다른 여행자가 확인하면 신뢰도가 올라가요.');
      Navigator.pop(context);
    } else {
      _toast(_isEdit ? '수정에 실패했어요.' : '등록에 실패했어요. 잠시 후 다시 시도해 주세요.');
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final cities = citiesByCountry[_cc] ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '시세 제보 수정' : '시세 제보')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              '실제로 «지불한 가격»을 공유해요. 블로그 별점이 아니라 진짜 가격이라 '
              '다른 여행자가 바가지인지 판단하는 데 큰 도움이 됩니다.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 16),
          _label('나라'),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: countries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final c = countries[i];
                return SelectPill(
                  label: c.nameKo,
                  selected: c.code == _cc,
                  leading: CountryFlag(code: c.code, height: 15),
                  onTap: () => setState(() {
                    _cc = c.code;
                    _city = null;
                    _customCity = false;
                    _cityCtrl.clear();
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          _label('도시'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final city in cities)
                SelectPill(
                  label: city,
                  selected: !_customCity && _city == city,
                  onTap: () => setState(() {
                    _customCity = false;
                    _cityCtrl.clear();
                    _city = city;
                  }),
                ),
              SelectPill(
                label: _customCity ? '✎ 새 도시' : '＋ 다른 도시',
                selected: _customCity,
                onTap: () => setState(() {
                  _customCity = true;
                  _city = _cityCtrl.text.trim().isEmpty
                      ? null
                      : _cityCtrl.text.trim();
                }),
              ),
            ],
          ),
          if (_customCity) ...[
            const SizedBox(height: 8),
            _field(_cityCtrl, '도시 이름 (예: 달랏, 붕따우)',
                onChanged: (v) =>
                    setState(() => _city = v.trim().isEmpty ? null : v.trim())),
          ],
          const SizedBox(height: 14),
          _label('품목'),
          _field(_item, '예: 반팔 티셔츠 / 쌀국수 / 크록스'),
          const SizedBox(height: 14),
          _label('지불한 가격'),
          _field(_price, '예: ₫ 8만 / ฿ 60 / 5,000원'),
          const SizedBox(height: 14),
          _label('메모 (선택 · 어디서·흥정 여부 등)'),
          _field(_note, '예: 담시장, 15만 부르는 걸 8만에 흥정', maxLines: 3),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _paid = !_paid),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _paid
                    ? AppColors.success.withValues(alpha: 0.10)
                    : AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: _paid ? AppColors.success : AppColors.line),
              ),
              child: Row(
                children: [
                  Icon(_paid ? Icons.check_circle : Icons.circle_outlined,
                      color: _paid ? AppColors.success : AppColors.textMuted),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text('직접 사봤어요 (필수)',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            child: Text(
                _submitting ? '저장 중…' : (_isEdit ? '수정 저장' : '시세 제보 등록'),
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
      );

  Widget _field(TextEditingController c, String hint,
          {int maxLines = 1, ValueChanged<String>? onChanged}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          isDense: true,
          hintText: hint,
          filled: true,
          fillColor: AppColors.surfaceAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
