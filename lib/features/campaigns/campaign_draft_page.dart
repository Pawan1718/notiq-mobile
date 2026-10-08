import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'campaign_repository.dart';

class CampaignDraftPage extends ConsumerStatefulWidget {
  const CampaignDraftPage({super.key, this.id, this.existing});
  final int? id;
  final CampaignDetail? existing;
  @override
  ConsumerState<CampaignDraftPage> createState() => _CampaignDraftPageState();
}

class _CampaignDraftPageState extends ConsumerState<CampaignDraftPage> {
  late final name = TextEditingController(text: widget.existing?.name ?? '');
  late final subject = TextEditingController(
      text: widget.existing?.raw['subject']?.toString() ?? '');
  late final body = TextEditingController(
      text: widget.existing?.raw['body']?.toString() ?? '');
  late final group = TextEditingController(
      text: widget.existing?.raw['contactGroupId']?.toString() ?? '');
  late final provider = TextEditingController();
  late final template = TextEditingController(
      text: widget.existing?.raw['templateId']?.toString() ?? '');
  int channel = 4;
  int audience = 3;
  bool saving = false;
  int step = 0;
  DateTime? scheduledAt;
  String? error;
  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      channel = number(widget.existing!.raw['channel']);
      audience = number(widget.existing!.raw['audienceType']);
      scheduledAt = DateTime.tryParse(widget.existing!.raw['scheduledAtUtc']?.toString() ?? '')?.toLocal();
      provider.text = widget.existing!.raw['providerSettingId']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    name.dispose();
    subject.dispose();
    body.dispose();
    group.dispose();
    provider.dispose();
    template.dispose();
    super.dispose();
  }

  int? optional(TextEditingController v) => int.tryParse(v.text.trim());
  Future<void> save() async {
    if (saving) return;
    if (widget.existing != null &&
        (number(widget.existing!.raw['audienceType']) != 2 &&
            number(widget.existing!.raw['audienceType']) != 3)) {
      setState(() => error =
          'This draft audience needs the full web editor to preserve recipients.');
      return;
    }
    if (name.text.trim().isEmpty ||
        (audience == 3 && optional(group) == null)) {
      setState(() => error = 'Enter a campaign name and a valid group ID');
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await ref.read(campaignRepositoryProvider).saveDraft({
        'campaignName': name.text.trim(),
        'channel': channel,
        'audienceType': audience,
        'providerSettingId': optional(provider),
        'contactGroupId': audience == 3 ? optional(group) : null,
        'templateId': optional(template),
        'subject': subject.text.trim(),
        'body': body.text.trim(),
        'recipients': <Object>[],
        'hasAttachment': widget.existing?.raw['hasAttachment'] == true,
        'attachmentName': widget.existing?.raw['attachmentName'] ?? '',
        'attachmentUrl': widget.existing?.raw['attachmentUrl'] ?? '',
        'attachmentMimeType': widget.existing?.raw['attachmentMimeType'] ?? '',
        'attachmentSize': widget.existing?.raw['attachmentSize'],
        'whatsAppCommerce': widget.existing?.raw['whatsAppCommerce'],
        'scheduledAtUtc': scheduledAt?.toUtc().toIso8601String(),
      }, id: widget.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> chooseSchedule() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: scheduledAt?.isAfter(now) == true ? scheduledAt! : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: scheduledAt == null ? TimeOfDay.now() : TimeOfDay.fromDateTime(scheduledAt!),
    );
    if (time == null || !mounted) return;
    final selected = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    if (!selected.isAfter(now)) {
      setState(() => error = 'Choose a future schedule time.');
      return;
    }
    setState(() { scheduledAt = selected; error = null; });
  }

  Widget lookupField({
    required String label,
    required TextEditingController controller,
    required AsyncValue<List<Map<String, dynamic>>> source,
    bool requiredValue = false,
  }) {
    return source.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => Text('Unable to load $label. Retry by reopening this draft.'),
      data: (items) {
        final options = items.where((entry) =>
          label == 'Provider'
            ? (number(entry['channel']) == channel && entry['isEnabled'] == true)
            : label == 'Template'
              ? (number(entry['channel']) == channel && entry['isActive'] == true)
              : entry['isActive'] != false
        ).toList();
        final selected = int.tryParse(controller.text);
        final chosen = options.any((entry) => number(entry['id']) == selected)
            ? selected : null;
        return DropdownButtonFormField<int>(
          key: ValueKey('$label-$channel-$chosen'),
          initialValue: chosen,
          isExpanded: true,
          decoration: InputDecoration(labelText: label),
          items: [
            if (!requiredValue) DropdownMenuItem<int>(
              value: null, child: Text('Default / none'),
            ),
            ...options.map((entry) => DropdownMenuItem<int>(
              value: number(entry['id']),
              child: Text((entry['displayName'] ?? entry['name'] ?? 'Item').toString(),
                overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: saving ? null : (value) =>
              setState(() => controller.text = value?.toString() ?? ''),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Audience', 'Channel', 'Content', 'Schedule', 'Review'];
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Create campaign' : 'Edit campaign draft')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step ${step + 1} of 5 · ${steps[step]}',
                style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: (step + 1) / steps.length,
                borderRadius: BorderRadius.circular(6)),
            ]),
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (step == 0) ...[
                Text('Who will receive this campaign?',
                  style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                TextField(controller: name,
                  decoration: const InputDecoration(labelText: 'Campaign name')),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('All contacts')),
                    DropdownMenuItem(value: 3, child: Text('Contact group')),
                  ],
                  onChanged: saving ? null : (value) =>
                    setState(() => audience = value ?? 3),
                ),
                if (audience == 3) ...[
                  const SizedBox(height: 16),
                  lookupField(
                    label: 'Contact group',
                    controller: group,
                    source: ref.watch(campaignGroupsProvider),
                    requiredValue: true,
                  ),
                ],
              ],
              if (step == 1) ...[
                Text('Choose channel and sender', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: channel,
                  decoration: const InputDecoration(labelText: 'Channel'),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('Email')),
                    DropdownMenuItem(value: 3, child: Text('SMS')),
                    DropdownMenuItem(value: 4, child: Text('WhatsApp')),
                  ],
                  onChanged: widget.id != null || saving ? null : (value) =>
                    setState(() {
                      channel = value ?? 4;
                      provider.clear();
                      template.clear();
                    }),
                ),
                const SizedBox(height: 16),
                lookupField(
                  label: 'Provider',
                  controller: provider,
                  source: ref.watch(campaignProvidersProvider),
                ),
              ],
              if (step == 2) ...[
                Text('Compose message', style: theme.textTheme.titleLarge),
                const SizedBox(height: 16),
                lookupField(
                  label: 'Template',
                  controller: template,
                  source: ref.watch(campaignTemplatesProvider),
                ),
                const SizedBox(height: 16),
                TextField(controller: subject,
                  decoration: const InputDecoration(labelText: 'Subject')),
                const SizedBox(height: 16),
                TextField(controller: body, maxLines: 7,
                  decoration: const InputDecoration(labelText: 'Message body')),
                const SizedBox(height: 8),
                Text('Template/provider rules are validated by the server.',
                  style: theme.textTheme.bodySmall),
              ],
              if (step == 3) ...[
                Text('When should it be sent?', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  leading: Icon(scheduledAt == null
                      ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  title: const Text('No schedule yet'),
                  subtitle: const Text('Save draft and decide later'),
                  onTap: saving ? null : () => setState(() => scheduledAt = null),
                ),
                ListTile(
                  leading: Icon(scheduledAt != null
                      ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                  title: const Text('Schedule for later'),
                  onTap: saving ? null : chooseSchedule,
                ),
                if (scheduledAt != null) ListTile(
                  leading: const Icon(Icons.event_available_outlined),
                  title: Text(scheduledAt!.toLocal().toString().substring(0, 16)),
                  trailing: TextButton(onPressed: chooseSchedule,
                    child: const Text('Change')),
                ),
              ],
              if (step == 4) ...[
                Text('Review draft', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(title: const Text('Name'), subtitle: Text(name.text)),
                ListTile(title: const Text('Audience'),
                  subtitle: Text(audience == 2 ? 'All contacts' : 'Group: ${group.text}')),
                ListTile(title: const Text('Channel'),
                  subtitle: Text(switch (channel) { 2 => 'Email', 3 => 'SMS', _ => 'WhatsApp' })),
                ListTile(title: const Text('Provider'),
                  subtitle: Text(provider.text.isEmpty ? 'Default' : provider.text)),
                ListTile(title: const Text('Template'),
                  subtitle: Text(template.text.isEmpty ? 'None' : template.text)),
                ListTile(title: const Text('Schedule'),
                  subtitle: Text(scheduledAt?.toString() ?? 'Not scheduled')),
                const SizedBox(height: 8),
                Text('Saving creates/updates a draft. Publishing is a separate confirmed action.',
                  style: theme.textTheme.bodySmall),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              if (step > 0) OutlinedButton(
                onPressed: saving ? null : () => setState(() { step--; error = null; }),
                child: const Text('Back'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: saving ? null : () {
                  if (step == 0 &&
                      (name.text.trim().isEmpty ||
                      (audience == 3 && optional(group) == null))) {
                    setState(() => error = 'Enter a campaign name and select a contact group.');
                    return;
                  }
                  if (step < 4) {
                    setState(() { step++; error = null; });
                  } else {
                    save();
                  }
                },
                child: Text(saving ? 'Saving...' : step == 4 ? 'Save draft' : 'Continue'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
