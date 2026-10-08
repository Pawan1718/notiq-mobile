import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/theme/notiq_brand.dart';
import '../../core/widgets/notiq_metric_card.dart';
import '../../core/widgets/notiq_page_state.dart';
import 'dashboard_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const NotiqBrand(compact: true),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh),
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
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: metrics.when(
          loading: () => const NotiqPageState.loading(),
          error: (_, __) => NotiqPageState.error(
            title: 'Dashboard could not be loaded',
            onRetry: () => ref.invalidate(dashboardMetricsProvider),
          ),
          data: (m) {
            final items = [
              ('Total messages', m.total, Icons.mail_outline),
              ('Sent', m.sent, Icons.send_outlined),
              ('Scheduled', m.scheduled, Icons.event_outlined),
              ('Failed', m.failed, Icons.error_outline),
              ('Pending', m.pending, Icons.schedule_outlined),
              ('Retriable failures', m.retriableFailed, Icons.replay_outlined),
            ];
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardMetricsProvider);
                await ref.read(dashboardMetricsProvider.future);
              },
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 700 ? 3 : 2;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      mainAxisExtent: 112,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return NotiqMetricCard(
                        label: item.$1,
                        value: '${item.$2}',
                        icon: item.$3,
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
