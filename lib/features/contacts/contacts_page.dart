import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'contact_models.dart';
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
  int? selectedGroupId;
  bool searchOpen = false;
  int page = 1;
  final scrollController = ScrollController();
  final List<ContactItem> extraContacts = [];
  bool loadingMore = false;
  bool loadMoreFailed = false;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.hasClients &&
          scrollController.position.extentAfter < 320) {
        _loadMore();
      }
    });
  }

  void resetList() {
    generation++;
    page = 1;
    extraContacts.clear();
    loadMoreFailed = false;
  }

  Future<void> _loadMore() async {
    if (!mounted || loadingMore) return;
    final first = ref.read(
      contactListProvider((page: 1, search: filter, groupId: selectedGroupId)),
    ).valueOrNull;
    if (first == null || page >= first.totalPages) return;
    final nextPage = page + 1;
    final searchAtStart = filter;
    final groupAtStart = selectedGroupId;
    final requestGeneration = generation;
    setState(() {
      loadingMore = true;
      loadMoreFailed = false;
    });
    try {
      final next = await ref.read(contactRepositoryProvider).list(
        page: nextPage, search: searchAtStart, groupId: groupAtStart,
      );
      if (!mounted || generation != requestGeneration ||
          filter != searchAtStart || selectedGroupId != groupAtStart) {
        return;
      }
      setState(() {
        page = nextPage;
        final knownIds = {
          ...first.items.map((item) => item.id),
          ...extraContacts.map((item) => item.id),
        };
        extraContacts.addAll(
          next.items.where((item) => knownIds.add(item.id)),
        );
      });
    } catch (_) {
      if (mounted && generation == requestGeneration &&
          filter == searchAtStart && selectedGroupId == groupAtStart) {
        setState(() => loadMoreFailed = true);
      }
    } finally {
      if (mounted) setState(() => loadingMore = false);
    }
  }

  @override
  void dispose() {
    scrollController.dispose();
    search.dispose();
    super.dispose();
  }

  void reload() {
    setState(resetList);
    ref.invalidate(contactListProvider((page: 1, search: filter, groupId: selectedGroupId)));
  }
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

  Future<void> _chooseGroup() async {
    final groups = await ref.read(contactGroupsProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Filter by group')),
            ListTile(
              title: const Text('All contacts'),
              trailing: selectedGroupId == null ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(sheetContext, -1)),
            for (final group in groups)
              ListTile(
                title: Text((group['name'] ?? 'Group').toString()),
                trailing: selectedGroupId == (group['id'] as num?)?.toInt()
                    ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(
                  sheetContext, (group['id'] as num).toInt())),
          ],
        ),
      ),
    );
    if (!mounted || selected == null) return;
    setState(() {
      selectedGroupId = selected == -1 ? null : selected;
      resetList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactListProvider((page: 1, search: filter, groupId: selectedGroupId)));
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
                  resetList();
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
                      resetList();
                      searchOpen = false;
                    }),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              ActionChip(
                label: const Text('All'),
                onPressed: () => setState(() {
                  selectedGroupId = null;
                  resetList();
                }),
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.groups_outlined, size: 16),
                label: Text(selectedGroupId == null ? 'Groups' : 'Group selected'),
                onPressed: _chooseGroup,
              ),
              const SizedBox(width: 8),
              ActionChip(
                avatar: const Icon(Icons.label_outline_rounded, size: 16),
                label: const Text('Labels'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(
                      'Label filtering needs backend support. Manage labels from the menu.')));
                },
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
                    contactListProvider((page: 1, search: filter, groupId: selectedGroupId)).future,
                  );
                },
                child: ListView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    for (final contact in [...data.items, ...extraContacts])
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
                    if (page < data.totalPages)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                        child: Center(
                          child: loadMoreFailed
                              ? TextButton(
                                  onPressed: _loadMore,
                                  child: const Text('Retry loading contacts'),
                                )
                              : loadingMore
                                  ? const CircularProgressIndicator()
                                  : TextButton(
                                      onPressed: _loadMore,
                                      child: const Text('Load more contacts'),
                                    ),
                        ),
                      )
                    else
                      const SizedBox(height: 110),
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.id == null ? 'Add contact' : 'Edit contact'),
      ),
      body: detail?.isLoading == true
          ? const Center(child: CircularProgressIndicator())
          : detail?.hasError == true
              ? const Center(child: Text('Unable to load contact'))
              : SafeArea(
                  top: false,
                  child: Column(children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                        children: [
                          Text('Basic details', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 14),
                          TextField(
                            controller: name,
                            textCapitalization: TextCapitalization.words,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Full name',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: mobile,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Mobile number',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: whatsapp,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp number',
                              prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: email,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email (optional)',
                              prefixIcon: Icon(Icons.mail_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text('Organize', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: Text('Groups',
                              style: theme.textTheme.titleSmall)),
                            TextButton(
                              onPressed: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(builder: (_) =>
                                    const ContactOrganizePage(type: 'groups')),
                                );
                                ref.invalidate(contactGroupsProvider);
                              },
                              child: const Text('Manage'),
                            ),
                          ]),
                          _MultiContactLookup(
                            title: 'Groups',
                            selected: selectedGroups,
                            provider: contactGroupsProvider,
                            onChange: (values) => setState(() => selectedGroups = values),
                          ),
                          const SizedBox(height: 10),
                          Row(children: [
                            Expanded(child: Text('Labels',
                              style: theme.textTheme.titleSmall)),
                            TextButton(
                              onPressed: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute(builder: (_) =>
                                    const ContactOrganizePage(type: 'tags')),
                                );
                                ref.invalidate(contactTagsProvider);
                              },
                              child: const Text('Manage'),
                            ),
                          ]),
                          _MultiContactLookup(
                            title: 'Labels',
                            selected: selectedTags,
                            provider: contactTagsProvider,
                            onChange: (values) => setState(() => selectedTags = values),
                          ),
                          const SizedBox(height: 24),
                          Text('Communication consent', style: theme.textTheme.titleMedium),
                          const SizedBox(height: 5),
                          Text(
                            'Enable only for channels with verified permission.',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 10),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Column(children: [
                              SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: const Text('WhatsApp'),
                                secondary: const Icon(Icons.chat_outlined),
                                value: whatsApp,
                                onChanged: saving ? null : (v) => setState(() => whatsApp = v),
                              ),
                              const Divider(height: 1, indent: 56),
                              SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: const Text('SMS'),
                                secondary: const Icon(Icons.sms_outlined),
                                value: sms,
                                onChanged: saving ? null : (v) => setState(() => sms = v),
                              ),
                              const Divider(height: 1, indent: 56),
                              SwitchListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                title: const Text('Email'),
                                secondary: const Icon(Icons.email_outlined),
                                value: emailAllowed,
                                onChanged: saving ? null : (v) => setState(() => emailAllowed = v),
                              ),
                            ]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        border: Border(top: BorderSide(color: theme.dividerColor)),
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        if (error != null) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(error!, style: TextStyle(
                              color: theme.colorScheme.error)),
                          ),
                          const SizedBox(height: 8),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
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
                                    'isActive': widget.id == null
                                        ? true
                                        : detail?.valueOrNull?.active ?? true,
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
                        
                            child: Text(saving ? 'Saving…' : 'Save contact'),
                          ),
                        ),
                      ]),
                    ),
                  ]),
                ),
    );
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
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Icon(title == 'Groups' ? Icons.groups_outlined : Icons.label_outline,
                size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(child: Text('No ${title.toLowerCase()} yet',
                style: Theme.of(context).textTheme.bodySmall)),
            ]),
          )
        : Wrap(spacing: 8, runSpacing: 2,
            children: items.map((item) {
              final id = (item['id'] as num).toInt();
              final isLabel = title == 'Labels';
              const palette = [
                Color(0xFF7C6CFF), Color(0xFF16A695),
                Color(0xFFE1A33F), Color(0xFFDB718C),
                Color(0xFF5B9AE5), Color(0xFF9C77C9),
              ];
              final color = palette[id.abs() % palette.length];
              return FilterChip(
                avatar: isLabel ? Icon(Icons.circle, size: 11, color: color) : null,
                label: Text((item['name'] ?? '').toString()),
                selected: selected.contains(id),
                selectedColor: isLabel ? color.withValues(alpha: 0.20) : null,

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
