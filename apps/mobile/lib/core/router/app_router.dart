import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_shell.dart';
import '../../features/admin/blogs/admin_blogs_screen.dart';
import '../../features/admin/learn_cms/admin_learn_topics_screen.dart';
import '../../features/admin/seminars/admin_seminars_screen.dart';
import '../../features/admin/services/admin_services_screen.dart';
import '../../features/auth/auth_contact.dart';
import '../../features/auth/otp_verify_screen.dart';
import '../../features/auth/phone_entry_screen.dart';
import '../../features/care/care_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/labs/labs_screen.dart';
import '../../features/learn/article_detail_screen.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/learn/learn_topics_tab.dart';
import '../../features/learn/subtopic_content_screen.dart';
import '../../features/onboarding/consent_screen.dart';
import '../../features/profile/profile_providers.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/services/daily_videos_screen.dart';
import '../../features/services/health_kits_screen.dart';
import '../../features/services/lab_directory_screen.dart';
import '../../features/services/medicines_screen.dart';
import '../../features/services/monitoring_messages_screen.dart';
import '../../features/services/services_home_screen.dart';
import '../../features/track/track_screen.dart';
import '../../models/enums.dart';
import '../supabase/supabase_client.dart';
import 'scaffold_with_nav.dart';

/// StatefulShellRoute keeps each of the 5 bottom-nav tabs' own navigation stack alive when
/// switching tabs (ARCHITECTURE.md §Navigation shell) — the specific go_router feature that
/// motivated choosing it over alternatives (pubspec.yaml's reasoning).
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// A gentle fade+slide-up replaces go_router's default (an abrupt platform-default push, which
/// on Flutter Web is a hard cut) for the handful of routes reached by explicit navigation
/// (verify code, consent, article detail, lab tests) — the shell's 5 tab destinations
/// intentionally do NOT use this, since StatefulShellRoute's IndexedStack switch is instant by
/// design and animating it would fight the "keep each tab's stack alive" behavior.
CustomTransitionPage<void> _fadeSlidePage(Widget child) {
  return CustomTransitionPage<void>(
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final signedInAtBuild = authState.valueOrNull?.session != null ||
      ref.read(supabaseClientProvider).auth.currentSession != null;
  // Only watch the profile once actually signed in — ownProfileProvider calls
  // `auth.currentUser!.id`, which throws on a null user, so watching it unconditionally would
  // crash router construction on a cold, signed-out start. Watching (not reading) here means the
  // router rebuilds — and redirect() re-runs — the moment the profile finishes loading, so an
  // admin isn't stuck on the patient shell just because their role wasn't known yet at the first
  // navigation attempt.
  if (signedInAtBuild) {
    ref.watch(ownProfileProvider);
  }

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    redirect: (context, state) {
      final signedIn = authState.valueOrNull?.session != null ||
          ref.read(supabaseClientProvider).auth.currentSession != null;
      final onAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation.startsWith('/onboarding');
      final onAdminRoute = state.matchedLocation.startsWith('/admin');

      if (!signedIn && !onAuthRoute) return '/auth/phone';
      if (!signedIn) return null;

      AppRole? role;
      final profileState = ref.read(ownProfileProvider);
      role = profileState.valueOrNull?.role;
      final isAdmin = role == AppRole.admin || role == AppRole.superAdmin;

      if (onAuthRoute) return isAdmin ? '/admin' : '/home';
      if (isAdmin && !onAdminRoute) return '/admin';
      if (!isAdmin && onAdminRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/auth/phone', builder: (context, state) => const PhoneEntryScreen()),
      GoRoute(
        path: '/auth/verify',
        pageBuilder: (context, state) => _fadeSlidePage(
          OtpVerifyScreen(contact: state.extra as AuthContact? ?? const AuthContact.phone('')),
        ),
      ),
      GoRoute(
        path: '/onboarding/consent',
        pageBuilder: (context, state) => _fadeSlidePage(const ConsentScreen()),
      ),
      GoRoute(
        path: '/learn/article/:slug',
        pageBuilder: (context, state) =>
            _fadeSlidePage(ArticleDetailScreen(slug: state.pathParameters['slug']!)),
      ),
      GoRoute(
        path: '/learn/topic/:topicId',
        pageBuilder: (context, state) => _fadeSlidePage(
          TopicSubtopicListScreen(topicId: state.pathParameters['topicId']!),
        ),
      ),
      GoRoute(
        path: '/learn/topic/:topicId/:subtopicId',
        pageBuilder: (context, state) => _fadeSlidePage(
          SubtopicContentScreen(
            topicId: state.pathParameters['topicId']!,
            subtopicId: state.pathParameters['subtopicId']!,
          ),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/admin', builder: (context, state) => const AdminHomeScreen()),
          GoRoute(
            path: '/admin/learn',
            builder: (context, state) => const AdminLearnTopicsScreen(),
          ),
          GoRoute(
            path: '/admin/blogs',
            builder: (context, state) => const AdminBlogsScreen(),
          ),
          GoRoute(
            path: '/admin/seminars',
            builder: (context, state) => const AdminSeminarsScreen(),
          ),
          GoRoute(
            path: '/admin/services',
            builder: (context, state) => const AdminServicesScreen(),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => ScaffoldWithNav(shell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/care', builder: (context, state) => const CareScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/learn', builder: (context, state) => const LearnScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/track', builder: (context, state) => const TrackScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
            ],
          ),
        ],
      ),
      GoRoute(path: '/labs', pageBuilder: (context, state) => _fadeSlidePage(const LabsScreen())),
      GoRoute(
        path: '/services',
        pageBuilder: (context, state) => _fadeSlidePage(const ServicesHomeScreen()),
      ),
      GoRoute(
        path: '/services/monitoring',
        pageBuilder: (context, state) => _fadeSlidePage(const MonitoringMessagesScreen()),
      ),
      GoRoute(
        path: '/services/videos',
        pageBuilder: (context, state) => _fadeSlidePage(const DailyVideosScreen()),
      ),
      GoRoute(
        path: '/services/labs-directory',
        pageBuilder: (context, state) => _fadeSlidePage(const LabDirectoryScreen()),
      ),
      GoRoute(
        path: '/services/health-kits',
        pageBuilder: (context, state) => _fadeSlidePage(const HealthKitsScreen()),
      ),
      GoRoute(
        path: '/services/medicines',
        pageBuilder: (context, state) => _fadeSlidePage(const MedicinesScreen()),
      ),
    ],
  );
});
