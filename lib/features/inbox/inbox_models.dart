class InboxConversation {
  const InboxConversation(
      {required this.id,
      required this.contactName,
      required this.phoneNumber,
      required this.preview,
      required this.unreadCount, required this.mode});
  final int id;
  final String contactName;
  final String phoneNumber;
  final String preview;
  final int unreadCount;
  /// Backend ConversationMode: Bot=1, Human=2.
  final int mode;

  factory InboxConversation.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid conversation');
    }
    return InboxConversation(
      id: (data['id'] as num).toInt(),
      contactName: data['contactName']?.toString() ?? '',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      preview: data['lastMessagePreview']?.toString() ?? '',
      unreadCount: (data['unreadCount'] as num?)?.toInt() ?? 0,
      mode: data['mode'] is num ? (data['mode'] as num).toInt() :
          (data['mode']?.toString().toLowerCase() == 'human' ? 2 : 1),
    );
  }
}

class InboxPageResult {
  const InboxPageResult({required this.items, required this.totalPages});
  final List<InboxConversation> items;
  final int totalPages;
  factory InboxPageResult.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid inbox page');
    }
    return InboxPageResult(
      items: (data['items'] as List<dynamic>)
          .map(InboxConversation.fromJson)
          .toList(),
      totalPages: (data['totalPages'] as num).toInt(),
    );
  }
}

class InboxMessage {
  const InboxMessage(
      {required this.id, required this.content, required this.direction, this.senderType, this.status});
  final int id;
  final String content;
  final Object? direction;
  final Object? senderType;
  final Object? status;
  factory InboxMessage.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid message');
    }
    return InboxMessage(
      id: (data['id'] as num).toInt(),
      content: data['content']?.toString() ?? '',
      direction: data['direction'],
      senderType: data['senderType'],
      status: data['status'],
    );
  }
}
