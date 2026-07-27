import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/otp_verify_screen.dart';
import '../../features/auth/phone_entry_screen.dart';
import '../../features/care/care_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/labs/labs_screen.dart';
import '../../features/learn/article_detail_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/onboarding/consent_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/track/track_screen.dart';
import '../supabase/supabase_client.dart';
import 'scaffold_with_nav.dart';

/// StatefulShellRoute keeps each of the 5 bottom-nav tabs' own navigation stack alive when
/// switching tabs (ARCHITECTURE.md §Navigation shell) — the specific go_router feature that
/// motivated choosing it over alternatives (pubspec.yaml's reasoning).
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final signedIn = authState.valueOrNull?.session != null ||
          ref.read(supabaseClientProvider).auth.currentSession != null;
      final onAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation.startsWith('/onboarding');

      if (!signedIn && !onAuthRoute) return '/auth/phone';
      if (signedIn && state.matchedLocation.startsWith('/auth')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/phone', builder: (context, state) => const PhoneEntryScreen()),
      GoRoute(
        path: '/auth/verify',
        builder: (context, state) => OtpVerifyScreen(
          phoneE164: state.extra as String? ?? '',
        ),
      ),
      GoRoute(path: '/onboarding/consent', builder: (context, state) => const ConsentScreen()),
      GoRoute(
        path: '/learn/article/:slug',
        builder: (context, state) => ArticleDetailScreen(slug: state.pathParameters['slug']!),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ScaffoldWithNav(shell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/care', builder: (context, state) => const CareScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/learn', builder: (context, state) => const LearnScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
          ]),
        ],
      ),
      GoRoute(path: '/labs', builder: (context, state) => const LabsScreen()),
    ],
  );
});
