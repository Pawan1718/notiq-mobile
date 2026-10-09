import 'package:file_picker/file_picker.dart';
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
  bool useTemplate = false;
  bool uploading = false;
  Map<String, dynamic>? uploadedAttachment;
  int channel = 4;
  int audience = 3;
  bool saving = false;
  int step = 0;
  DateTime? scheduledAt;
  String? error;
  @override
  void initState() {
    super.initState();
    useTemplate = template.text.trim().isNotEmpty;
    body.addListener(_refreshComposer);
    subject.addListener(_refreshComposer);
    if (widget.existing != null) {
      channel = number(widget.existing!.raw['channel']);
      audience = number(widget.existing!.raw['audienceType']);
      scheduledAt = DateTime.tryParse(widget.existing!.raw['scheduledAtUtc']?.toString() ?? '')?.toLocal();
      provider.text = widget.existing!.raw['providerSettingId']?.toString() ?? '';
    }
  }

  void _refreshComposer() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    body.removeListener(_refreshComposer);
    subject.removeListener(_refreshComposer);
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
        'templateId': useTemplate ? optional(template) : null,
        'subject': subject.text.trim(),
        'body': body.text.trim(),
        'recipients': <Object>[],
        'hasAttachment': uploadedAttachment != null || widget.existing?.raw['hasAttachment'] == true,
        'attachmentName': uploadedAttachment?['attachmentName'] ?? widget.existing?.raw['attachmentName'] ?? '',
        'attachmentUrl': uploadedAttachment?['attachmentUrl'] ?? widget.existing?.raw['attachmentUrl'] ?? '',
        'attachmentMimeType': uploadedAttachment?['attachmentMimeType'] ?? widget.existing?.raw['attachmentMimeType'] ?? '',
        'attachmentSize': uploadedAttachment?['attachmentSize'] ?? widget.existing?.raw['attachmentSize'],
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

  void _insert(String value) {
    final selection = body.selection;
    final position = selection.isValid ? selection.start : body.text.length;
    final end = selection.isValid ? selection.end : position;
    body.value = TextEditingValue(
      text: body.text.replaceRange(position, end, value),
      selection: TextSelection.collapsed(offset: position + value.length),
    );
  }

  Future<void> _chooseAttachment() async {
    if (channel == 3 || uploading) return;
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'jpg', 'jpeg', 'png', 'webp', 'pdf', 'mp4',
          'mp3', 'ogg', 'doc', 'docx',
        ],
        withData: true,
      );
      if (!mounted || picked == null || picked.files.isEmpty) return;
      final file = picked.files.single;
      if (file.size == 0 || file.size > 25 * 1024 * 1024) {
        setState(() => error = 'File must be between 1 byte and 25 MB.');
        return;
      }
      if (file.bytes == null) {
        setState(() => error = 'Cannot read the selected file.');
        return;
      }
      setState(() { uploading = true; error = null; });
      final uploaded = await ref.read(campaignRepositoryProvider).uploadAttachment(
        channel: channel, name: file.name, bytes: file.bytes!,
      );
      if (mounted) setState(() => uploadedAttachment = uploaded);
    } catch (_) {
      if (mounted) setState(() => error = 'Upload failed. Please retry.');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  void _showTools() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Message tools', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.attach_file_rounded),
              title: const Text('Attach file'),
              subtitle: Text(channel == 3
                  ? 'Not supported for SMS' : 'Images, video, audio and documents (max 25 MB)'),
              enabled: channel != 3 && !uploading,
              onTap: () { Navigator.pop(sheetContext); _chooseAttachment(); },
            ),
            ListTile(
              leading: const Icon(Icons.emoji_emotions_outlined),
              title: const Text('Emojis'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showInsertOptions(['😀','😊','❤️','🎉','👍','🙏','🔥','✅','✨','👋']);
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object_rounded),
              title: const Text('Placeholders'),
              subtitle: const Text('Personalize for each recipient'),
              onTap: () {
                Navigator.pop(sheetContext);
                _showInsertOptions([
                  '{{Name}}','{{RecipientName}}','{{MobileNumber}}',
                  '{{WhatsAppNumber}}','{{Email}}','{{Tags}}','{{Date}}',
                ]);
              },
            ),
          ]),
        ),
      ),
    );
  }

  void _showInsertOptions(List<String> values) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Wrap(spacing: 8, runSpacing: 8, children: [
            for (final value in values)
              ActionChip(
                label: Text(value),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _insert(value);
                },
              ),
          ]),
        ),
      ),
    );
  }

  Widget _messageStep(ThemeData theme) {
    final colors = theme.colorScheme;
    final templates = ref.watch(campaignTemplatesProvider);
    final selectedId = optional(template);
    final selectedTemplate = templates.valueOrNull
        ?.where((item) => number(item['id']) == selectedId)
        .firstOrNull;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your message', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Custom'),
                icon: Icon(Icons.chat_bubble_outline_rounded)),
              ButtonSegment(value: true, label: Text('Template'),
                icon: Icon(Icons.article_outlined)),
            ],
            selected: {useTemplate},
            onSelectionChanged: saving ? null : (selection) {
              setState(() {
                useTemplate = selection.first;
                if (!useTemplate) template.clear();
                error = null;
              });
            },
          ),
        ]),
      ),
      if (useTemplate)
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            lookupField(label: 'Template', controller: template,
              source: templates, requiredValue: true),
            const SizedBox(height: 16),
            if (selectedTemplate != null) ...[
              Text('Message preview', style: theme.textTheme.titleSmall),
              const SizedBox(height: 10),
              Card(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (channel == 2 && (selectedTemplate['subject'] ?? '').toString().isNotEmpty) ...[
                      Text(selectedTemplate['subject'].toString(),
                        style: theme.textTheme.titleSmall),
                      const SizedBox(height: 10),
                    ],
                    SelectableText((selectedTemplate['body'] ?? '').toString()),
                  ],
                ),
              )),
            ] else
              Text('Select an active template to preview it.',
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Text('Template content is managed on Notiq Web.',
              style: theme.textTheme.bodySmall),
          ],
        ))
      else ...[
        if (channel == 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(controller: subject,
              decoration: const InputDecoration(labelText: 'Email subject'),
            ),
          ),
        Expanded(child: Container(
          width: double.infinity,
          color: colors.surfaceContainerLowest,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
            children: [
              Center(child: Text('Message preview · not sent',
                style: theme.textTheme.bodySmall)),
              const SizedBox(height: 22),
              if (body.text.trim().isNotEmpty || uploadedAttachment != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(14),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (body.text.trim().isNotEmpty)
                            SelectableText(body.text, style: TextStyle(
                              color: colors.onPrimaryContainer)),
                          if (uploadedAttachment != null) ...[
                            if (body.text.isNotEmpty) const SizedBox(height: 10),
                            Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.attach_file_rounded,
                                color: colors.onPrimaryContainer, size: 18),
                              const SizedBox(width: 6),
                              Flexible(child: Text(
                                uploadedAttachment!['attachmentName'].toString(),
                                style: TextStyle(color: colors.onPrimaryContainer),
                                overflow: TextOverflow.ellipsis)),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                )
              else
                Center(child: Text('Start typing to preview your message',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall)),
            ],
          ),
        )),
        if (uploadedAttachment != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
            child: InputChip(
              label: Text(uploadedAttachment!['attachmentName'].toString(),
                overflow: TextOverflow.ellipsis),
              onDeleted: () => setState(() => uploadedAttachment = null),
            ),
          ),
        if (uploading) const LinearProgressIndicator(),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            IconButton.filledTonal(
              tooltip: 'Message tools',
              onPressed: uploading ? null : _showTools,
              icon: const Icon(Icons.add_rounded),
            ),
            const SizedBox(width: 8),
            Expanded(child: TextField(
              controller: body,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Type a message…',
                isDense: true,
              ),
            )),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Message preview updates automatically',
              onPressed: null,
              icon: const Icon(Icons.visibility_outlined),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16, bottom: 6),
          child: Align(alignment: Alignment.centerRight,
            child: Text('${body.text.characters.length} characters',
              style: theme.textTheme.bodySmall)),
        ),
      ],
    ]);
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
          Expanded(child: step == 1 ? _messageStep(theme) : ListView(
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
                      _summaryRow('Message', useTemplate && template.text.isNotEmpty
                          ? 'Template' : 'Custom message'),
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
                  if (step == 1 && (useTemplate
                      ? optional(template) == null
                      : body.text.trim().isEmpty)) {
                    setState(() => error = useTemplate
                        ? 'Choose a template to continue.'
                        : 'Write your message to continue.');
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
