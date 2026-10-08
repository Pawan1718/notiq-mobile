import 'package:flutter_test/flutter_test.dart';
import 'package:notiq_mobile/features/dashboard/dashboard_models.dart';

void main() {
  test('Dashboard metrics match existing React API contract', () {
    final result = DashboardMetrics.fromJson({
      'total': 10, 'pending': 2, 'scheduled': 1, 'sent': 6,
      'failed': 1, 'retriableFailed': 1,
    });
    expect(result.total, 10);
    expect(result.sent, 6);
  });
  test('Missing metrics are rejected rather than mocked', () {
    expect(() => DashboardMetrics.fromJson({'total': 1}),
      throwsFormatException);
  });
}
