import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'inbox_repository.dart';
import '../../core/realtime/inbox_realtime_service.dart';

class InboxPage extends ConsumerStatefulWidget {
  const InboxPage({super.key});
  @override
  ConsumerState<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends ConsumerState<InboxPage> {
  int page = 1;
  ProviderSubscription<AsyncValue<InboxRealtimeEvent>>? _subscription;

  @override
  void initState() {
    super.initState();
    _observeRealtime();
  }

  void _observeRealtime() {
    // Keep a single authenticated connection alive while inbox is visible.
    _subscription = ref.listenManual(inboxRealtimeProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null || !mounted) return;
      ref.invalidate(inboxPageProvider(page));
    }, fireImmediately: false);
  }

  @override
  void dispose() {
    _subscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(inboxRealtimeProvider);
    final result = ref.watch(inboxPageProvider(page));
    return Scaffold(
      appBar: AppBar(title: const Text('WhatsApp Inbox'), actions: [
        IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(inboxPageProvider(page))),
      ]),
      body: result.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
            child: FilledButton(
                onPressed: () => ref.invalidate(inboxPageProvider(page)),
                child: const Text('Retry loading inbox'))),
        data: (data) => Column(children: [
          Expanded(
              child: data.items.isEmpty
                  ? const Center(child: Text('No conversations found'))
                  : ListView.builder(
                      itemCount: data.items.length,
                      itemBuilder: (context, index) {
                        final item = data.items[index];
                        return ListTile(
                          title: Text(item.contactName.isEmpty
                              ? item.phoneNumber
                              : item.contactName),
                          subtitle: Text(item.preview,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(item.mode == 2 ? Icons.support_agent : Icons.smart_toy_outlined,
                              size: 18, semanticLabel: item.mode == 2 ? 'Human' : 'KRAG AI'),
                            if (item.unreadCount > 0) ...[
                              const SizedBox(width: 8),
                              CircleAvatar(radius: 13, child: Text('${item.unreadCount}',
                                style: const TextStyle(fontSize: 11))),
                            ],
                          ]),
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) => ConversationPage(
                                      conversationId: item.id,
                                      initialMode: item.mode,
                                      title: item.contactName.isEmpty
                                          ? item.phoneNumber
                                          : item.contactName))),
                        );
                      },
                    )),
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
      ),
    );
  }
}

class ConversationPage extends ConsumerStatefulWidget {
  const ConversationPage(
      {super.key, required this.conversationId, required this.title, required this.initialMode});
  final int conversationId;
  final int initialMode;
  final String title;
  @override
  ConsumerState<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends ConsumerState<ConversationPage> {
  final controller = TextEditingController();
  bool sending = false;
  bool markingRead = false;
  bool switchingMode = false;
  int? currentMode;
  String? error;
  late final ProviderSubscription<AsyncValue<InboxRealtimeEvent>>
      realtimeSubscription;

  @override
  void initState() {
    super.initState();
    realtimeSubscription = ref.listenManual(inboxRealtimeProvider, (_, next) {
      final event = next.valueOrNull;
      if (event == null || !mounted) return;
      if (event.conversationId == null ||
          event.conversationId == widget.conversationId) {
        ref.invalidate(inboxMessagesProvider(widget.conversationId));
        ref.invalidate(inboxPageProvider(1));
      }
    });
  }

  @override
  void dispose() {
    realtimeSubscription.close();
    controller.dispose();
    super.dispose();
  }

  Future<void> changeMode(int mode) async {
    if (switchingMode || currentMode == mode) return;
    setState(() { switchingMode = true; error = null; });
    try {
      final updated = await ref.read(inboxRepositoryProvider)
          .setMode(widget.conversationId, mode);
      if (mounted) setState(() => currentMode = updated.mode);
      ref.invalidate(inboxPageProvider(1));
    } catch (_) {
      if (mounted) setState(() => error = 'Could not change conversation mode.');
    } finally {
      if (mounted) setState(() => switchingMode = false);
    }
  }

  Future<void> sendReply() async {
    final body = controller.text.trim();
    if (body.isEmpty || sending) return;
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await ref
          .read(inboxRepositoryProvider)
          .reply(widget.conversationId, body);
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
    setState(() {
      markingRead = true;
      error = null;
    });
    try {
      await ref.read(inboxRepositoryProvider).markRead(widget.conversationId);
      ref.invalidate(inboxPageProvider(1));
    } catch (_) {
      if (mounted) setState(() => error = 'Could not mark as read.');
    } finally {
      if (mounted) setState(() => markingRead = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(inboxRealtimeProvider);
    final inbox = ref.watch(inboxPageProvider(1));
    final conversation = inbox.valueOrNull?.items.where(
      (item) => item.id == widget.conversationId).firstOrNull;
    final mode = currentMode ?? conversation?.mode ?? widget.initialMode;
    final messages = ref.watch(inboxMessagesProvider(widget.conversationId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.title), actions: [
        IconButton(
            tooltip: 'Mark as read',
            icon: const Icon(Icons.mark_email_read_outlined),
            onPressed: markingRead ? null : markRead),
        IconButton(
            tooltip: 'Refresh messages',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(inboxMessagesProvider(widget.conversationId))),
      ]),
      body: SafeArea(
          child: Column(children: [
        if (mode != null)
          ListTile(
            leading: Icon(mode == 2 ? Icons.support_agent : Icons.smart_toy_outlined),
            title: Text(mode == 2 ? 'Human takeover active' : 'KRAG AI auto-reply mode'),
            subtitle: Text(mode == 2 ? 'Agent handles replies' : 'Bot handles incoming messages'),
            trailing: switchingMode
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(
                    onPressed: () => changeMode(mode == 2 ? 1 : 2),
                    child: Text(mode == 2 ? 'Return to AI' : 'Take over'),
                  ),
          ),
        if (error != null)
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(error!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error))),
        Expanded(
            child: messages.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
              child: FilledButton(
                  onPressed: () => ref
                      .invalidate(inboxMessagesProvider(widget.conversationId)),
                  child: const Text('Retry loading messages'))),
          data: (items) => items.isEmpty
              ? const Center(child: Text('No messages yet'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final message = items[index];
                    final outbound = message.direction == 2 ||
                        message.direction?.toString().toLowerCase() ==
                            'outbound';
                    final sender = message.senderType;
                    final senderLabel = sender == 2 || sender.toString().toLowerCase() == 'bot'
                        ? 'KRAG AI' : sender == 3 || sender.toString().toLowerCase() == 'agent'
                            ? 'Agent' : outbound ? 'Outgoing' : 'Customer';
                    return Align(
                      alignment: outbound
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                          child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, children: [
                                  Text(senderLabel, style: Theme.of(context).textTheme.labelSmall),
                                  const SizedBox(height: 4),
                                  Text(message.content.isEmpty ? '[Non-text message]' : message.content),
                                ]))),
                    );
                  },
                ),
        )),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                  child: TextField(
                controller: controller,
                enabled: !sending && !switchingMode && mode == 2,
                maxLines: 3,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(hintText: 'Write a reply…'),
              )),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Send reply',
                onPressed: sending || switchingMode || mode != 2 ? null : sendReply,
                icon: sending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send),
              ),
            ])),
      ])),
    );
  }
}
