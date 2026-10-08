import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../api/api_client.dart';
import '../api/api_response.dart';
import 'auth_models.dart';
import 'secure_session_store.dart';

final sessionStoreProvider = Provider<SecureSessionStore>(
  (ref) => const SecureSessionStore(FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true))),
);
final apiClientProvider =
    Provider<ApiClient>((ref) => ApiClient(ref.read(sessionStoreProvider)));
final authProvider =
    AsyncNotifierProvider<AuthController, bool>(AuthController.new);

class AuthController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async =>
      (await ref.read(sessionStoreProvider).readValidToken()) != null;

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await ref.read(apiClientProvider).post<LoginSession>(
            '/api/auth/login',
            {'email': email.trim(), 'password': password},
            LoginSession.fromJson,
            anonymous: true,
          );
      final session = response.data;
      if (session == null) throw const ApiFailure('No session returned.');
      await ref.read(sessionStoreProvider).save(
            token: session.accessToken,
            expiresAt: session.expiresAtUtc,
            tenantId: session.tenantId,
          );
      return true;
    });
  }

  Future<void> logout() async {
    await ref.read(sessionStoreProvider).clear();
    state = const AsyncData(false);
  }
}
