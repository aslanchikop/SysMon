// 🐾 Provider Navigation Tab Scaffold using Material 3 NavigationBar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class ProviderTabScaffold extends StatelessWidget {
  final Widget child;

  const ProviderTabScaffold({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/provider/calendar')) return 1;
    if (location.startsWith('/provider/services')) return 2;
    if (location.startsWith('/provider/profile')) return 3;
    return 0; // Default to /provider (Dashboard)
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/provider');
        break;
      case 1:
        context.go('/provider/calendar');
        break;
      case 2:
        context.go('/provider/services');
        break;
      case 3:
        context.go('/provider/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _onItemTapped(index, context),
        backgroundColor: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF1E1F35),
        elevation: 8,
        indicatorColor: theme.colorScheme.primary.withOpacity(0.12),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.calendar'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.room_service_outlined),
            selectedIcon: Icon(Icons.room_service_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.services'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.profile'),
          ),
        ],
      ),
    );
  }
}
