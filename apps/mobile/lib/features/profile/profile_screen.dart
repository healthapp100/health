import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import 'consent_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'profile_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(ownProfileProvider);
    final dependentsAsync = ref.watch(dependentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) => ResponsiveContent(
          maxWidth: 600,
          child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 24,
                  child: Text(
                    (profile.fullName?.isNotEmpty ?? false)
                        ? profile.fullName![0].toUpperCase()
                        : '?',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                title: Text(
                  profile.fullName ?? 'Add your name',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(profile.phone ?? profile.email ?? ''),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditProfileScreen(profile: profile)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.family_restroom_outlined),
                    title: const Text('Family & dependents'),
                    subtitle: dependentsAsync.when(
                      data: (deps) => Text('${deps.length} linked'),
                      loading: () => const Text('Loading…'),
                      error: (e, _) => const Text('—'),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {}, // Dependent management screen — Phase 5+ per BLUEPRINT.md §6.
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: const Text('Privacy & consent'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ConsentSettingsScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Language'),
                    subtitle: Text(profile.locale),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {}, // Multilingual support — Phase 5+ per BLUEPRINT.md §5.1.
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                title: Text(
                  'Sign out',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/auth/phone');
                },
              ),
            ),
          ],
          ),
        ),
        loading: () => const Padding(
          padding: EdgeInsets.all(16),
          child: SkeletonList(count: 3),
        ),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}
