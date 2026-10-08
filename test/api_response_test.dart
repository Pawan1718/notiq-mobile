import 'package:flutter_test/flutter_test.dart';
import 'package:notiq_mobile/core/api/api_response.dart';
import 'package:notiq_mobile/core/auth/auth_models.dart';

void main() {
  test('ApiResponse reads existing Notiq envelope', () {
    final result = ApiResponse<String>.fromJson({
      'success': true, 'message': 'OK', 'data': 'ready',
      'errors': <String>[], 'traceId': 'trace',
    }, (x) => x as String);
    expect(result.success, isTrue);
    expect(result.data, 'ready');
    expect(result.traceId, 'trace');
  });

  test('Rejects non-tenant login sessions', () {
    expect(() => LoginSession.fromJson({
      'accessToken': 'example',
      'expiresAtUtc': '2099-01-01T00:00:00Z',
      'tenantId': null,
    }), throwsFormatException);
  });
}
