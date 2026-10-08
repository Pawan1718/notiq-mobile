import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';
import 'inbox_models.dart';

const inboxBasePath = '/api/communication/webhooks/whatsapp/conversations';

final inboxRepositoryProvider = Provider<InboxRepository>(
  (ref) => InboxRepository(ref.read(apiClientProvider)),
);

class InboxRepository {
  const InboxRepository(this._api);
  final ApiClient _api;

  Future<InboxPageResult> conversations({int page = 1}) async {
    final response = await _api.get<InboxPageResult>(
      '$inboxBasePath?pageNumber=$page&pageSize=20',
      InboxPageResult.fromJson,
    );
    if (response.data == null) {
      throw const FormatException('Inbox data missing');
    }
    return response.data!;
  }

  Future<InboxMessage> reply(int id, String body) async {
    final response = await _api.mutate<InboxMessage>(
      '$inboxBasePath/$id/reply',
      'POST',
      InboxMessage.fromJson,
      payload: {'body': body},
    );
    if (response.data == null) {
      throw const FormatException('Reply data missing');
    }
    return response.data!;
  }

  Future<InboxConversation> markRead(int id) async {
    final response = await _api.mutate<InboxConversation>(
      '$inboxBasePath/$id/read',
      'PATCH',
      InboxConversation.fromJson,
    );
    if (response.data == null) {
      throw const FormatException('Read response missing');
    }
    return response.data!;
  }


  Future<List<InboxAssignee>> assignees() async {
    final response = await _api.get<List<InboxAssignee>>(
      '$inboxBasePath/assignees',
      (data) => (data as List<dynamic>)
          .map((value) => InboxAssignee.fromJson(value as Map<String, dynamic>)).toList(),
    );
    return response.data ?? const [];
  }

  Future<List<InboxTag>> tags() async {
    final response = await _api.get<List<InboxTag>>(
      '$inboxBasePath/tags',
      (data) => (data as List<dynamic>)
          .map((value) => InboxTag.fromJson(value as Map<String, dynamic>)).toList(),
    );
    return response.data ?? const [];
  }

  Future<List<InboxQuickReply>> quickReplies() async {
    final response = await _api.get<List<InboxQuickReply>>(
      '$inboxBasePath/quick-replies',
      (data) => (data as List<dynamic>)
          .map((value) => InboxQuickReply.fromJson(value as Map<String, dynamic>)).toList(),
    );
    return response.data ?? const [];
  }

  Future<InboxConversation> updateAssignment(int id, int? assignedUserId) =>
      _updateConversation(id, 'assignment', {'assignedUserId': assignedUserId});

  Future<InboxConversation> updateStatus(int id, int status) =>
      _updateConversation(id, 'status', {'status': status});

  Future<InboxConversation> updateMode(int id, int mode) =>
      _updateConversation(id, 'mode', {'mode': mode});

  Future<InboxConversation> updateTags(int id, List<int> tagIds) =>
      _updateConversation(id, 'tags', {'tagIds': tagIds});

  Future<InboxConversation> _updateConversation(
      int id, String path, Map<String, dynamic> payload) async {
    final response = await _api.mutate<InboxConversation>(
      '$inboxBasePath/$id/$path',
      'PUT',
      InboxConversation.fromJson,
      payload: payload,
    );
    if (response.data == null) {
      throw const FormatException('Conversation update response missing');
    }
    return response.data!;
  }

  Future<List<InboxMessage>> messages(int id) async {
    final response = await _api.get<List<InboxMessage>>(
      '$inboxBasePath/$id/messages',
      (data) => (data as List<dynamic>).map(InboxMessage.fromJson).toList(),
    );
    if (response.data == null) throw const FormatException('Messages missing');
    return response.data!;
  }
}

final inboxPageProvider =
    FutureProvider.autoDispose.family<InboxPageResult, int>(
  (ref, page) => ref.read(inboxRepositoryProvider).conversations(page: page),
);

final inboxMessagesProvider =
    FutureProvider.autoDispose.family<List<InboxMessage>, int>(
  (ref, id) => ref.read(inboxRepositoryProvider).messages(id),
);

final inboxAssigneesProvider = FutureProvider.autoDispose<List<InboxAssignee>>(
  (ref) => ref.read(inboxRepositoryProvider).assignees(),
);
final inboxTagsProvider = FutureProvider.autoDispose<List<InboxTag>>(
  (ref) => ref.read(inboxRepositoryProvider).tags(),
);
final inboxQuickRepliesProvider = FutureProvider.autoDispose<List<InboxQuickReply>>(
  (ref) => ref.read(inboxRepositoryProvider).quickReplies(),
);
