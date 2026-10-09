import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/notiq_pagination.dart';
import 'campaign_repository.dart';
import 'campaign_draft_page.dart';

class CampaignsPage extends ConsumerStatefulWidget {
  const CampaignsPage({super.key});

  @override
  ConsumerState<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends ConsumerState<CampaignsPage> {
  final search = TextEditingController();
  String query = '';
  bool searchOpen = false;
  String statusView = 'All';
  int page = 1;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void refresh() =>
      ref.invalidate(campaignsProvider((page: page, search: query)));

  Future<void> createDraft() async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const CampaignDraftPage()),
    );
    if (mounted) refresh();
  }

  Future<void> openCampaign(CampaignItem item) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => CampaignDetailPage(id: item.id)),
    );
    if (mounted) refresh();
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(campaignsProvider((page: page, search: query)));
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaigns'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Campaign actions',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (action) {
              if (action == 'refresh') refresh();
              if (action == 'create') createDraft();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'create', child: Text('Create campaign')),
              PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            ],
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!searchOpen) FloatingActionButton.small(
              heroTag: 'campaign-search',
              tooltip: 'Search campaigns',
              onPressed: () => setState(() => searchOpen = true),
              child: const Icon(Icons.search_rounded),
            ),
            const SizedBox(height: 10),
            FloatingActionButton(
              heroTag: 'campaign-create',
              tooltip: 'Create campaign',
              onPressed: createDraft,
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (searchOpen)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: TextField(
                  controller: search,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (value) => setState(() {
                    query = value.trim();
                    page = 1;
                  }),
                  decoration: InputDecoration(
                    hintText: 'Search campaigns',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: IconButton(
                      tooltip: 'Close search',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(() {
                        search.clear();
                        query = '';
                        page = 1;
                        searchOpen = false;
                      }),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  for (final label in const ['All', 'Drafts', 'Scheduled', 'Completed']) ...[
                    ChoiceChip(
                      label: Text(label),
                      selected: statusView == label,
                      onSelected: (_) => setState(() => statusView = label),
                    ),
                    const SizedBox(width: 8),
                  ],
                ]),
              ),
            ),
            Expanded(
              child: result.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Campaigns could not be loaded'),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  ]),
                ),
                data: (data) {
                  final shown = data.items.where((item) {
                    final status = item.status.toLowerCase();
                    return switch (statusView) {
                      'Drafts' => status.contains('draft'),
                      'Scheduled' => status.contains('schedul'),
                      'Completed' => status.contains('complete') || status.contains('sent') || status.contains('deliver'),
                      _ => true,
                    };
                  }).toList();
                  return RefreshIndicator(
                  onRefresh: () async {
                    refresh();
                    await ref.read(campaignsProvider((page: page, search: query)).future);
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 2, 16, 22),
                    children: [
                      if (statusView != 'All')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text('Filter applies to this page only',
                            style: theme.textTheme.bodySmall),
                        ),
                      if (shown.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 72),
                          child: Column(children: [
                            Icon(Icons.campaign_outlined, size: 48,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(height: 12),
                            Text(query.isEmpty && statusView == 'All' ? 'No campaigns yet' : 'No matching campaigns',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(query.isEmpty && statusView == 'All'
                                ? 'Create a draft to get started.'
                                : 'Try another filter or search.',
                                style: theme.textTheme.bodySmall),
                          ]),
                        ),
                      for (final item in shown) ...[
                        _CampaignCard(item: item, onTap: () => openCampaign(item)),
                        const SizedBox(height: 10),
                      ],
                      if (data.totalPages > 1)
                        NotiqPagination(
                          page: page,
                          totalPages: data.totalPages,
                          onPageChanged: (next) => setState(() => page = next),
                        ),
                    ],
                  ),
                );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.item, required this.onTap});
  final CampaignItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final status = item.status;
    final lower = status.toLowerCase();
    final danger = lower.contains('fail') || lower.contains('cancel');
    final positive = lower.contains('deliver') || lower.contains('sent') ||
        lower.contains('complete');
    final statusColor = danger ? colors.error
        : positive ? const Color(0xFF087F61)
        : colors.primary;
    final progress = item.total > 0
        ? (item.sent / item.total).clamp(0.0, 1.0) : 0.0;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.campaign_outlined,
                      color: colors.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(item.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, size: 20),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: .10),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(status, style: TextStyle(
                    color: statusColor, fontSize: 12, fontWeight: FontWeight.w700,
                  )),
                ),
                const Spacer(),
                Text('${item.total} recipients', style: theme.textTheme.bodySmall),
              ]),
              const SizedBox(height: 14),
              LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                borderRadius: BorderRadius.circular(8),
                backgroundColor: colors.surfaceContainerHighest,
              ),
              const SizedBox(height: 9),
              Row(children: [
                Icon(Icons.send_outlined, size: 14,
                    color: colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${item.sent} sent', style: theme.textTheme.bodySmall),
                const Spacer(),
                Icon(Icons.error_outline_rounded, size: 14,
                    color: item.failed > 0 ? colors.error : colors.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('${item.failed} failed', style: theme.textTheme.bodySmall),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class CampaignDetailPage extends ConsumerStatefulWidget {
  const CampaignDetailPage({super.key, required this.id});
  final int id;
  @override
  ConsumerState<CampaignDetailPage> createState() => _CampaignDetailPageState();
}

class _CampaignDetailPageState extends ConsumerState<CampaignDetailPage> {
  bool busy = false;
  String? error;
  Future<bool> confirm(String title) async =>
      await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                  title: Text(title),
                  content: const Text(
                      'This action changes the campaign on the server.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Back')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Confirm')),
                  ])) ??
      false;
  Future<void> runAction(String title, String suffix,
      {Map<String, dynamic>? body}) async {
    if (busy || !await confirm(title)) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref
          .read(campaignRepositoryProvider)
          .action(widget.id, suffix, body: body);
      ref.invalidate(campaignDetailProvider(widget.id));
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> reschedule() async {
    final selected = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (selected == null || !mounted) return;
    final time =
        await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null || !mounted) return;
    final local = DateTime(
        selected.year, selected.month, selected.day, time.hour, time.minute);
    if (!local.isAfter(DateTime.now())) {
      setState(() => error = 'Choose a future date and time');
      return;
    }
    await runAction('Reschedule campaign', 'reschedule',
        body: {'scheduledAtUtc': local.toUtc().toIso8601String()});
  }

  @override
  Widget build(BuildContext context) {
    final result = ref.watch(campaignDetailProvider(widget.id));
    return Scaffold(
        appBar: AppBar(title: const Text('Campaign details')),
        body: result.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: TextButton(
                  onPressed: () =>
                      ref.invalidate(campaignDetailProvider(widget.id)),
                  child: Text('Retry: $e'))),
          data: (item) =>
              ListView(padding: const EdgeInsets.all(16), children: [
            Text(item.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(label: Text(item.status)),
            ),
            const SizedBox(height: 20),
            Text('Delivery overview',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final metric in [
                  ('Recipients', 'totalRecipients'),
                  ('Queued', 'queuedCount'),
                  ('Sent', 'sentCount'),
                  ('Delivered', 'deliveredCount'),
                  ('Read', 'readCount'),
                  ('Failed', 'failedCount'),
                ])
                  SizedBox(
                    width: (MediaQuery.sizeOf(context).width - 42) / 2,
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${number(item.raw[metric.$2])}',
                                style: Theme.of(context).textTheme.headlineSmall),
                            const SizedBox(height: 5),
                            Text(metric.$1,
                                style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Manage campaign',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (error != null)
              Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            FilledButton.tonal(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                        builder: (_) => CampaignRecipientsPage(id: widget.id))),
                child: const Text('Recipient report')),
            if (item.canEditDraft)
              FilledButton.tonal(
                  onPressed: () async {
                    await Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                            builder: (_) => CampaignDraftPage(
                                id: item.id, existing: item)));
                    ref.invalidate(campaignDetailProvider(widget.id));
                  },
                  child: const Text('Edit draft')),
            if (item.canPublish)
              FilledButton(
                  onPressed: busy
                      ? null
                      : () => runAction('Publish draft', 'draft/publish'),
                  child: const Text('Publish draft')),
            if (item.canDeleteDraft)
              OutlinedButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!await confirm('Delete draft')) return;
                          setState(() => busy = true);
                          try {
                            await ref
                                .read(campaignRepositoryProvider)
                                .action(widget.id, 'draft', method: 'DELETE');
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (mounted) setState(() => error = '$e');
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: const Text('Delete draft')),
            if (item.canDuplicate)
              OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => runAction('Duplicate campaign', 'duplicate',
                          body: {}),
                  child: const Text('Duplicate')),
            if (item.canRetry)
              OutlinedButton(
                  onPressed: busy
                      ? null
                      : () =>
                          runAction('Retry failed recipients', 'retry-failed'),
                  child: const Text('Retry failed')),
            if (item.canReschedule)
              OutlinedButton(
                  onPressed: busy ? null : reschedule,
                  child: const Text('Reschedule')),
            if (item.canCancel)
              OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => runAction('Cancel campaign', 'cancel',
                          body: {'reason': 'Cancelled from Notiq mobile'}),
                  child: const Text('Cancel campaign')),
          ]),
        ));
  }
}

class CampaignRecipientsPage extends ConsumerStatefulWidget {
  const CampaignRecipientsPage({super.key, required this.id});
  final int id;
  @override
  ConsumerState<CampaignRecipientsPage> createState() =>
      _CampaignRecipientsPageState();
}

class _CampaignRecipientsPageState
    extends ConsumerState<CampaignRecipientsPage> {
  int page = 1;
  @override
  Widget build(BuildContext context) {
    final report =
        ref.watch(campaignRecipientsProvider((id: widget.id, page: page)));
    return Scaffold(
        appBar: AppBar(title: const Text('Recipient report')),
        body: report.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
              child: TextButton(
                  onPressed: () => ref.invalidate(
                      campaignRecipientsProvider((id: widget.id, page: page))),
                  child: Text('Retry: $e'))),
          data: (data) => ListView(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Text('Recipient delivery',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('Total ${number(data.summary['total'])}')),
                  Chip(label: Text('Delivered ${number(data.summary['delivered'])}')),
                  Chip(label: Text('Read ${number(data.summary['read'])}')),
                  Chip(label: Text('Failed ${number(data.summary['failed'])}')),
                ],
              ),
            ),
            const Divider(height: 24),
            for (final recipient in data.recipients)
              ListTile(
                  title: Text((recipient['recipientName'] ??
                          recipient['recipientAddress'] ??
                          '')
                      .toString()),
                  subtitle:
                      Text((recipient['recipientAddress'] ?? '').toString()),
                  trailing: Text('${recipient['status'] ?? '-'}')),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  onPressed: page > 1 ? () => setState(() => page--) : null,
                  icon: const Icon(Icons.chevron_left)),
              Text('Page $page of ${data.totalPages}'),
              IconButton(
                  onPressed: page < data.totalPages
                      ? () => setState(() => page++)
                      : null,
                  icon: const Icon(Icons.chevron_right)),
            ]),
          ]),
        ));
  }
}
