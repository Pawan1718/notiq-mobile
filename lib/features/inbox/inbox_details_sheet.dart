import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'inbox_models.dart';
import 'inbox_repository.dart';

/// Conversation collaboration controls backed by existing Notiq API routes.
class InboxDetailsSheet extends ConsumerStatefulWidget {
  const InboxDetailsSheet({
    super.key,
    required this.conversation,
    required this.onUpdated,
  });

  final InboxConversation conversation;
  final ValueChanged<InboxConversation> onUpdated;

  @override
  ConsumerState<InboxDetailsSheet> createState() => _InboxDetailsSheetState();
}

class _InboxDetailsSheetState extends ConsumerState<InboxDetailsSheet> {
  late InboxConversation conversation;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    conversation = widget.conversation;
  }

  Future<void> update(Future<InboxConversation> Function() action) async {
    if (saving) return;
    setState(() { saving = true; error = null; });
    try {
      final changed = await action();
      if (!mounted) return;
      setState(() => conversation = changed);
      widget.onUpdated(changed);
    } catch (_) {
      if (mounted) setState(() => error = 'Could not update conversation. Check permissions and retry.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(inboxRepositoryProvider);
    final assignees = ref.watch(inboxAssigneesProvider);
    final tags = ref.watch(inboxTagsProvider);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(children: [
              Expanded(child: Text('Conversation details',
                  style: Theme.of(context).textTheme.titleLarge)),
              IconButton(
                tooltip: 'Close details',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ]),
            if (error != null) Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error!, style: TextStyle(
                  color: Theme.of(context).colorScheme.error)),
            ),
            const SizedBox(height: 12),
            Text('Status', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Open')),
                ButtonSegment(value: 3, label: Text('Pending')),
                ButtonSegment(value: 2, label: Text('Resolved')),
              ],
              selected: {conversation.status},
              onSelectionChanged: saving ? null : (values) => update(
                () => repo.updateStatus(conversation.id, values.first)),
            ),
            const SizedBox(height: 22),
            Text('Conversation mode',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('Bot')),
                ButtonSegment(value: 2, label: Text('Human')),
              ],
              selected: {conversation.mode},
              onSelectionChanged: saving ? null : (values) => update(
                () => repo.updateMode(conversation.id, values.first)),
            ),
            const SizedBox(height: 22),
            Text('Assigned agent',
                style: Theme.of(context).textTheme.titleMedium),
            assignees.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(inboxAssigneesProvider),
                child: const Text('Retry loading agents'),
              ),
              data: (items) => DropdownButtonFormField<int>(
                value: conversation.assignedUserId ?? -1,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Assigned to'),
                items: [
                  const DropdownMenuItem(value: -1, child: Text('Unassigned')),
                  ...items.map((agent) => DropdownMenuItem(
                    value: agent.id,
                    child: Text(agent.name, overflow: TextOverflow.ellipsis),
                  )),
                ],
                onChanged: saving ? null : (id) => update(
                  () => repo.updateAssignment(conversation.id, id == -1 ? null : id)),
              ),
            ),
            const SizedBox(height: 22),
            Text('Tags', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            tags.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => TextButton(
                onPressed: () => ref.invalidate(inboxTagsProvider),
                child: const Text('Retry loading tags'),
              ),
              data: (items) => items.isEmpty
                  ? const Text('No tags available')
                  : Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: items.map((tag) {
                        final selected = conversation.tags.any((t) => t.id == tag.id);
                        return FilterChip(
                          label: Text(tag.name),
                          selected: selected,
                          onSelected: saving ? null : (checked) {
                            final selectedIds = conversation.tags.map((t) => t.id).toSet();
                            checked ? selectedIds.add(tag.id) : selectedIds.remove(tag.id);
                            update(() => repo.updateTags(
                              conversation.id, selectedIds.toList()));
                          },
                        );
                      }).toList(),
                    ),
            ),
            if (saving) const Padding(
              padding: EdgeInsets.only(top: 16),
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}
