import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/notiq_pagination.dart';
import 'contact_repository.dart';
import 'contact_organize_page.dart';

class ContactsPage extends ConsumerStatefulWidget {
  const ContactsPage({super.key});
  @override
  ConsumerState<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends ConsumerState<ContactsPage> {
  final search = TextEditingController();
  String filter = '';
  bool searchOpen = false;
  int page = 1;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void reload() =>
      ref.invalidate(contactListProvider((page: page, search: filter)));
  Future<void> openCreate() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const ContactEditorPage()),
    );
    if (mounted) reload();
  }

  Future<void> openOrganizer(String type) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => ContactOrganizePage(type: type)),
    );
    if (mounted) {
      ref.invalidate(contactGroupsProvider);
      ref.invalidate(contactTagsProvider);
      reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactListProvider((page: page, search: filter)));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Contact actions',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              if (value == 'groups' || value == 'tags') {
                await openOrganizer(value);
              } else if (value == 'import') {
                await Navigator.push<void>(
                  context,
                  MaterialPageRoute(builder: (_) => const ContactImportPage()),
                );
                if (mounted) reload();
              } else if (value == 'refresh') {
                reload();
              } else if (value == 'create') {
                await openCreate();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'create', child: Text('Add contact')),
              PopupMenuItem(value: 'groups', child: Text('Create / manage groups')),
              PopupMenuItem(value: 'tags', child: Text('Create / manage labels')),
              PopupMenuItem(value: 'import', child: Text('Import contacts')),
              PopupMenuDivider(),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!searchOpen)
            FloatingActionButton.small(
              heroTag: 'contact-search',
              tooltip: 'Search contacts',
              onPressed: () => setState(() => searchOpen = true),
              child: const Icon(Icons.search_rounded),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'contact-create',
            tooltip: 'Add contact',
            onPressed: openCreate,
            child: const Icon(Icons.person_add_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(children: [
          if (searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: search,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onSubmitted: (value) => setState(() {
                  filter = value.trim();
                  page = 1;
                }),
                decoration: InputDecoration(
                  hintText: 'Search contacts',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Close search',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() {
                      search.clear();
                      filter = '';
                      page = 1;
                      searchOpen = false;
                    }),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              const Chip(label: Text('All contacts')),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.groups_outlined, size: 16),
                label: const Text('Groups'),
                onPressed: () => openOrganizer('groups'),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.label_outline_rounded, size: 16),
                label: const Text('Labels'),
                onPressed: () => openOrganizer('tags'),
              ),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: contacts.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: FilledButton(onPressed: reload, child: const Text('Retry')),
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () async {
                  reload();
                  await ref.read(
                    contactListProvider((page: page, search: filter)).future,
                  );
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    for (final contact in data.items)
                      Column(children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: colors.primaryContainer,
                            child: Text(
                              contact.name.isEmpty
                                  ? (contact.mobile.isEmpty ? '?' : contact.mobile[0])
                                  : contact.name[0].toUpperCase(),
                              style: TextStyle(color: colors.onPrimaryContainer,
                                fontWeight: FontWeight.w600),
                            ),
                          ),
                          title: Text(
                            contact.name.isEmpty ? contact.mobile : contact.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            contact.mobile.isNotEmpty
                                ? contact.mobile
                                : contact.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: contact.active
                              ? const Icon(Icons.chevron_right_rounded)
                              : Icon(Icons.pause_circle_outline_rounded,
                                  color: colors.error),
                          onTap: () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContactEditorPage(id: contact.id),
                              ),
                            );
                            if (mounted) reload();
                          },
                        ),
                        const Divider(height: 1, indent: 72),
                      ]),
                    if (data.items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(36),
                        child: Center(child: Text('No contacts found')),
                      ),
                    NotiqPagination(
                      page: page,
                      totalPages: data.totalPages,
                      onPageChanged: (next) => setState(() => page = next),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class ContactEditorPage extends ConsumerStatefulWidget {
  const ContactEditorPage({super.key, this.id});
  final int? id;
  @override
  ConsumerState<ContactEditorPage> createState() => _ContactEditorPageState();
}

class _ContactEditorPageState extends ConsumerState<ContactEditorPage> {
  final name = TextEditingController(),
      mobile = TextEditingController(),
      whatsapp = TextEditingController(),
      email = TextEditingController();
  bool sms = false,
      whatsApp = false,
      emailAllowed = false,
      saving = false,
      loaded = false;
  String? error;
  List<int> selectedGroups = [];
  List<int> selectedTags = [];
  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    whatsapp.dispose();
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detail =
        widget.id == null ? null : ref.watch(contactDetailProvider(widget.id!));
    if (detail?.hasValue == true && !loaded) {
      final contact = detail!.value!;
      name.text = contact.name;
      mobile.text = contact.mobile;
      whatsapp.text = contact.whatsapp;
      email.text = contact.email;
      sms = contact.smsAllowed;
      whatsApp = contact.whatsappAllowed;
      emailAllowed = contact.emailAllowed;
      selectedGroups = [...contact.groupIds];
      selectedTags = [...contact.tagIds];
      loaded = true;
    }
    return Scaffold(
        appBar: AppBar(
            title: Text(widget.id == null ? 'Add contact' : 'Edit contact')),
        body: detail?.isLoading == true
            ? const Center(child: CircularProgressIndicator())
            : detail?.hasError == true
                ? const Center(child: Text('Unable to load contact'))
                : ListView(padding: const EdgeInsets.all(16), children: [
                    Text('Contact information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 12),
                    TextField(
                        controller: name,
                        decoration: const InputDecoration(labelText: 'Name')),
                    TextField(
                        controller: mobile,
                        keyboardType: TextInputType.phone,
                        decoration:
                            const InputDecoration(labelText: 'Mobile number')),
                    TextField(
                        controller: whatsapp,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                            labelText: 'WhatsApp number')),
                    TextField(
                        controller: email,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(labelText: 'Email')),
                    const SizedBox(height: 24),
                    Text('Groups and tags', style: Theme.of(context).textTheme.titleLarge),
                    _MultiContactLookup(title: 'Groups', selected: selectedGroups,
                      provider: contactGroupsProvider,
                      onChange: (values) => setState(() => selectedGroups = values)),
                    _MultiContactLookup(title: 'Tags', selected: selectedTags,
                      provider: contactTagsProvider,
                      onChange: (values) => setState(() => selectedTags = values)),
                    const SizedBox(height: 24),
                    Text('Communication consent', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('Enable a channel only when the contact has given consent.',
                      style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 12),
                    SwitchListTile(
                        title: const Text('WhatsApp consent'),
                        value: whatsApp,
                        onChanged: (v) => setState(() => whatsApp = v)),
                    SwitchListTile(
                        title: const Text('SMS consent'),
                        value: sms,
                        onChanged: (v) => setState(() => sms = v)),
                    SwitchListTile(
                        title: const Text('Email consent'),
                        value: emailAllowed,
                        onChanged: (v) => setState(() => emailAllowed = v)),
                    if (error != null)
                      Text(error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    FilledButton(
                        onPressed: saving
                            ? null
                            : () async {
                                if (name.text.trim().isEmpty ||
                                    mobile.text.trim().isEmpty) {
                                  setState(() => error =
                                      'Name and mobile number are required');
                                  return;
                                }
                                setState(() {
                                  saving = true;
                                  error = null;
                                });
                                try {
                                  await ref
                                      .read(contactRepositoryProvider)
                                      .save({
                                    'name': name.text.trim(),
                                    'mobileNumber': mobile.text.trim(),
                                    'whatsAppNumber': whatsapp.text.trim(),
                                    'email': email.text.trim(),
                                    'isSmsAllowed': sms,
                                    'isWhatsAppAllowed': whatsApp,
                                    'isEmailAllowed': emailAllowed,
                                    'isActive': true,
                                    'tagIds': selectedTags,
                                    'groupIds': selectedGroups,
                                  }, id: widget.id);
                                  if (context.mounted) Navigator.pop(context);
                                } catch (e) {
                                  if (mounted) {
                                    setState(() => error = e.toString());
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => saving = false);
                                  }
                                }
                              },
                        child: Text(saving ? 'Saving…' : 'Save contact')),
                  ]));
  }
}

class _MultiContactLookup extends ConsumerWidget {
  const _MultiContactLookup({
    required this.title, required this.selected,
    required this.provider, required this.onChange,
  });
  final String title;
  final List<int> selected;
  final AutoDisposeFutureProvider<List<Map<String,dynamic>>> provider;
  final ValueChanged<List<int>> onChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(provider);
    return result.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => TextButton(
        onPressed: () => ref.invalidate(provider),
        child: Text('Retry loading $title')),
      data: (items) => items.isEmpty
        ? Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('No $title available'))
        : Wrap(spacing: 8, runSpacing: 2,
            children: items.map((item) {
              final id = (item['id'] as num).toInt();
              return FilterChip(
                label: Text((item['name'] ?? '').toString()),
                selected: selected.contains(id),
                onSelected: (checked) {
                  final next = {...selected};
                  if (checked) { next.add(id); } else { next.remove(id); }
                  onChange(next.toList());
                },
              );
            }).toList()),
    );
  }
}
