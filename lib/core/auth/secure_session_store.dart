import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureSessionStore {
  const SecureSessionStore(this._storage);
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'notiq.access_token';
  static const _expiryKey = 'notiq.expires_at_utc';
  static const _tenantKey = 'notiq.tenant_id';

  Future<void> save(
      {required String token,
      required DateTime expiresAt,
      required int tenantId}) async {
    await clear();
    try {
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(
          key: _expiryKey, value: expiresAt.toUtc().toIso8601String());
      await _storage.write(key: _tenantKey, value: tenantId.toString());
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  Future<String?> readValidToken() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final expiry =
          DateTime.tryParse(await _storage.read(key: _expiryKey) ?? '');
      final tenantId = int.tryParse(await _storage.read(key: _tenantKey) ?? '');
      if (token == null ||
          token.isEmpty ||
          expiry == null ||
          !expiry.isAfter(DateTime.now().toUtc()) ||
          tenantId == null ||
          tenantId <= 0) {
        await clear();
        return null;
      }
      return token;
    } catch (_) {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiryKey);
    await _storage.delete(key: _tenantKey);
  }
}
