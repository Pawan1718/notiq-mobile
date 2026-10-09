import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'workspace_read_repository.dart';

String _role(Object? value) => switch (value?.toString()) {
  '1' => 'Owner', '2' => 'Admin', '3' => 'Agent', _ => 'Unknown role',
};

class TeamReadPage extends ConsumerWidget {
  const TeamReadPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceTeamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Team members')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(workspaceTeamProvider),
          child: const Text('Unable to load team. Retry'),
        )),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('View-only · Team access is managed on Notiq Web.'),
            const SizedBox(height: 12),
            if (items.isEmpty) const ListTile(title: Text('No team members found')),
            for (final user in items)
              Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                  title: Text((user['name'] ?? 'Team member').toString()),
                  subtitle: Text((user['email'] ?? '').toString()),
                  trailing: Column(mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_role(user['role'])),
                      Text(user['isActive'] == true ? 'Active' : 'Inactive',
                        style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RolesReadPage extends StatelessWidget {
  const RolesReadPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Roles & permissions')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Workspace roles are managed on Notiq Web.'),
        SizedBox(height: 12),
        ListTile(leading: Icon(Icons.shield_outlined),
          title: Text('Owner'), subtitle: Text('Workspace owner role')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.admin_panel_settings_outlined),
          title: Text('Admin'), subtitle: Text('Workspace administrator role')),
        Divider(height: 1),
        ListTile(leading: Icon(Icons.support_agent_outlined),
          title: Text('Agent'), subtitle: Text('Workspace agent role')),
        SizedBox(height: 12),
        Text('This is a role directory, not an entitlement or permission matrix.'),
      ],
    ),
  );
}

class SubscriptionReadPage extends ConsumerWidget {
  const SubscriptionReadPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceSubscriptionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Plan & billing')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(workspaceSubscriptionProvider),
          child: const Text('Unable to load subscription. Retry'),
        )),
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text((item['planName'] ?? 'Current plan').toString(),
              style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(title: const Text('Plan code'),
              subtitle: Text((item['planCode'] ?? '—').toString())),
            ListTile(title: const Text('Subscription ID'),
              subtitle: Text((item['subscriptionId'] ?? '—').toString())),
            ListTile(title: const Text('Status code'),
              subtitle: Text((item['status'] ?? '—').toString())),
            if (item['endsAt'] != null)
              ListTile(title: const Text('Ends at'),
                subtitle: Text(item['endsAt'].toString())),
            const SizedBox(height: 12),
            const Text('Read only · Billing changes are managed on Notiq Web.'),
          ],
        ),
      ),
    );
  }
}

class UsageReadPage extends ConsumerWidget {
  const UsageReadPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(workspaceCostProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Usage & costs')),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(workspaceCostProvider),
          child: const Text('Unable to load usage. Retry'),
        )),
        data: (item) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Communication costs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${item['currency'] ?? ''} ${item['totalCost'] ?? '0'}',
                  style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text('Total messages: ${item['totalMessages'] ?? 0}'),
                Text('Sent: ${item['sentMessages'] ?? 0}'),
                Text('Failed: ${item['failedMessages'] ?? 0}'),
              ]),
            )),
            const SizedBox(height: 12),
            Text('By channel', style: Theme.of(context).textTheme.titleMedium),
            for (final entry in (item['byChannel'] as List<dynamic>? ?? const []))
              if (entry is Map)
                ListTile(
                  title: Text('Channel ${entry['channel'] ?? '—'}'),
                  subtitle: Text('${entry['sentMessages'] ?? 0} sent'),
                  trailing: Text('${item['currency'] ?? ''} ${entry['totalCost'] ?? '0'}'),
                ),
            const SizedBox(height: 12),
            const Text('Values are reported by the server.'),
          ],
        ),
      ),
    );
  }
}
