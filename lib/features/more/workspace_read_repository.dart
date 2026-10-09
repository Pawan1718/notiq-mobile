import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/auth/auth_controller.dart';

class WorkspaceReadRepository {
  const WorkspaceReadRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> team() async {
    final result = await _api.get<List<Map<String, dynamic>>>(
      '/api/team/users',
      (v) => (v as List<dynamic>)
          .map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
    return result.data ?? const [];
  }

  Future<Map<String, dynamic>> subscription() async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/saas/subscriptions/current',
      (v) => Map<String, dynamic>.from(v as Map),
    );
    if (result.data == null) throw const FormatException('Subscription unavailable');
    return result.data!;
  }

  Future<Map<String, dynamic>> cost() async {
    final result = await _api.get<Map<String, dynamic>>(
      '/api/communication/cost-tracking',
      (v) => Map<String, dynamic>.from(v as Map),
    );
    if (result.data == null) throw const FormatException('Cost report unavailable');
    return result.data!;
  }
}

final workspaceReadRepositoryProvider = Provider<WorkspaceReadRepository>(
  (ref) => WorkspaceReadRepository(ref.read(apiClientProvider)),
);
final workspaceTeamProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.read(workspaceReadRepositoryProvider).team(),
);
final workspaceSubscriptionProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(workspaceReadRepositoryProvider).subscription(),
);
final workspaceCostProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.read(workspaceReadRepositoryProvider).cost(),
);
