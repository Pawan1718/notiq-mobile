import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/api/api_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/notiq_theme.dart';
import 'core/theme/theme_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.validate();
  runApp(const ProviderScope(child: NotiqApp()));
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
