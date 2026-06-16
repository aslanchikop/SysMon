// 🐾 Owner Navigation Tab Scaffold using Material 3 NavigationBar

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class OwnerTabScaffold extends StatelessWidget {
  final Widget child;

  const OwnerTabScaffold({
    super.key,
    required this.child,
  });

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/owner/search')) return 1;
    if (location.startsWith('/owner/pets')) return 2;
    if (location.startsWith('/owner/bookings')) return 3;
    if (location.startsWith('/owner/profile')) return 4;
    return 0; // Default to /owner (Home)
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/owner');
        break;
      case 1:
        context.go('/owner/search');
        break;
      case 2:
        context.go('/owner/pets');
        break;
      case 3:
        context.go('/owner/bookings');
        break;
      case 4:
        context.go('/owner/profile');
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
            icon: const Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.search'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.pets_outlined),
            selectedIcon: Icon(Icons.pets_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.pets'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.bookings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: theme.colorScheme.primary),
            label: tr('tabs.profile'),
          ),
        ],
      ),
    );
  }
}
