import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/app_colors.dart';

/// Navigation scaffold housing the official 5-tab Bottom Navigation bar
class AppBottomNavScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNavScaffold({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barBackground = isDark ? AppColors.darkSurface : Colors.white;
    final topBorderColor = isDark
        ? AppColors.darkBorder
        : AppColors.borderNeutral;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: barBackground,
          border: Border(top: BorderSide(color: topBorderColor, width: 0.8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: barBackground,
              indicatorColor: AppColors.forestSoft,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                states,
              ) {
                final isSelected = states.contains(WidgetState.selected);
                return TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryForest
                      : AppColors.textMuted,
                  letterSpacing: -0.1,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((
                states,
              ) {
                final isSelected = states.contains(WidgetState.selected);
                return IconThemeData(
                  size: 22,
                  color: isSelected
                      ? AppColors.primaryForest
                      : AppColors.textMuted,
                );
              }),
            ),
            child: NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
              elevation: 0,
              backgroundColor: Colors.transparent,
              height: 64,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Dashboard',
                  tooltip: 'Executive Dashboard',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline_rounded),
                  selectedIcon: Icon(Icons.people_rounded),
                  label: 'Students',
                  tooltip: 'Student Directory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_outlined),
                  selectedIcon: Icon(Icons.menu_book_rounded),
                  label: 'Courses',
                  tooltip: 'Curricula & Courses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.payments_outlined),
                  selectedIcon: Icon(Icons.payments_rounded),
                  label: 'Payments',
                  tooltip: 'Fee Reconciliation',
                ),
                NavigationDestination(
                  icon: Icon(Icons.widgets_outlined),
                  selectedIcon: Icon(Icons.widgets_rounded),
                  label: 'More',
                  tooltip: 'Operational Suites',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
