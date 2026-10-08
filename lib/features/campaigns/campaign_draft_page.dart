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
  late final provider = TextEditingController(
      text: widget.existing?.raw['providerSettingId']?.toString() ?? '');
  DateTime? scheduledAtUtc;
  late final template = TextEditingController(
      text: widget.existing?.raw['templateId']?.toString() ?? '');
  int channel = 4;
  int audience = 3;
  bool saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      channel = number(widget.existing!.raw['channel']);
      audience = number(widget.existing!.raw['audienceType']);
      scheduledAtUtc = DateTime.tryParse(widget.existing!.raw['scheduledAtUtc']?.toString() ?? '')?.toUtc();
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
  Future<void> chooseSchedule() async {
    final now = DateTime.now();
    final current = scheduledAtUtc?.toLocal();
    final selected = await showDatePicker(
      context: context,
      initialDate: current != null && current.isAfter(now) ? current : now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (selected == null || !mounted) return;
    final time = await showTimePicker(context: context,
      initialTime: TimeOfDay.fromDateTime(
        current != null && current.isAfter(now)
          ? current : now.add(const Duration(hours: 1))));
    if (time == null || !mounted) return;
    final local = DateTime(selected.year, selected.month, selected.day,
      time.hour, time.minute);
    if (!local.isAfter(DateTime.now())) {
      setState(() => error = 'Choose a future date and time.');
      return;
    }
    setState(() { scheduledAtUtc = local.toUtc(); error = null; });
  }

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
      if (scheduledAtUtc != null && !scheduledAtUtc!.isAfter(DateTime.now().toUtc())) {
        setState(() => error = 'Scheduled time must be in the future.');
        return;
      }
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
        'scheduledAtUtc': scheduledAtUtc?.toIso8601String(),
      }, id: widget.id);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            title:
                Text(widget.id == null ? 'New campaign draft' : 'Edit draft')),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Campaign name')),
          DropdownButtonFormField<int>(
              initialValue: channel,
              decoration: const InputDecoration(labelText: 'Channel'),
              items: const [
                DropdownMenuItem(value: 2, child: Text('Email')),
                DropdownMenuItem(value: 3, child: Text('SMS')),
                DropdownMenuItem(value: 4, child: Text('WhatsApp'))
              ],
              onChanged: widget.id == null
                  ? (v) => setState(() => channel = v ?? 4)
                  : null),
          DropdownButtonFormField<int>(
              initialValue: audience,
              decoration: const InputDecoration(labelText: 'Audience'),
              items: const [
                DropdownMenuItem(value: 2, child: Text('All contacts')),
                DropdownMenuItem(value: 3, child: Text('Contact group'))
              ],
              onChanged: (v) => setState(() => audience = v ?? 3)),
          if (audience == 3)
            TextField(
                controller: group,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Contact group ID')),
          TextField(
              controller: provider,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Provider setting ID (optional)')),
          TextField(
              controller: template,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Template ID (optional)')),
          TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'Subject')),
          TextField(
              controller: body,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Message body')),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.schedule_outlined),
            title: Text(scheduledAtUtc == null ? 'Send when published'
              : 'Scheduled: ${scheduledAtUtc!.toLocal()}'),
            subtitle: const Text('Publish performs the final scheduling validation.'),
            trailing: Wrap(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Set schedule',
                icon: const Icon(Icons.edit_calendar_outlined),
                onPressed: saving ? null : chooseSchedule,
              ),
              if (scheduledAtUtc != null)
                IconButton(
                  tooltip: 'Clear schedule',
                  icon: const Icon(Icons.close),
                  onPressed: saving ? null : () => setState(() => scheduledAtUtc = null),
                ),
            ]),
          ),
          if (error != null)
            Text(error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          FilledButton(
              onPressed: saving ? null : save,
              child: Text(saving ? 'Saving…' : 'Save draft (does not send)')),
          const Text('Publishing a draft is a separate, confirmed action.'),
        ]),
      );
}
