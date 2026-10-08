import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One navigation surface shared by the four existing tenant routes.
class NotiqAppShell extends StatelessWidget {
  const NotiqAppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.chat_bubble_outline_rounded),
      selectedIcon: Icon(Icons.chat_bubble_rounded),
      label: 'Inbox',
    ),
    NavigationDestination(
      icon: Icon(Icons.campaign_outlined),
      selectedIcon: Icon(Icons.campaign_rounded),
      label: 'Campaigns',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline_rounded),
      selectedIcon: Icon(Icons.people_rounded),
      label: 'Contacts',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(color: colors.outlineVariant.withValues(alpha: .6)),
          ),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            height: 70,
            elevation: 0,
            backgroundColor: colors.surface,
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: navigationShell.currentIndex,
            destinations: destinations,
            onDestinationSelected: (index) => navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            ),
          ),
        ),
      ),
    );
  }
}
