import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/app_scaffold.dart';
import 'dashboard_repository.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metrics = ref.watch(dashboardMetricsProvider);
    return AppScaffold(
      title: 'Dashboard', actions: [



        IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardMetricsProvider)),

      ],
      child: SafeArea(
        child: metrics.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Dashboard could not be loaded.'),
                    const SizedBox(height: 12),
                    FilledButton(
                        onPressed: () =>
                            ref.invalidate(dashboardMetricsProvider),
                        child: const Text('Retry')),
                  ]),
                )),
            data: (m) => RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(dashboardMetricsProvider);
                    await ref.read(dashboardMetricsProvider.future);
                  },
                  child: ListView(padding: const EdgeInsets.all(16), children: [
                    Text('Communication overview',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    ...[
                      ('Total messages', m.total),
                      ('Sent', m.sent),
                      ('Pending', m.pending),
                      ('Scheduled', m.scheduled),
                      ('Failed', m.failed),
                      ('Retriable failures', m.retriableFailed),
                    ].map((entry) => Card(
                            child: ListTile(
                          title: Text(entry.$1),
                          trailing: Text('${entry.$2}',
                              style: Theme.of(context).textTheme.titleLarge),
                        ))),
                  ]),
                )),
      ),
    );
  }
}
