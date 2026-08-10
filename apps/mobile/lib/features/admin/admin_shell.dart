import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/responsive.dart';
import '../profile/profile_providers.dart';

/// Root of the admin/staff-facing side of the app — reached automatically after login when
/// `profiles.role` is 'admin'/'super_admin' (see app_router.dart's redirect). Deliberately the
/// *same* Flutter app/binary as the patient experience rather than a separate project: it reuses
/// the existing auth, Supabase client, and theme wiring, and the real security boundary is
/// Supabase RLS (is_admin()), not which app happens to render the button — a second app would add
/// deployment overhead without adding any access control that isn't already enforced server-side.
///
/// Sections beyond the dashboard land here as later phases (Learn CMS, Blogs, Seminars, Services)
/// are built — this phase establishes the shell, the redirect, and sign-out.
class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _sections = [
    (Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', '/admin'),
    (Icons.menu_book_outlined, Icons.menu_book, 'Learn', '/admin/learn'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _sections.indexWhere((s) => s.$4 == location).clamp(0, _sections.length - 1);

    if (isCompact(context)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Admin'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => _signOut(context, ref),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(child: Text('Admin sections')),
              for (final (icon, selectedIcon, label, path) in _sections)
                ListTile(
                  leading: Icon(path == location ? selectedIcon : icon),
                  title: Text(label),
                  selected: path == location,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(path);
                  },
                ),
            ],
          ),
        ),
        body: child,
      );
    }

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (i) => context.go(_sections[i].$4),
            destinations: [
              for (final (icon, selectedIcon, label, _) in _sections)
                NavigationRailDestination(
                  icon: Icon(icon),
                  selectedIcon: Icon(selectedIcon),
                  label: Text(label),
                ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: IconButton(
                    icon: const Icon(Icons.logout),
                    tooltip: 'Sign out',
                    onPressed: () => _signOut(context, ref),
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    await ref.read(authServiceProvider).signOut();
    if (context.mounted) context.go('/auth/phone');
  }
}

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);

    return ResponsiveContent(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            profileAsync.when(
              data: (profile) => Text(
                'Welcome, ${profile.fullName ?? profile.email ?? 'Admin'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const SizedBox(height: 32),
              error: (e, _) => Text('$e'),
            ),
            const SizedBox(height: 8),
            Text(
              'Content management sections (Learn, Blogs, Seminars, Services) land here as '
              'each is built.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
