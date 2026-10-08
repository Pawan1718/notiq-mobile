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
