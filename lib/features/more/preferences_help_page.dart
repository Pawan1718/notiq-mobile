import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
);
const _themeKey = 'notiq.mobile.appearance';

final appThemeModeProvider =
    AsyncNotifierProvider<AppThemeModeController, ThemeMode>(
  AppThemeModeController.new,
);

class AppThemeModeController extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final value = await _storage.read(key: _themeKey);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    await _storage.write(key: _themeKey, value: mode.name);
    state = AsyncData(mode);
  }
}

class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appThemeModeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: current.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: TextButton(
          onPressed: () => ref.invalidate(appThemeModeProvider),
          child: const Text('Unable to load preferences. Retry'),
        )),
        data: (mode) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final option in ThemeMode.values)
              ListTile(
                leading: Icon(option == mode
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
                title: Text(switch (option) {
                  ThemeMode.system => 'Use device setting',
                  ThemeMode.light => 'Light',
                  ThemeMode.dark => 'Dark',
                }),
                onTap: () async {
                  try {
                    await ref.read(appThemeModeProvider.notifier).setMode(option);
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not save preference')),
                      );
                    }
                  }
                },
              ),
            const SizedBox(height: 16),
            const Text('Appearance is saved on this device.'),
          ],
        ),
      ),
    );
  }
}

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Help & support')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Need help?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        const ListTile(
          leading: Icon(Icons.sync_problem_outlined),
          title: Text('Connection problem'),
          subtitle: Text('Check your network and retry the screen.'),
        ),
        const Divider(height: 1),
        const ListTile(
          leading: Icon(Icons.shield_outlined),
          title: Text('Access denied'),
          subtitle: Text('Some workspace data requires Owner or Admin access.'),
        ),
        const Divider(height: 1),
        const ListTile(
          leading: Icon(Icons.help_outline),
          title: Text('Advanced settings'),
          subtitle: Text('Use Notiq Web for configuration and administration.'),
        ),
        const SizedBox(height: 16),
        const SelectableText(
          'Project documentation: https://github.com/Pawan1718/Notiq',
        ),
      ],
    ),
  );
}
