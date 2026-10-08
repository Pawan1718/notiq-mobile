import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_controller.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/inbox/inbox_page.dart';
import '../../features/contacts/contacts_page.dart';
import '../../features/campaigns/campaigns_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen(authProvider, (_, __) => notifier.value++);
  ref.onDispose(() {
    notifier.dispose();
  });
  final router = GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loggedIn = auth.valueOrNull == true;
      final atLogin = state.matchedLocation == '/login';
      if (auth.isLoading && auth.valueOrNull == null) return '/loading';
      if (!loggedIn && !atLogin) return '/login';
      if (loggedIn && (atLogin || state.matchedLocation == '/loading')) {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(
          path: '/loading',
          builder: (_, __) =>
              const Scaffold(body: Center(child: CircularProgressIndicator()))),
      GoRoute(path: '/login', builder: (_, __) => const LoginPage()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardPage()),
      GoRoute(path: '/inbox', builder: (_, __) => const InboxPage()),
      GoRoute(path: '/contacts', builder: (_, __) => const ContactsPage()),
      GoRoute(path: '/campaigns', builder: (_, __) => const CampaignsPage()),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
