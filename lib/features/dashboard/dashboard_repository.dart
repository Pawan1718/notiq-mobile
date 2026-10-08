import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/api/api_client.dart';
import 'dashboard_models.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DashboardRepository(ref.read(apiClientProvider)),
);

class DashboardRepository {
  const DashboardRepository(this._api);
  final ApiClient _api;

  Future<DashboardMetrics> getMetrics() async {
    final response = await _api.get<DashboardMetrics>(
        '/api/communication/dashboard', DashboardMetrics.fromJson);
    final data = response.data;
    if (data == null) throw const FormatException('Dashboard data missing.');
    return data;
  }
}

final dashboardMetricsProvider = FutureProvider.autoDispose<DashboardMetrics>(
  (ref) => ref.read(dashboardRepositoryProvider).getMetrics(),
);
