import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/profile.dart';
import 'consent_settings_screen.dart';
import 'dependents_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'profile_providers.dart';

/// Language codes shown in the picker → display label. Persisted to `profiles.locale` now so
/// the preference is captured; actual UI translation (flutter_localizations + .arb string
/// tables for every screen) is a separate, much larger effort not yet built — this stores the
/// preference correctly rather than pretending the app already speaks these languages.
const _supportedLocales = {
  'en-IN': 'English',
  'hi-IN': 'हिन्दी (Hindi)',
  'ta-IN': 'தமிழ் (Tamil)',
  'te-IN': 'తెలుగు (Telugu)',
  'kn-IN': 'ಕನ್ನಡ (Kannada)',
  'bn-IN': 'বাংলা (Bengali)',
  'mr-IN': 'मराठी (Marathi)',
};

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
                  backgroundImage:
                      profile.avatarUrl != null ? NetworkImage(profile.avatarUrl!) : null,
                  child: profile.avatarUrl == null
                      ? Text(
                          (profile.fullName?.isNotEmpty ?? false)
                              ? profile.fullName![0].toUpperCase()
                              : '?',
                          style: Theme.of(context).textTheme.titleLarge,
                        )
                      : null,
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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DependentsScreen()),
                    ),
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
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Privacy policy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.language_outlined),
                    title: const Text('Language'),
                    subtitle: Text(_supportedLocales[profile.locale] ?? profile.locale),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguagePicker(context, ref, profile),
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

  Future<void> _showLanguagePicker(BuildContext context, WidgetRef ref, Profile profile) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Preferred language', style: Theme.of(context).textTheme.titleLarge),
            ),
            for (final entry in _supportedLocales.entries)
              ListTile(
                title: Text(entry.value),
                trailing: entry.key == profile.locale
                    ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null || picked == profile.locale || !context.mounted) return;
    try {
      await ref.read(profileServiceProvider).updateOwnProfile(
            Profile(
              id: profile.id,
              role: profile.role,
              fullName: profile.fullName,
              phone: profile.phone,
              email: profile.email,
              locale: picked,
              avatarUrl: profile.avatarUrl,
              createdAt: profile.createdAt,
              updatedAt: profile.updatedAt,
            ),
          );
      ref.invalidate(ownProfileProvider);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save. $e')));
    }
  }
}
