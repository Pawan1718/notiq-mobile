import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'inbox_repository.dart';
import 'inbox_models.dart';
import 'inbox_details_sheet.dart';
import 'package:intl/intl.dart';
import '../../core/realtime/inbox_realtime_service.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});
  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  int page = 1;
  bool unreadOnly = false;
  String search = '';
  int? statusFilter;
  int? modeFilter;
  final searchController = TextEditingController();
  late final ProviderSubscription<AsyncValue<InboxRealtimeEvent>> realtimeSubscription;

  @override
  void initState() {
    super.initState();
    realtimeSubscription = ref.listenManual(inboxRealtimeProvider, (_, next) {
      if (next.valueOrNull != null && mounted) {
        ref.invalidate(inboxFilteredProvider((page: page, search: search, status: statusFilter, mode: modeFilter)));
      }
    });
  }

  @override
  void dispose() {
    realtimeSubscription.close();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = (page: page, search: search, status: statusFilter, mode: modeFilter);
    final result = ref.watch(inboxFilteredProvider(filter));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            tooltip: 'Refresh conversations',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(inboxFilteredProvider(filter)),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: Text('Conversations', style: theme.textTheme.headlineSmall),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                controller: searchController,
                onSubmitted: (value) => setState(() { search = value.trim(); page = 1; }),
                decoration: const InputDecoration(
                  hintText: 'Search all conversations',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: !unreadOnly,
                    onSelected: (_) => setState(() => unreadOnly = false),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Unread'),
                    selected: unreadOnly,
                    onSelected: (_) => setState(() => unreadOnly = true),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int?>(
                    value: statusFilter,
                    hint: const Text('Any status'),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('Any status')),
                      DropdownMenuItem<int?>(value: 1, child: Text('Open')),
                      DropdownMenuItem<int?>(value: 3, child: Text('Pending')),
                      DropdownMenuItem<int?>(value: 2, child: Text('Resolved')),
                    ],
                    onChanged: (value) => setState(() { statusFilter = value; page = 1; }),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int?>(
                    value: modeFilter,
                    hint: const Text('Any mode'),
                    items: const [
                      DropdownMenuItem<int?>(value: null, child: Text('Any mode')),
                      DropdownMenuItem<int?>(value: 1, child: Text('Bot')),
                      DropdownMenuItem<int?>(value: 2, child: Text('Human')),
                    ],
                    onChanged: (value) => setState(() { modeFilter = value; page = 1; }),
                  ),
                ],
              )),
            ),
            const Divider(height: 1),
            Expanded(
              child: result.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => Center(child: FilledButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry inbox'),
                  onPressed: () => ref.invalidate(inboxFilteredProvider(filter)),
                )),
                data: (data) {
                  final matches = data.items.where((item) {
                    if (unreadOnly && item.unreadCount == 0) return false;
                    return true;
                  }).toList();
                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(inboxFilteredProvider(filter));
                      await ref.read(inboxFilteredProvider(filter).future);
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: matches.isEmpty ? 1 : matches.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 78),
                      itemBuilder: (context, index) {
                        if (matches.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(36),
                            child: Column(
                              children: [
                                Icon(Icons.mark_chat_read_outlined, size: 40,
                                    color: colors.onSurfaceVariant),
                                const SizedBox(height: 12),
                                const Text('No matching conversations'),
                                const SizedBox(height: 4),
                                Text('Unread applies to this page; search, status and mode apply to all pages.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          );
                        }
                        final item = matches[index];
                        final name = item.contactName.isEmpty
                            ? item.phoneNumber : item.contactName;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: colors.primaryContainer,
                            child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                              style: TextStyle(color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w700)),
                          ),
                          title: Text(name, maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontWeight: item.unreadCount > 0
                                  ? FontWeight.w700 : FontWeight.w600)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Text(
                              item.preview.isEmpty ? 'No message preview' : item.preview,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          trailing: item.unreadCount > 0
                              ? Container(
                                  constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  decoration: BoxDecoration(
                                    color: colors.primary,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${item.unreadCount}',
                                      style: TextStyle(color: colors.onPrimary,
                                          fontWeight: FontWeight.w700, fontSize: 12)),
                                )
                              : const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(builder: (_) => ConversationPage(
                              conversationId: item.id, title: name,
                              initialConversation: item)),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            result.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (data) => Container(
                padding: const EdgeInsets.symmetric(vertical: 5),
                decoration: BoxDecoration(
                  color: colors.surface,
                  border: Border(top: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  IconButton(
                    tooltip: 'Previous page',
                    onPressed: page > 1 ? () => setState(() => page--) : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $page of ${data.totalPages}',
                      style: theme.textTheme.labelMedium),
                  IconButton(
                    tooltip: 'Next page',
                    onPressed: page < data.totalPages
                        ? () => setState(() => page++) : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage({
    super.key, required this.conversationId, required this.title, this.initialConversation,
  });
  final int conversationId;
  final String title;
  final InboxConversation? initialConversation;
  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final controller = TextEditingController();
  bool sending = false;
  bool markingRead = false;
  String? error;
  InboxConversation? currentConversation;
  late final ProviderSubscription<AsyncValue<InboxRealtimeEvent>> realtimeSubscription;

  @override
  void initState() {
    super.initState();
    currentConversation = widget.initialConversation;
    realtimeSubscription = ref.listenManual(inboxRealtimeProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null || !mounted) return;
      if (event.conversationId == null ||
          event.conversationId == widget.conversationId) {
        ref.invalidate(inboxMessagesProvider(widget.conversationId));
      }
    });
  }

  @override
  void dispose() {
    realtimeSubscription.close();
    controller.dispose();
    super.dispose();
  }

  Future<void> openDetails() async {
    final conversation = currentConversation;
    if (conversation == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .82,
        child: InboxDetailsSheet(
          conversation: conversation,
          onUpdated: (updated) {
            if (mounted) setState(() => currentConversation = updated);
            ref.invalidate(inboxPageProvider(1));
          },
        ),
      ),
    );
  }

  Future<void> insertQuickReply() async {
    final replies = await showModalBottomSheet<InboxQuickReply>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Consumer(builder: (context, ref, _) {
          final result = ref.watch(inboxQuickRepliesProvider);
          return result.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: TextButton(
              onPressed: () => ref.invalidate(inboxQuickRepliesProvider),
              child: const Text('Retry loading quick replies'),
            )),
            data: (items) => ListView(
              shrinkWrap: true,
              children: [
                const ListTile(title: Text('Quick replies')),
                ...items.map((reply) => ListTile(
                  title: Text(reply.title),
                  subtitle: Text(reply.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(context, reply),
                )),
                if (items.isEmpty) const ListTile(title: Text('No quick replies yet')),
              ],
            ),
          );
        }),
      ),
    );
    if (replies == null || !mounted) return;
    if (controller.text.trim().isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Replace your draft?'),
          content: const Text('Your current message will be replaced with this saved reply.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Replace'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    controller.text = replies.body;
    controller.selection = TextSelection.collapsed(offset: controller.text.length);
  }

  Future<void> sendReply() async {
    final body = controller.text.trim();
    if (body.isEmpty || sending || currentConversation?.mode != 2) return;
    setState(() { sending = true; error = null; });
    try {
      await ref.read(inboxRepositoryProvider).reply(widget.conversationId, body);
      if (!mounted) return;
      controller.clear();
      ref.invalidate(inboxMessagesProvider(widget.conversationId));
      ref.invalidate(inboxPageProvider(1));
    } catch (_) {
      if (mounted) setState(() => error = 'Reply failed. Please retry.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> markRead() async {
    if (markingRead) return;
    setState(() { markingRead = true; error = null; });
    try {
      await ref.read(inboxRepositoryProvider).markRead(widget.conversationId);
      ref.invalidate(inboxPageProvider(1));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Marked as read')),
        );
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Could not mark as read.');
    } finally {
      if (mounted) setState(() => markingRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(inboxMessagesProvider(widget.conversationId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: colors.primaryContainer,
            child: Text(widget.title.isEmpty ? '?' : widget.title[0].toUpperCase(),
                style: TextStyle(color: colors.onPrimaryContainer,
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium),
              Text('WhatsApp conversation', style: theme.textTheme.bodySmall),
            ],
          )),
        ]),
        actions: [
          IconButton(
            tooltip: 'Conversation details',
            icon: const Icon(Icons.tune_rounded),
            onPressed: currentConversation == null ? null : openDetails,
          ),
          IconButton(
            tooltip: 'Mark as read',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: markingRead ? null : markRead,
          ),
          IconButton(
            tooltip: 'Refresh messages',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(inboxMessagesProvider(widget.conversationId)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          if (currentConversation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                Chip(label: Text(switch (currentConversation!.status) {
                  2 => 'Resolved',
                  3 => 'Pending',
                  _ => 'Open',
                })),
                Chip(label: Text(currentConversation!.mode == 2 ? 'Human' : 'Bot')),
                if (currentConversation!.assignedUserName?.isNotEmpty == true)
                  Chip(label: Text(currentConversation!.assignedUserName!)),
              ]),
            ),
          if (currentConversation?.mode == 1)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('Bot mode is active. Switch to Human in conversation details to reply.',
                style: theme.textTheme.bodySmall),
            ),
          if (error != null)
            MaterialBanner(
              content: Text(error!),
              leading: Icon(Icons.error_outline, color: colors.error),
              actions: [TextButton(
                onPressed: () => setState(() => error = null),
                child: const Text('Dismiss'),
              )],
            ),
          Expanded(child: messages.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => Center(child: FilledButton(
              onPressed: () => ref.invalidate(inboxMessagesProvider(widget.conversationId)),
              child: const Text('Retry loading messages'),
            )),
            data: (items) => items.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final message = items[index];
                      final outbound = message.direction == 2 ||
                          message.direction?.toString().toLowerCase() == 'outbound';
                      return Align(
                        alignment: outbound ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * .82,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: outbound ? colors.primary : colors.surfaceContainerLow,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(outbound ? 16 : 4),
                                  bottomRight: Radius.circular(outbound ? 4 : 16),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 11),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      message.content.isEmpty
                                          ? '[Non-text message]' : message.content,
                                      style: TextStyle(
                                        color: outbound ? colors.onPrimary : colors.onSurface,
                                        height: 1.35,
                                      ),
                                    ),
                                    if (message.messageType.isNotEmpty &&
                                        message.messageType.toLowerCase() != 'text') ...[
                                      const SizedBox(height: 4),
                                      Text('Type: ${message.messageType}',
                                        style: TextStyle(fontSize: 11,
                                          color: outbound ? colors.onPrimary : colors.onSurfaceVariant)),
                                    ],
                                    if (message.createdAt != null) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        DateFormat('h:mm a').format(message.createdAt!.toLocal()),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: outbound
                                              ? colors.onPrimary.withValues(alpha: .78)
                                              : colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          )),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(top: BorderSide(color: theme.dividerColor)),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              IconButton(
                tooltip: 'Quick replies',
                onPressed: sending || currentConversation?.mode != 2 ? null : insertQuickReply,
                icon: const Icon(Icons.bolt_outlined),
              ),
              Expanded(child: TextField(
                controller: controller,
                enabled: !sending && currentConversation?.mode == 2,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: currentConversation?.mode == 2
                      ? 'Write a reply...' : 'Switch to Human mode to reply',
                  isDense: true,
                ),
              )),
              const SizedBox(width: 8),
              IconButton.filled(
                tooltip: 'Send reply',
                onPressed: sending || currentConversation?.mode != 2 ? null : sendReply,
                icon: sending
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: Colors.white))
                    : const Icon(Icons.send_rounded),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
