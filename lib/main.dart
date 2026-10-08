import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/notiq_theme.dart';
import 'core/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    ApiConfig.validate();
    runApp(const ProviderScope(child: NotiqApp()));
  } on StateError catch (error) {
    // A configuration error must not leave Android showing its native splash.
    runApp(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.settings_outlined, size: 48),
                  const SizedBox(height: 16),
                  const Text('Notiq cannot start',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(error.message.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text('Configure API_BASE_URL with --dart-define and restart the app.',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

class NotiqApp extends ConsumerWidget {
  const NotiqApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
        title: 'Notiq',
        debugShowCheckedModeBanner: false,
        theme: NotiqTheme.light(),
        darkTheme: NotiqTheme.darkTheme(),
        themeMode: ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.system,
        routerConfig: ref.watch(routerProvider),
      );
}
