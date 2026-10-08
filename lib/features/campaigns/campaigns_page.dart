import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'campaign_repository.dart';
import 'campaign_draft_page.dart';
import '../../core/navigation/app_scaffold.dart';

class CampaignsPage extends ConsumerStatefulWidget {
  const CampaignsPage({super.key});
  @override
  ConsumerState<CampaignsPage> createState() => _CampaignsPageState();
}

class _CampaignsPageState extends ConsumerState<CampaignsPage> {
  final search = TextEditingController();
  String query = '';
  int page = 1;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void refresh() =>
      ref.invalidate(campaignsProvider((page: page, search: query)));
  @override
  Widget build(BuildContext context) {
    final result = ref.watch(campaignsProvider((page: page, search: query)));
    return AppScaffold(
      title: 'Campaigns', actions: [
        IconButton(
            tooltip: 'Create draft',
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                      builder: (_) => const CampaignDraftPage()));
              refresh();
            }),
        IconButton(
            tooltip: 'Refresh',
            onPressed: refresh,
            icon: const Icon(Icons.refresh)),
      ],
      child: Column(children: [
        Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
                controller: search,
                decoration: const InputDecoration(
                    labelText: 'Search campaigns',
                    prefixIcon: Icon(Icons.search)),
                onSubmitted: (v) => setState(() {
                      query = v;
                      page = 1;
                    }))),
        Expanded(
            child: result.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: TextButton(
                        onPressed: refresh, child: Text('Retry: $e'))),
                data: (data) => ListView(children: [
                      for (final item in data.items)
                        ListTile(
                          leading: const Icon(Icons.campaign_outlined),
                          title: Text(item.name),
                          subtitle: Text(
                              '${item.status} · ${item.sent}/${item.total} sent · ${item.failed} failed'),
                          onTap: () async {
                            await Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                    builder: (_) =>
                                        CampaignDetailPage(id: item.id)));
                            refresh();
                          },
                        ),
                      if (data.items.isEmpty)
                        const ListTile(title: Text('No campaigns found')),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                                onPressed: page > 1
                                    ? () => setState(() => page--)
                                    : null,
                                icon: const Icon(Icons.chevron_left)),
                            Text('Page $page of ${data.totalPages}'),
                            IconButton(
                                onPressed: page < data.totalPages
                                    ? () => setState(() => page++)
                                    : null,
                                icon: const Icon(Icons.chevron_right)),
                          ]),
                    ]))),
      ]),
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
            Text('Status: ${item.status}'),
            for (final key in [
              'totalRecipients',
              'queuedCount',
              'sentCount',
              'failedCount',
              'deliveredCount',
              'readCount'
            ])
              ListTile(
                  title: Text(key), trailing: Text('${number(item.raw[key])}')),
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
                padding: const EdgeInsets.all(16),
                child: Text(
                    'Total: ${number(data.summary['total'])} · Delivered: ${number(data.summary['delivered'])} · Failed: ${number(data.summary['failed'])}')),
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
