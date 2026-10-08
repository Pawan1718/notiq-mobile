import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_controller.dart';

/// Directory of currently available mobile workspace features.
/// Modules without a mobile implementation are deliberately not clickable.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text('Workspace', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('Manage your daily communication work',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 20),
            _WorkspaceLink(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              subtitle: 'Message totals, channels and activity',
              onTap: () => context.go('/dashboard'),
            ),
            _WorkspaceLink(
              icon: Icons.chat_bubble_outline,
              title: 'Inbox',
              subtitle: 'Conversations and replies',
              onTap: () => context.go('/inbox'),
            ),
            _WorkspaceLink(
              icon: Icons.campaign_outlined,
              title: 'Campaigns',
              subtitle: 'Drafts, scheduling and reports',
              onTap: () => context.go('/campaigns'),
            ),
            _WorkspaceLink(
              icon: Icons.people_outline,
              title: 'Contacts',
              subtitle: 'Contacts and channel consent',
              onTap: () => context.go('/contacts'),
            ),
            const SizedBox(height: 22),
            Text('Additional tools', style: theme.textTheme.titleLarge),
            const SizedBox(height: 10),
            const _UpcomingTool(title: 'Templates & providers', icon: Icons.tune),
            const _UpcomingTool(title: 'KRAG AI & team', icon: Icons.auto_awesome_outlined),
            const _UpcomingTool(title: 'Billing & settings', icon: Icons.settings_outlined),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: const Icon(Icons.logout),
              label: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceLink extends StatelessWidget {
  const _WorkspaceLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _UpcomingTool extends StatelessWidget {
  const _UpcomingTool({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 6),
    leading: Icon(icon),
    title: Text(title),
    trailing: const Text('Coming soon'),
  );
}
