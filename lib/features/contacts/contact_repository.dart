import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/api/api_client.dart';
import 'contact_models.dart';

const contactsPath = '/api/communication/contacts';

final contactRepositoryProvider = Provider<ContactRepository>(
  (ref) => ContactRepository(ref.read(apiClientProvider)),
);

class ContactRepository {
  const ContactRepository(this.api);
  final ApiClient api;
  Future<List<Map<String,dynamic>>> lookup(String type) async {
    final response = await api.get<List<Map<String,dynamic>>>(
      '$contactsPath/$type',
      (data) => (data as List<dynamic>).map((v) => Map<String,dynamic>.from(v as Map)).toList(),
    );
    return response.data ?? [];
  }

  Future<void> createLookup(String type, Map<String,dynamic> payload) async {
    await api.mutate<Object?>('$contactsPath/$type', 'POST', (v) => v, payload: payload);
  }

  Future<Map<String,dynamic>> importContacts(Map<String,dynamic> payload,
      {required bool confirm}) async {
    final result = await api.mutate<Map<String,dynamic>>(
      '$contactsPath/import/mobile-${confirm ? 'confirm' : 'preview'}',
      'POST', (v) => Map<String,dynamic>.from(v as Map), payload: payload,
    );
    if (result.data == null) throw const FormatException('Import response missing');
    return result.data!;
  }

  Future<ContactPage> list({int page = 1, String search = ''}) async {
    final query = Uri(queryParameters: {
      'pageNumber': '$page',
      'pageSize': '20',
      if (search.trim().isNotEmpty) 'search': search.trim(),
    }).query;
    final result = await api.get<ContactPage>(
        '$contactsPath?$query', ContactPage.fromJson);
    if (result.data == null) {
      throw const FormatException('Contact list missing');
    }
    return result.data!;
  }

  Future<ContactDetail> detail(int id) async {
    final result = await api.get<ContactDetail>(
        '$contactsPath/$id', ContactDetail.fromJson);
    if (result.data == null) throw const FormatException('Contact missing');
    return result.data!;
  }

  Future<void> save(Map<String, dynamic> payload, {int? id}) async {
    await api.mutate<ContactItem>(
        id == null ? contactsPath : '$contactsPath/$id',
        id == null ? 'POST' : 'PUT',
        ContactItem.fromJson,
        payload: payload);
  }
}

final contactListProvider =
    FutureProvider.autoDispose.family<ContactPage, ({int page, String search})>(
  (ref, filter) => ref
      .read(contactRepositoryProvider)
      .list(page: filter.page, search: filter.search),
);
final contactDetailProvider =
    FutureProvider.autoDispose.family<ContactDetail, int>(
  (ref, id) => ref.read(contactRepositoryProvider).detail(id),
);

final contactGroupsProvider = FutureProvider.autoDispose<List<Map<String,dynamic>>>(
 (ref) => ref.read(contactRepositoryProvider).lookup('groups'));
final contactTagsProvider = FutureProvider.autoDispose<List<Map<String,dynamic>>>(
 (ref) => ref.read(contactRepositoryProvider).lookup('tags'));
