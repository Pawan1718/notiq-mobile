import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'campaign_repository.dart';

class CampaignDraftPage extends ConsumerStatefulWidget {
  const CampaignDraftPage({super.key, this.id, this.existing});
  final int? id;
  final CampaignDetail? existing;
  @override
  ConsumerState<CampaignDraftPage> createState() => _CampaignDraftPageState();
}

class _CampaignDraftPageState extends ConsumerState<CampaignDraftPage> {
  late final name = TextEditingController(
    text: widget.existing?.name ??
        'Campaign - ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
  );
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
      setState(() => error = 'Select a contact group to continue.');
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
              setState(() { controller.text = value?.toString() ?? ''; error = null; }),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 80,
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        )),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = ['Setup', 'Message', 'Review & schedule'];
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Create campaign' : 'Edit campaign draft')),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Step ${step + 1} of 3 · ${steps[step]}',
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
                const SizedBox(height: 2),
                TextField(controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Campaign name',
                    helperText: 'Auto-filled · you can rename it',
                  )),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  initialValue: audience,
                  decoration: const InputDecoration(labelText: 'Audience'),
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('All contacts')),
                    DropdownMenuItem(value: 3, child: Text('Contact group')),
                  ],
                  onChanged: saving ? null : (value) =>
                    setState(() { audience = value ?? 3; error = null; }),
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
              if (step == 0) ...[
                const SizedBox(height: 22),
                Text('Channel', style: theme.textTheme.titleMedium),
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
              if (step == 1) ...[
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
              if (step == 2) ...[
                Text('Schedule', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  child: Column(children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(scheduledAt == null
                          ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      onTap: saving ? null : () => setState(() => scheduledAt = null),
                      title: const Text('Save without schedule'),
                      subtitle: const Text('You can schedule or publish later'),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      leading: Icon(scheduledAt != null
                          ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                      onTap: saving ? null : chooseSchedule,
                      title: const Text('Schedule for later'),
                      subtitle: scheduledAt == null
                          ? const Text('Choose a date and time')
                          : Text(DateFormat('dd MMM yyyy, hh:mm a').format(scheduledAt!)),
                    ),
                    if (scheduledAt != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12, bottom: 8),
                          child: TextButton.icon(
                            onPressed: saving ? null : chooseSchedule,
                            icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                            label: const Text('Change time'),
                          ),
                        ),
                      ),
                  ]),
                ),
                const SizedBox(height: 22),
                Text('Campaign summary', style: theme.textTheme.titleMedium),
                const SizedBox(height: 10),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Column(children: [
                      _summaryRow('Name', name.text),
                      const Divider(height: 1),
                      _summaryRow('Audience', audience == 2
                          ? 'All contacts' : 'Contact group'),
                      const Divider(height: 1),
                      _summaryRow('Channel', switch (channel) {
                        2 => 'Email', 3 => 'SMS', _ => 'WhatsApp'
                      }),
                      const Divider(height: 1),
                      _summaryRow('Provider', provider.text.isEmpty
                          ? 'Default' : 'Selected provider'),
                      const Divider(height: 1),
                      _summaryRow('Template', template.text.isEmpty
                          ? 'None' : 'Selected template'),
                    ]),
                  ),
                ),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(Icons.info_outline_rounded, size: 18,
                      color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'Save draft does not send messages. Publishing is a separate confirmed action.',
                    style: theme.textTheme.bodySmall,
                  )),
                ]),
              ],
              if (error != null) ...[
                const SizedBox(height: 12),
                Text(error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
            ],
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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
                    setState(() => error = 'Select a contact group to continue.');
                    return;
                  }
                  if (step < 2) {
                    setState(() { step++; error = null; });
                  } else {
                    save();
                  }
                },
                child: Text(saving ? 'Saving...' : step == 2 ? 'Save draft' : 'Continue'),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
