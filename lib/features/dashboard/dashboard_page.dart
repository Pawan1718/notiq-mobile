import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/widgets/notiq_metric_card.dart';
import '../../core/widgets/notiq_page_state.dart';
import 'dashboard_models.dart';
import 'dashboard_repository.dart';
import 'package:intl/intl.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(dashboardMetricsProvider),
          ),
          PopupMenuButton<String>(
            tooltip: 'Account menu',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) {
              if (value == 'logout') {
                ref.read(authProvider.notifier).logout();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded),
                    SizedBox(width: 12),
                    Text('Sign out'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: metrics.when(
          loading: () => const NotiqPageState.loading(),
          error: (_, __) => NotiqPageState.error(
            title: 'Dashboard could not be loaded',
            onRetry: () => ref.invalidate(dashboardMetricsProvider),
          ),
          data: (m) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(dashboardMetricsProvider);
              await ref.read(dashboardMetricsProvider.future);
            },
            child: _DashboardContent(metrics: m),
          ),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.metrics});
  final DashboardMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 600 ? 24.0 : 16.0;
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontal, 14, horizontal, 28),
          children: [
            _SectionTitle(
              title: 'Message activity',
              subtitle: 'Workspace totals',
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              childAspectRatio: constraints.maxWidth < 350 ? 1.08 : 1.28,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                NotiqMetricCard(
                  label: 'Total',
                  value: NumberFormat.compact().format(metrics.total),
                  icon: Icons.chat_bubble_outline_rounded,
                ),
                NotiqMetricCard(
                  label: 'Sent',
                  value: NumberFormat.compact().format(metrics.sent),
                  icon: Icons.check_circle_outline_rounded,
                ),
                NotiqMetricCard(
                  label: 'Scheduled',
                  value: NumberFormat.compact().format(metrics.scheduled),
                  icon: Icons.calendar_today_outlined,
                ),
                NotiqMetricCard(
                  label: 'Failed',
                  value: NumberFormat.compact().format(metrics.failed),
                  icon: Icons.error_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionTitle(
              title: 'Quick actions',
              subtitle: 'Pick up where you left off',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _QuickAction(
                    icon: Icons.campaign_outlined,
                    label: 'Campaigns',
                    onTap: () => context.go('/campaigns'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Inbox',
                    onTap: () => context.go('/inbox'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickAction(
                    icon: Icons.people_outline_rounded,
                    label: 'Contacts',
                    onTap: () => context.go('/contacts'),
                  ),
                ),
              ],
            ),
            if (metrics.failed > 0) ...[
              const SizedBox(height: 14),
              _FailureNotice(failed: metrics.failed),
            ],
            const SizedBox(height: 24),
            if (metrics.channelStats.isNotEmpty) ...[
              const _SectionTitle(
                title: 'Channels',
                subtitle: 'Message volume by channel',
              ),
              const SizedBox(height: 12),
              ...metrics.channelStats.map((stat) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ChannelTile(stat: stat),
              )),
              const SizedBox(height: 18),
            ],
            if (metrics.recentLogs.isNotEmpty) ...[
              const _SectionTitle(
                title: 'Recent activity',
                subtitle: 'Latest message events',
              ),
              const SizedBox(height: 12),
              ...metrics.recentLogs.take(5).map((log) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ActivityTile(log: log),
              )),
              const SizedBox(height: 18),
            ],
            const _SectionTitle(
              title: 'Jump back in',
              subtitle: 'Your most-used workspaces',
            ),
            const SizedBox(height: 12),
            _QuickLink(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Open inbox',
              subtitle: 'Review conversations and replies',
              onTap: () => context.go('/inbox'),
            ),
            const SizedBox(height: 8),
            _QuickLink(
              icon: Icons.campaign_outlined,
              title: 'Manage campaigns',
              subtitle: 'Track sends and scheduling',
              onTap: () => context.go('/campaigns'),
            ),
            const SizedBox(height: 8),
            _QuickLink(
              icon: Icons.people_outline_rounded,
              title: 'View contacts',
              subtitle: 'Find and manage recipients',
              onTap: () => context.go('/contacts'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

class _FailureNotice extends StatelessWidget {
  const _FailureNotice({required this.failed});
  final int failed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: colors.onErrorContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$failed failed messages need attention.',
              style: TextStyle(color: colors.onErrorContainer),
            ),
          ),
          TextButton(
            onPressed: () => context.go('/campaigns'),
            child: const Text('Review'),
          ),
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
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
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 15, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  const _ChannelTile({required this.stat});
  final DashboardChannelStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = stat.total <= 0 ? 0.0 : (stat.sent / stat.total).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_channelIcon(stat.channel), color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(child: Text(stat.channel, style: theme.textTheme.titleMedium)),
              Text('${stat.total} messages', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(8),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('${stat.sent} sent', style: theme.textTheme.bodySmall),
              const Spacer(),
              Text('${stat.failed} failed', style: theme.textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.log});
  final DashboardRecentLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = log.recipientName.trim().isNotEmpty
        ? log.recipientName
        : _maskedRecipient(log.recipientAddress);
    final when = log.createdAt == null
        ? ''
        : DateFormat('MMM d, h:mm a').format(log.createdAt!.toLocal());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(_channelIcon(log.channel),
                size: 19, color: theme.colorScheme.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(target.isEmpty ? 'Recipient' : target,
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
                Text('${log.channel} · $when',
                    style: theme.textTheme.bodySmall,
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(log.status,
              style: theme.textTheme.labelSmall?.copyWith(
                color: log.status == 'Failed'
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              )),
        ],
      ),
    );
  }
}

IconData _channelIcon(String channel) {
  switch (channel) {
    case 'WhatsApp':
      return Icons.chat_outlined;
    case 'Email':
      return Icons.mail_outline;
    case 'SMS':
      return Icons.sms_outlined;
    default:
      return Icons.notifications_none;
  }
}

String _maskedRecipient(String value) {
  if (value.length <= 4) return '••••';
  return '••••${value.substring(value.length - 4)}';
}
