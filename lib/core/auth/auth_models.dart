class LoginSession {
  const LoginSession(
      {required this.accessToken,
      required this.expiresAtUtc,
      required this.tenantId,
      required this.name,
      required this.email});

  final String accessToken;
  final DateTime expiresAtUtc;
  final int tenantId;
  final String name;
  final String email;

  factory LoginSession.fromJson(Object? data) {
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Invalid login response.');
    }
    final tenantId = (data['tenantId'] as num?)?.toInt();
    final token = data['accessToken'] as String?;
    final expires = DateTime.tryParse(data['expiresAtUtc']?.toString() ?? '');
    if (tenantId == null ||
        tenantId <= 0 ||
        token == null ||
        token.isEmpty ||
        expires == null ||
        !expires.isAfter(DateTime.now().toUtc())) {
      throw const FormatException('Tenant session is missing or expired.');
    }
    return LoginSession(
        accessToken: token,
        expiresAtUtc: expires.toUtc(),
        tenantId: tenantId,
        name: data['name']?.toString() ?? '',
        email: data['email']?.toString() ?? '');
  }
}
