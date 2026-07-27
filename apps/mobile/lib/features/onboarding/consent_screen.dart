import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import '../../models/consent_record.dart';

/// Implements docs/consent-flow-draft.md Screens 2 and 3 exactly: essential consent blocks
/// proceeding, optional consent never does (DPDP's "unconditional" requirement — BLUEPRINT.md
/// §3.1). Keep this screen's copy in sync with that doc if either changes.
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _acceptedTerms = false;
  bool _acceptedRoleDisclaimer = false;
  bool _shareWithProviders = false;
  bool _reminderComms = false;
  bool _marketingComms = false;
  bool _isSubmitting = false;

  bool get _canProceed => _acceptedTerms && _acceptedRoleDisclaimer;

  Future<void> _finish() async {
    setState(() => _isSubmitting = true);
    final consentService = ref.read(consentServiceProvider);
    try {
      await consentService.grant(ConsentType.termsOfService);
      await consentService.grant(ConsentType.platformRoleDisclaimer);
      if (_shareWithProviders) {
        await consentService.grant(ConsentType.healthDataSharingWithProvider);
      }
      if (_reminderComms) await consentService.grant(ConsentType.reminderComms);
      if (_marketingComms) await consentService.grant(ConsentType.marketingComms);

      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not save your preferences. $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Before we get started')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Essential', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acceptedTerms,
              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
              title: const Text('I’ve read and agree to the Terms of Service and Privacy Notice.'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acceptedRoleDisclaimer,
              onChanged: (v) => setState(() => _acceptedRoleDisclaimer = v ?? false),
              title: const Text(
                'I understand this app connects me with independent, licensed healthcare '
                'professionals and does not itself provide medical diagnosis or treatment.',
              ),
            ),
            const Divider(height: 32),
            Text('A couple of optional things', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _shareWithProviders,
              onChanged: (v) => setState(() => _shareWithProviders = v ?? false),
              title: const Text(
                'Share my health data with a doctor or coach only when I book a consultation '
                'with them.',
              ),
              subtitle: const Text('You can turn this off later, but you won’t be able to book calls without it.'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _reminderComms,
              onChanged: (v) => setState(() => _reminderComms = v ?? false),
              title: const Text('Send me appointment reminders and health tips by SMS/WhatsApp.'),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _marketingComms,
              onChanged: (v) => setState(() => _marketingComms = v ?? false),
              title: const Text('Send me occasional product updates and offers by email.'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _canProceed && !_isSubmitting ? _finish : null,
              child: _isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Finish setup'),
            ),
          ],
        ),
      ),
    );
  }
}
