import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _appearanceKey = 'notiq.appearance';

final themeModeProvider =
    AsyncNotifierProvider<ThemeModeController, ThemeMode>(
        ThemeModeController.new);

class ThemeModeController extends AsyncNotifier<ThemeMode> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<ThemeMode> build() async {
    try {
      final value = await _storage.read(key: _appearanceKey);
      if (value == 'dark') return ThemeMode.dark;
      if (value == 'light') return ThemeMode.light;
    } catch (_) {
      // Device storage might be temporarily inaccessible.
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    try {
      await _storage.write(key: _appearanceKey, value: mode.name);
    } catch (_) {
      // Keep this preference for the current process even if persistence fails.
    }
  }
}
