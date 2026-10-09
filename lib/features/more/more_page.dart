import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import 'readonly_catalog_pages.dart';
import 'workspace_read_pages.dart';
import 'preferences_help_page.dart';

/// Workspace settings directory. Unsupported mobile destinations are disabled.
class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(Icons.business_outlined, color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Workspace', style: theme.textTheme.titleMedium),
                    Text('Settings and account tools',
                      style: theme.textTheme.bodySmall),
                  ],
                )),
              ]),
            ),
            const SizedBox(height: 24),
            _MenuSection(
              title: 'Communication',
              items: [
                _MenuItem('Providers', Icons.settings_input_component_outlined,
                  'WhatsApp, SMS & Email', page: ProviderCatalogPage()),
                _MenuItem('Templates', Icons.article_outlined,
                  'Message templates', page: TemplateCatalogPage()),
                _MenuItem('AI & automation', Icons.auto_awesome_outlined,
                  'Bot and routing settings'),
                _MenuItem('Webhooks', Icons.webhook_outlined,
                  'Events and integrations'),
              ],
            ),
            const SizedBox(height: 22),
            _MenuSection(
              title: 'Workspace',
              items: [
                _MenuItem('Team members', Icons.group_outlined,
                  'Workspace access', page: TeamReadPage()),
                _MenuItem('Roles & permissions', Icons.admin_panel_settings_outlined,
                  'Access control', page: RolesReadPage()),
                _MenuItem('Plan & billing', Icons.credit_card_outlined,
                  'Subscription details', page: SubscriptionReadPage()),
                _MenuItem('Usage & costs', Icons.bar_chart_outlined,
                  'Communication usage', page: UsageReadPage()),
              ],
            ),
            const SizedBox(height: 22),
            _MenuSection(
              title: 'Account',
              items: [
                _MenuItem('My profile', Icons.person_outline_rounded,
                  'Personal information'),
                _MenuItem('Preferences', Icons.tune_rounded,
                  'App preferences', page: PreferencesPage()),
                _MenuItem('Help & support', Icons.help_outline_rounded,
                  'Support resources', page: HelpSupportPage()),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              icon: Icon(Icons.logout_rounded, color: colors.error),
              label: Text('Sign out', style: TextStyle(color: colors.error)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem(this.title, this.icon, this.subtitle, {this.page});
  final String title;
  final IconData icon;
  final String subtitle;
  final Widget? page;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.items});
  final String title;
  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(title, style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          )),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: [
            for (var index = 0; index < items.length; index++) ...[
              if (index > 0) const Divider(height: 1, indent: 54),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                dense: true,
                leading: Icon(items[index].icon, color: colors.primary, size: 21),
                title: Text(items[index].title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  )),
                subtitle: Text(items[index].subtitle,
                  style: theme.textTheme.bodySmall),
                trailing: items[index].page == null
                    ? Text('Soon', style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant))
                    : const Icon(Icons.chevron_right_rounded),
                onTap: items[index].page == null ? null : () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => items[index].page!),
                ),
              ),
            ],
          ]),
        ),
      ],
    );
  }
}
