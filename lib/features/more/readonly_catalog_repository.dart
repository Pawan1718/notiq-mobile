import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';

class ReadOnlyCatalogRepository {
  const ReadOnlyCatalogRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> _list(String path) async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      path,
      (data) => (data as List<dynamic>).map(
        (entry) => Map<String, dynamic>.from(entry as Map),
      ).toList(),
    );
    return response.data ?? const [];
  }

  Future<List<Map<String, dynamic>>> providers() =>
      _list('/api/communication/provider-settings');

  Future<List<Map<String, dynamic>>> templates() =>
      _list('/api/communication/templates?includeInactive=true');
}

final readOnlyCatalogRepositoryProvider = Provider<ReadOnlyCatalogRepository>(
  (ref) => ReadOnlyCatalogRepository(ref.read(apiClientProvider)),
);

final providerCatalogProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(readOnlyCatalogRepositoryProvider).providers(),
);

final templateCatalogProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(readOnlyCatalogRepositoryProvider).templates(),
);
