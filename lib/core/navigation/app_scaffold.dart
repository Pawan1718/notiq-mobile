import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_controller.dart';
import '../theme/notiq_theme.dart';
import '../theme/theme_controller.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.title, required this.child, this.actions});

  final String title;
  final Widget child;
  final List<Widget>? actions;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(icon: Icon(Icons.space_dashboard_outlined),
        selectedIcon: Icon(Icons.space_dashboard), label: 'Dashboard'),
    NavigationDestination(icon: Icon(Icons.forum_outlined),
        selectedIcon: Icon(Icons.forum), label: 'Inbox'),
    NavigationDestination(icon: Icon(Icons.campaign_outlined),
        selectedIcon: Icon(Icons.campaign), label: 'Campaigns'),
    NavigationDestination(icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people), label: 'Contacts'),
  ];
  static const _paths = ['/dashboard', '/inbox', '/campaigns', '/contacts'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = _paths.indexOf(location);
    final index = selected < 0 ? 0 : selected;
    final mode = ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system;
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('notiq', style: TextStyle(
            color: NotiqTheme.violet, fontWeight: FontWeight.w800,
            letterSpacing: -1)),
          const SizedBox(width: 12),
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
        ]),
        actions: [
          ...?actions,
          PopupMenuButton<ThemeMode>(
            tooltip: 'Appearance',
            icon: const Icon(Icons.brightness_6_outlined),
            initialValue: mode,
            onSelected: (choice) =>
                ref.read(themeModeProvider.notifier).setThemeMode(choice),
            itemBuilder: (_) => const [
              PopupMenuItem(value: ThemeMode.system, child: Text('System theme')),
              PopupMenuItem(value: ThemeMode.light, child: Text('Light theme')),
              PopupMenuItem(value: ThemeMode.dark, child: Text('Dark theme')),
            ],
          ),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: _destinations,
        onDestinationSelected: (next) {
          if (next != index) context.go(_paths[next]);
        },
      ),
    );
  }
}
