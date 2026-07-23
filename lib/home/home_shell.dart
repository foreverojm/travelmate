import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../features/currency/currency_screen.dart';
import '../features/more/more_screen.dart';
import '../features/places/places_screen.dart';
import '../features/sos/sos_screen.dart';

/// 하단 탭 4개를 담는 셸. 탭 전환 시 각 화면 상태를 유지(IndexedStack).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _screens = [
    CurrencyScreen(),
    PlacesScreen(),
    SosScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate, color: AppColors.primary),
            label: '환율',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant, color: AppColors.primary),
            label: '맛집·명소',
          ),
          NavigationDestination(
            icon: Icon(Icons.sos_outlined),
            selectedIcon: Icon(Icons.sos, color: AppColors.danger),
            label: '긴급',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz, color: AppColors.primary),
            label: '더보기',
          ),
        ],
      ),
    );
  }
}
