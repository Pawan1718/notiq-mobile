import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'readonly_catalog_repository.dart';

String _channel(Object? value) {
  return switch (value?.toString()) {
    '2' => 'Email',
    '3' => 'SMS',
    '4' => 'WhatsApp',
    _ => 'Channel',
  };
}

class ProviderCatalogPage extends ConsumerWidget {
  const ProviderCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(providerCatalogProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Providers'), actions: [
        IconButton(
          tooltip: 'Refresh providers',
          onPressed: () => ref.invalidate(providerCatalogProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ]),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(providerCatalogProvider),
          child: const Text('Unable to load providers. Retry'),
        )),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Managed on the web. Credentials are never shown here.',
              style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (items.isEmpty) const ListTile(title: Text('No providers configured')),
            for (final item in items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.settings_input_component_outlined),
                  title: Text((item['displayName'] ?? 'Provider').toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${_channel(item['channel'])} · '
                    '${item['isConfigured'] == true ? 'Configured' : 'Needs setup'}'),
                  trailing: Text(item['isEnabled'] == true ? 'Enabled' : 'Disabled',
                    style: theme.textTheme.labelSmall),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TemplateCatalogPage extends ConsumerWidget {
  const TemplateCatalogPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(templateCatalogProvider);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Templates'), actions: [
        IconButton(
          tooltip: 'Refresh templates',
          onPressed: () => ref.invalidate(templateCatalogProvider),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ]),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(templateCatalogProvider),
          child: const Text('Unable to load templates. Retry'),
        )),
        data: (items) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Read-only. Manage templates in Notiq Web.',
              style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (items.isEmpty) const ListTile(title: Text('No templates available')),
            for (final item in items)
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: Text((item['name'] ?? 'Template').toString(),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(
                    '${_channel(item['channel'])} · '
                    '${item['isActive'] == true ? 'Active' : 'Inactive'}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => SafeArea(
                      top: false,
                      child: FractionallySizedBox(
                        heightFactor: .65,
                        child: ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            Text((item['name'] ?? 'Template').toString(),
                              style: theme.textTheme.titleMedium),
                            const SizedBox(height: 12),
                            if ((item['subject'] ?? '').toString().isNotEmpty) ...[
                              Text('Subject', style: theme.textTheme.labelMedium),
                              Text(item['subject'].toString()),
                              const SizedBox(height: 16),
                            ],
                            Text('Message', style: theme.textTheme.labelMedium),
                            const SizedBox(height: 6),
                            SelectableText((item['body'] ?? '').toString()),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
