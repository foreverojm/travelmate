import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'features/currency/currency_provider.dart';
import 'features/currency/rate_service.dart';
import 'features/places/places_provider.dart';
import 'features/places/places_repository.dart';
import 'features/prices/prices_provider.dart';
import 'features/prices/prices_repository.dart';
import 'features/contrib/contrib_provider.dart';
import 'features/contrib/contrib_service.dart';
import 'home/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TravelMateApp());
}

class TravelMateApp extends StatelessWidget {
  const TravelMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CurrencyProvider(RateService())..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => PlacesProvider(PlacesRepository())..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => PricesProvider(PricesRepository())..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => ContribProvider(ContribService())..init(),
        ),
      ],
      child: MaterialApp(
        title: 'TravelMate',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: const HomeShell(),
      ),
    );
  }
}
