// TravelMate 기본 스모크 테스트.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:travel_mate/features/currency/currency_provider.dart';
import 'package:travel_mate/features/currency/rate_service.dart';
import 'package:travel_mate/features/places/places_provider.dart';
import 'package:travel_mate/features/places/places_repository.dart';
import 'package:travel_mate/home/home_shell.dart';

void main() {
  testWidgets('앱이 뜨고 하단 탭 4개가 보인다', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => CurrencyProvider(RateService())),
          ChangeNotifierProvider(create: (_) => PlacesProvider(PlacesRepository())),
        ],
        child: const MaterialApp(home: HomeShell()),
      ),
    );
    await tester.pump();

    expect(find.text('환율'), findsWidgets);
    expect(find.text('맛집·명소'), findsOneWidget);
    expect(find.text('긴급'), findsOneWidget);
    expect(find.text('더보기'), findsOneWidget);
  });
}
