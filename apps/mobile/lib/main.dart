import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';
import 'core/supabase/supabase_client.dart';
import 'core/theme/app_theme.dart';
import 'services/auth_service.dart';

/// Shown app-wide (not tied to any one screen's BuildContext) so a session expiring while the
/// user is mid-flow on any screen still surfaces a message, instead of them just silently
/// landing back on the login screen with no explanation.
final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Loads apps/mobile/.env (gitignored — copy from .env.example, see README.md §Setup).
  await dotenv.load(fileName: '.env');

  await Supabase.initialize(
    url: dotenv.get('SUPABASE_URL'),
    publishableKey: dotenv.get('SUPABASE_ANON_KEY'),
  );

  runApp(const ProviderScope(child: HealthcarePlatformApp()));
}

class HealthcarePlatformApp extends ConsumerWidget {
  const HealthcarePlatformApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // The router's own redirect already sends a signed-out user back to /auth/phone (see
    // app_router.dart) — this listener adds the missing piece: telling them *why*, distinguishing
    // an expired session from the user's own "Sign out" tap via AuthService.consumeExpectedSignOut.
    ref.listen(authStateChangesProvider, (previous, next) {
      final event = next.valueOrNull?.event;
      if (event == AuthChangeEvent.signedOut && !AuthService.consumeExpectedSignOut()) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Your session expired — please sign in again.')),
        );
      }
    });

    return MaterialApp.router(
      scaffoldMessengerKey: _scaffoldMessengerKey,
      title: 'Healthcare Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
