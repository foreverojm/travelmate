import 'package:flutter/material.dart';
import '../../core/country_data.dart';
import '../../core/flag.dart';
import '../../core/models.dart';
import '../../core/theme.dart';

/// 통화 선택 바텀시트. from/to 버튼을 누르면 뜬다.
Future<Currency?> showCurrencyPicker(
  BuildContext context, {
  required Currency current,
}) {
  return showModalBottomSheet<Currency>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('통화 선택',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
            ...allCurrencies.map((c) {
              final selected = c.code == current.code;
              return ListTile(
                leading: CountryFlag(code: c.code, height: 22),
                title: Text('${c.name}  (${c.code})',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(c.symbol,
                    style: const TextStyle(color: AppColors.textMuted)),
                trailing: selected
                    ? const Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, c),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}
