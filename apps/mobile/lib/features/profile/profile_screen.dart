import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/state_widgets.dart';
import 'consent_settings_screen.dart';
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
        data: (profile) => ListView(
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(profile.fullName ?? 'Add your name'),
              subtitle: Text(profile.phone ?? profile.email ?? ''),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.family_restroom_outlined),
              title: const Text('Family & dependents'),
              subtitle: dependentsAsync.when(
                data: (deps) => Text('${deps.length} linked'),
                loading: () => const Text('Loading…'),
                error: (e, _) => const Text('—'),
              ),
              onTap: () {}, // Dependent management screen — Phase 5+ per BLUEPRINT.md §6.
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy & consent'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConsentSettingsScreen()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: const Text('Language'),
              subtitle: Text(profile.locale),
              onTap: () {}, // Multilingual support — Phase 5+ per BLUEPRINT.md §5.1.
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
              title: Text('Sign out', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () async {
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) context.go('/auth/phone');
              },
            ),
          ],
        ),
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}
