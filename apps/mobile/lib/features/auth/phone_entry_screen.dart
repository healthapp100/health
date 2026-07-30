import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import 'auth_contact.dart';

/// Phone+OTP is the intended primary login (BLUEPRINT.md §2.3), but sending real SMS requires a
/// DLT-registered Indian SMS aggregator, which needs its own business/compliance setup — see
/// AuthService.sendEmailOtp's doc comment. Until that's wired up, email OTP is offered as an
/// equally real (not mocked) way to sign in and exercise the rest of the auth/RLS flow, via a
/// toggle rather than removing the phone option entirely — it's still the target default.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

enum _Channel { phone, email }

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  _Channel _channel = _Channel.phone;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  String? _toE164(String raw) {
    final digitsOnly = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length == 10) return '+91$digitsOnly';
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) return '+$digitsOnly';
    return null;
  }

  bool _isValidEmail(String raw) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(raw.trim());
  }

  Future<void> _submitPhone() async {
    final phoneE164 = _toE164(_phoneController.text);
    if (phoneE164 == null) {
      setState(() => _errorText = 'Enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authServiceProvider).sendPhoneOtp(phoneE164);
      if (!mounted) return;
      context.push('/auth/verify', extra: AuthContact.phone(phoneE164));
    } catch (e) {
      setState(() => _errorText = 'Could not send OTP. $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitEmail() async {
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _errorText = 'Enter a valid email address');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authServiceProvider).sendEmailOtp(email);
      if (!mounted) return;
      context.push('/auth/verify', extra: AuthContact.email(email));
    } catch (e) {
      setState(() => _errorText = 'Could not send code. $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = _channel == _Channel.phone;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Welcome', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                isPhone
                    ? "We'll text you a one-time code to sign in."
                    : "We'll email you a one-time code to sign in.",
              ),
              const SizedBox(height: 16),
              SegmentedButton<_Channel>(
                segments: const [
                  ButtonSegment(value: _Channel.phone, label: Text('Phone'), icon: Icon(Icons.phone_outlined)),
                  ButtonSegment(value: _Channel.email, label: Text('Email'), icon: Icon(Icons.email_outlined)),
                ],
                selected: {_channel},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (s) => setState(() {
                          _channel = s.first;
                          _errorText = null;
                        }),
              ),
              const SizedBox(height: 16),
              if (isPhone)
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  autofocus: true,
                  decoration: InputDecoration(
                    prefixText: '+91 ',
                    labelText: 'Mobile number',
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _submitPhone(),
                )
              else
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _submitEmail(),
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : (isPhone ? _submitPhone : _submitEmail),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send code'),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          await ref.read(authServiceProvider).signInWithGoogleOAuth();
                        },
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Continue with Google'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
