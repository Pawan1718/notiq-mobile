import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/notiq_brand.dart';
import '../../core/widgets/notiq_metric_card.dart';
import '../../core/widgets/notiq_page_state.dart';
import '../../core/widgets/notiq_section_header.dart';
import 'dashboard_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    return Scaffold(
      appBar: AppBar(title: const NotiqBrand(compact: true), actions: [
        IconButton(
            tooltip: 'Campaigns',
            icon: const Icon(Icons.campaign_outlined),
            onPressed: () => context.push('/campaigns')),
        IconButton(
            tooltip: 'Contacts',
            icon: const Icon(Icons.people_outline),
            onPressed: () => context.push('/contacts')),
        IconButton(
            tooltip: 'WhatsApp Inbox',
            icon: const Icon(Icons.forum_outlined),
            onPressed: () => context.push('/inbox')),
        IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardMetricsProvider)),
        IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout()),
      ]),
      body: SafeArea(
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
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    const NotiqSectionHeader(title: 'Communication overview'),
                    const SizedBox(height: 16),
                    ...[
                      ('Total messages', m.total, Icons.mail_outline),
                      ('Sent', m.sent, Icons.send_outlined),
                      ('Pending', m.pending, Icons.schedule_outlined),
                      ('Scheduled', m.scheduled, Icons.event_outlined),
                      ('Failed', m.failed, Icons.error_outline),
                      ('Retriable failures', m.retriableFailed, Icons.replay_outlined),
                    ].map((entry) => NotiqMetricCard(
                          label: entry.$1,
                          value: '${entry.$2}',
                          icon: entry.$3,
                        )),
                  ]),
                )),
      ),
    );
  }
}
