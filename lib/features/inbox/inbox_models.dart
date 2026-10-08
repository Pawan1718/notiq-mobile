class InboxConversation {
  const InboxConversation(
      {required this.id,
      required this.contactName,
      required this.phoneNumber,
      required this.preview,
      required this.unreadCount, required this.status, required this.mode, required this.assignedUserId, required this.assignedUserName, required this.tags, required this.lastMessageAtUtc});
  final int id;
  final String contactName;
  final String phoneNumber;
  final String preview;
  final int unreadCount;
  final int status;
  final int mode;
  final int? assignedUserId;
  final String? assignedUserName;
  final List<InboxTag> tags;
  final DateTime? lastMessageAtUtc;

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
      status: (data['status'] as num?)?.toInt() ?? 1,
      mode: (data['mode'] as num?)?.toInt() ?? 1,
      assignedUserId: (data['assignedUserId'] as num?)?.toInt(),
      assignedUserName: data['assignedUserName']?.toString(),
      tags: ((data['tags'] as List<dynamic>?) ?? const []).map((v) => InboxTag.fromJson(v as Map<String, dynamic>)).toList(),
      lastMessageAtUtc: DateTime.tryParse(data['lastMessageAtUtc']?.toString() ?? ''),
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
      {required this.id, required this.content, required this.direction, this.createdAt, this.status, this.messageType = ''});
  final int id;
  final String content;
  final Object? direction;
  final DateTime? createdAt;
  final Object? status;
  final String messageType;
  factory InboxMessage.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid message');
    }
    return InboxMessage(
      id: (data['id'] as num).toInt(),
      content: data['content']?.toString() ?? '',
      direction: data['direction'],
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
      status: data['status'],
      messageType: data['messageType']?.toString() ?? '',
    );
  }
}

class InboxTag {
  const InboxTag({required this.id, required this.name});
  final int id;
  final String name;
  factory InboxTag.fromJson(Map<String, dynamic> data) => InboxTag(
    id: (data['id'] as num).toInt(),
    name: data['name']?.toString() ?? '',
  );
}

class InboxAssignee {
  const InboxAssignee({required this.id, required this.name});
  final int id;
  final String name;
  factory InboxAssignee.fromJson(Map<String, dynamic> data) => InboxAssignee(
    id: (data['id'] as num).toInt(),
    name: data['name']?.toString() ?? '',
  );
}

class InboxQuickReply {
  const InboxQuickReply({required this.id, required this.title, required this.body});
  final int id;
  final String title;
  final String body;
  factory InboxQuickReply.fromJson(Map<String, dynamic> data) => InboxQuickReply(
    id: (data['id'] as num).toInt(),
    title: data['title']?.toString() ?? '',
    body: data['body']?.toString() ?? '',
  );
}
