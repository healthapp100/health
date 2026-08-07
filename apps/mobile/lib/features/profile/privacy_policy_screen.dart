import 'package:flutter/material.dart';

/// Renders docs/privacy-notice-draft.md content in-app — required for Play Store/App Store
/// listing (both require a reachable privacy policy). The source doc is explicitly marked DRAFT,
/// pending lawyer review and company-detail placeholders (BLUEPRINT.md §3.1) — the banner below
/// carries that status into the app rather than silently presenting placeholder legal text
/// (`[COMPANY LEGAL NAME]` etc.) as if it were final and reviewed.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.onErrorContainer, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Draft — pending legal review. Company registration details, the Grievance '
                    'Officer contact, and data-retention periods below are still placeholders.',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _Section(
            title: '1. Who we are',
            body: '[Company legal name], a company registered in India ([registration details]), '
                'operates this app (the "Platform"). For any privacy question or to exercise your '
                'rights below, contact our Grievance Officer at [Grievance Officer name / email / '
                'address].',
          ),
          const _Section(
            title: '2. What we collect, and why',
            body: 'We only collect what a specific feature you use needs:\n\n'
                '• Name, phone number — to identify your account and contact you (Login, appointments)\n'
                '• Health information you enter (vitals, symptoms, meal logs) — to show you your own '
                'health trends and share them with a provider you choose to consult\n'
                '• Lab results you upload or that a partner lab sends us — to store your reports in '
                'one place and let a doctor you consult see them\n'
                '• Wearable/device data (if you connect one) — to display synced metrics alongside '
                'your manually logged data\n'
                '• Call/appointment metadata (not call recordings, unless separately disclosed) — to '
                'schedule and remind you about consultations\n'
                '• Payment reference (not full card/UPI details — handled by our payment processor) — '
                'to confirm a subscription or paid consultation\n\n'
                'We do not sell your health data or use it for advertising.',
          ),
          const _Section(
            title: '3. Your consent',
            body: 'We ask for your specific, informed, freely-given consent before collecting '
                'anything beyond what\'s strictly needed to create your account. Consent for '
                'anything not essential to your care (e.g. marketing messages) is never a condition '
                'of using the core Platform. You can withdraw consent at any time from Profile → '
                'Privacy & consent, as easily as you gave it — if you withdraw consent needed for a '
                'feature, we\'ll tell you which features stop working.',
          ),
          const _Section(
            title: '4. Your rights',
            body: 'You have the right to:\n\n'
                '• Access a copy of the personal data we hold about you\n'
                '• Correct inaccurate data\n'
                '• Erase your data, subject to records we\'re legally required to keep (e.g. a '
                'consultation record your doctor is obligated to retain)\n'
                '• Nominate someone to exercise these rights on your behalf if you\'re incapacitated '
                'or deceased\n'
                '• File a grievance with our Grievance Officer, and afterward with the Data '
                'Protection Board of India if unresolved\n\n'
                'To exercise any of these, go to Profile → Privacy & consent, or email '
                '[privacy email]. We will respond within [X] days.',
          ),
          const _Section(
            title: '5. Where your data is stored',
            body: 'Your data is stored on servers located in Mumbai, India. We do not transfer your '
                'data outside India except [any third-party processor that isn\'t India-hosted, if '
                'any], which we only use to the extent needed to operate the Platform and under '
                'contractual data-protection obligations.',
          ),
          const _Section(
            title: '6. How long we keep your data',
            body: '[Retention periods per data type — e.g. consultation records per Telemedicine '
                'Practice Guidelines record-keeping expectations, vitals/logs for as long as your '
                'account is active plus a defined grace period, audit logs for a defined compliance '
                'period.]',
          ),
          const _Section(
            title: '7. If something goes wrong',
            body: 'If we become aware of a personal data breach affecting you, we will notify the '
                'Data Protection Board of India and you, without delay, as required under the DPDP '
                'Rules 2025.',
          ),
          const _Section(
            title: '8. This app is not a medical device',
            body: 'This app provides educational content and connects you with independently '
                'licensed doctors and healthcare professionals. It does not itself diagnose, treat, '
                'or prevent any medical condition, and is not a substitute for professional medical '
                'advice. In an emergency, call [local emergency number] or go to the nearest '
                'hospital.',
          ),
          const _Section(
            title: '9. Changes to this notice',
            body: 'We\'ll tell you in-app before any material change takes effect, and ask for '
                'fresh consent where the change affects how we use data you\'ve already given us.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
