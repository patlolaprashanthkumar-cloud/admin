import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';

/// Navigation scaffold housing the primary 5-tab Bottom Navigation bar
class AppBottomNavScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppBottomNavScaffold({
    super.key,
    required this.navigationShell,
  });

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

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppColors.secondaryTeal.withValues(alpha: isDark ? 0.25 : 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primaryNavy)
                  : theme.colorScheme.onSurfaceVariant,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            final isSelected = states.contains(WidgetState.selected);
            return IconThemeData(
              size: 22,
              color: isSelected
                  ? (isDark ? const Color(0xFF38BDF8) : AppColors.primaryNavy)
                  : theme.colorScheme.onSurfaceVariant,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          elevation: 4,
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
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
              tooltip: 'Curriculum & Courses',
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
              label: 'Hubs',
              tooltip: 'Operational Suites',
            ),
          ],
        ),
      ),
    );
  }
}

