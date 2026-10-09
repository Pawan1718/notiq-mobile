import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contact_repository.dart';

class ContactOrganizePage extends ConsumerWidget {
  const ContactOrganizePage({super.key, required this.type});
  final String type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isGroup = type == 'groups';
    final provider = isGroup ? contactGroupsProvider : contactTagsProvider;
    final items = ref.watch(provider);
    return Scaffold(
      appBar: AppBar(title: Text(isGroup ? 'Contact groups' : 'Contact tags')),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: FilledButton(
          onPressed: () => ref.invalidate(provider), child: const Text('Retry'))),
        data: (values) => ListView(children: [
          for (final item in values)
            ListTile(
              leading: isGroup
                  ? const Icon(Icons.group_outlined)
                  : Icon(Icons.label_rounded, color: const [
                      Color(0xFF7C6CFF), Color(0xFF16A695),
                      Color(0xFFE1A33F), Color(0xFFDB718C),
                      Color(0xFF5B9AE5), Color(0xFF9C77C9),
                    ][((item['id'] as num?)?.toInt() ?? 0).abs() % 6]),
              title: Text((item['name'] ?? '').toString()),
              subtitle: isGroup ? Text('${item['memberCount'] ?? 0} members') : null,
            ),
          if (values.isEmpty) const ListTile(title: Text('Nothing created yet')),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final name = TextEditingController();
          final description = TextEditingController();
          try {
            final accepted = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(isGroup ? 'New group' : 'New tag'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
                  if (isGroup) TextField(controller: description,
                    decoration: const InputDecoration(labelText: 'Description')),
                ]),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text('Create')),
                ],
              ),
            );
            if (accepted != true || name.text.trim().isEmpty) return;
            await ref.read(contactRepositoryProvider).createLookup(type, {
              'name': name.text.trim(),
              if (isGroup) 'description': description.text.trim(),
            });
            ref.invalidate(provider);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to create. Please retry.')));
            }
          } finally {
            name.dispose();
            description.dispose();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(isGroup ? 'New group' : 'New tag'),
      ),
    );
  }
}

class ContactImportPage extends ConsumerStatefulWidget {
  const ContactImportPage({super.key});
  @override
  ConsumerState<ContactImportPage> createState() => _ContactImportPageState();
}

class _ContactImportPageState extends ConsumerState<ContactImportPage> {
  final raw = TextEditingController();
  bool busy = false;
  bool sms = false;
  bool whatsApp = false;
  Map<String,dynamic>? preview;
  String? error;

  @override
  void dispose() { raw.dispose(); super.dispose(); }

  Map<String,dynamic> get payload => {
    'rawText': raw.text,
    'groupIds': <int>[],
    'enableSms': sms,
    'enableWhatsApp': whatsApp,
    'consentMode': 'Unknown',
  };

  Future<void> run({required bool confirm}) async {
    if (busy || raw.text.trim().isEmpty) return;
    setState(() { busy = true; error = null; });
    try {
      final data = await ref.read(contactRepositoryProvider).importContacts(payload, confirm: confirm);
      if (!mounted) return;
      setState(() => preview = data);
      if (confirm) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${data['importedCount'] ?? 0} contacts')));
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Import failed. Check input and retry.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Import contacts')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      Text('Paste phone numbers', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8),
      const Text('Enter one phone number per line. Preview before importing.'),
      const SizedBox(height: 12),
      TextField(controller: raw, minLines: 5, maxLines: 12,
        onChanged: (_) => setState(() => preview = null),
        decoration: const InputDecoration(hintText: '+15551234567')),
      SwitchListTile(title: const Text('SMS consent'),
        subtitle: const Text('Keep off unless consent is verified'),
        value: sms, onChanged: (v) => setState(() { sms = v; preview = null; })),
      SwitchListTile(title: const Text('WhatsApp consent'),
        subtitle: const Text('Keep off unless consent is verified'),
        value: whatsApp, onChanged: (v) => setState(() { whatsApp = v; preview = null; })),
      if (error != null) Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
      if (preview != null) Card(child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Import preview', style: Theme.of(context).textTheme.titleMedium),
          Text('Valid: ${preview!['validCount'] ?? 0}'),
          Text('Duplicates: ${preview!['duplicateInPasteCount'] ?? 0}'),
          Text('Already exists: ${preview!['alreadyExistsCount'] ?? 0}'),
          Text('Will import: ${preview!['willImportCount'] ?? 0}'),
        ]),
      )),
      const SizedBox(height: 12),
      FilledButton.tonal(onPressed: busy ? null : () => run(confirm: false),
        child: Text(busy ? 'Please wait...' : 'Preview import')),
      if (preview != null)
        FilledButton(
          onPressed: busy || (preview!['willImportCount'] as num? ?? 0) <= 0 ? null : () async {
            final accepted = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Confirm import?'),
                content: Text('Import ${preview!['willImportCount']} contacts?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Import')),
                ],
              ),
            );
            if (accepted == true) await run(confirm: true);
          },
          child: const Text('Confirm import'),
        ),
    ]),
  );
}
