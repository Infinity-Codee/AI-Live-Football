/// Main Screen — Holds the Bottom Navigation Bar
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/app_strings.dart';
import '../home/home_screen.dart';
import '../standings/standings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const StandingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>(); // rebuild nav labels on language switch
    return PopScope(
      // Allow the app to exit only from the Home tab; otherwise the system
      // back gesture returns to Home instead of quitting the app.
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            backgroundColor: AppTheme.bgSurface,
            indicatorColor: AppTheme.primary.withValues(alpha: 0.2),
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home, color: AppTheme.primary),
                label: tr('nav.home'),
              ),
              NavigationDestination(
                icon: const Icon(Icons.table_chart_outlined),
                selectedIcon: const Icon(Icons.table_chart, color: AppTheme.primary),
                label: tr('nav.standings'),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
