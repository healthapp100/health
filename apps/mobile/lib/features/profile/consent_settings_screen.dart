import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/consent_record.dart';
import 'profile_providers.dart';

/// Withdrawal path from docs/consent-flow-draft.md §Withdrawal: essential consents prompt a
/// deactivation confirmation instead of silently doing nothing (DPDP requires withdrawal be as
/// easy as granting, but an accidental toggle shouldn't silently disable the account either).
class ConsentSettingsScreen extends ConsumerWidget {
  const ConsentSettingsScreen({super.key});

  static const _labels = {
    ConsentType.termsOfService: 'Terms of Service & Privacy Notice',
    ConsentType.platformRoleDisclaimer: 'Platform role disclaimer',
    ConsentType.healthDataSharingWithProvider: 'Share health data with providers I consult',
    ConsentType.reminderComms: 'Appointment & health reminders (SMS/WhatsApp)',
    ConsentType.marketingComms: 'Product updates & offers (email)',
  };

  Future<void> _handleToggle(
    BuildContext context,
    WidgetRef ref,
    String consentType,
    bool newValue,
  ) async {
    final isEssential = ConsentType.essential.contains(consentType);
    if (isEssential && !newValue) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('This will deactivate your account'),
          content: Text(
            'You can’t use the app without agreeing to "${_labels[consentType]}". '
            'Withdrawing this consent means we’ll deactivate your account rather than '
            'silently removing access to features.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Withdraw & deactivate'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final consentService = ref.read(consentServiceProvider);
    if (newValue) {
      await consentService.grant(consentType);
    } else {
      await consentService.revoke(consentType);
    }
    ref.invalidate(consentStateProvider);

    if (isEssential && !newValue && context.mounted) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final consentStateAsync = ref.watch(consentStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & consent')),
      body: consentStateAsync.when(
        data: (state) => ListView(
          children: [
            ..._labels.entries.map((entry) {
              final granted = state[entry.key] ?? false;
              return SwitchListTile(
                title: Text(entry.value),
                value: granted,
                onChanged: (v) => _handleToggle(context, ref, entry.key, v),
              );
            }),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'See our full Privacy Notice for details on what we collect, why, and how to '
                'request access, correction, or erasure of your data.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}
