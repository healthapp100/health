import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';
import 'auth_contact.dart';

/// Phone+OTP is the intended primary login (BLUEPRINT.md §2.3), but sending real SMS requires a
/// DLT-registered Indian SMS aggregator, which needs its own business/compliance setup — see
/// AuthService.sendEmailOtp's doc comment. Email OTP and Email+Password are offered as equally
/// real (not mocked) ways to sign in and exercise the rest of the auth/RLS flow via a toggle,
/// rather than removing the phone option entirely — it's still the target default.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

enum _Channel { phone, email, password }

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  _Channel _channel = _Channel.phone;
  bool _isSignUp = false;
  bool _isSubmitting = false;
  String? _errorText;
  String? _infoText;

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordEmailController.dispose();
    _passwordController.dispose();
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

  Future<void> _submitPassword() async {
    final email = _passwordEmailController.text.trim();
    final password = _passwordController.text;
    if (!_isValidEmail(email)) {
      setState(() {
        _errorText = 'Enter a valid email address';
        _infoText = null;
      });
      return;
    }
    if (password.length < 6) {
      setState(() {
        _errorText = 'Password must be at least 6 characters';
        _infoText = null;
      });
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
      _infoText = null;
    });
    try {
      final authService = ref.read(authServiceProvider);
      if (_isSignUp) {
        final response = await authService.signUpWithPassword(email: email, password: password);
        if (!mounted) return;
        if (response.session == null) {
          // Supabase's "Confirm email" setting is on — no session yet until the user clicks the
          // link mailed to them, so there's nothing to redirect into.
          setState(() {
            _infoText = 'Check $email for a confirmation link, then sign in.';
            _isSignUp = false;
          });
          return;
        }
        await _goPastAuth();
      } else {
        await authService.signInWithPassword(email: email, password: password);
        if (!mounted) return;
        await _goPastAuth();
      }
    } catch (e) {
      setState(() => _errorText = _isSignUp ? 'Could not create account. $e' : 'Could not sign in. $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // Mirrors OtpVerifyScreen's post-verification redirect: a brand-new user has no
  // consent_records rows yet, so route them to consent first (docs/consent-flow-draft.md).
  Future<void> _goPastAuth() async {
    final hasEssential = await ref.read(consentServiceProvider).hasEssentialConsent();
    if (!mounted) return;
    context.go(hasEssential ? '/home' : '/onboarding/consent');
  }

  @override
  Widget build(BuildContext context) {
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
              Text(switch (_channel) {
                _Channel.phone => "We'll text you a one-time code to sign in.",
                _Channel.email => "We'll email you a one-time code to sign in.",
                _Channel.password =>
                  _isSignUp ? 'Create an account with email and password.' : 'Sign in with your email and password.',
              },),
              const SizedBox(height: 16),
              SegmentedButton<_Channel>(
                segments: const [
                  ButtonSegment(value: _Channel.phone, label: Text('Phone'), icon: Icon(Icons.phone_outlined)),
                  ButtonSegment(value: _Channel.email, label: Text('Email'), icon: Icon(Icons.email_outlined)),
                  ButtonSegment(value: _Channel.password, label: Text('Password'), icon: Icon(Icons.lock_outline)),
                ],
                selected: {_channel},
                onSelectionChanged: _isSubmitting
                    ? null
                    : (s) => setState(() {
                          _channel = s.first;
                          _errorText = null;
                          _infoText = null;
                        }),
              ),
              const SizedBox(height: 16),
              if (_channel == _Channel.phone)
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
              else if (_channel == _Channel.email)
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Email address',
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _submitEmail(),
                )
              else ...[
                TextField(
                  controller: _passwordEmailController,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Email address'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    errorText: _errorText,
                    helperText: _infoText,
                  ),
                  onSubmitted: (_) => _submitPassword(),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _errorText = null;
                              _infoText = null;
                            }),
                    child: Text(_isSignUp ? 'Already have an account? Sign in' : 'New here? Create an account'),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting
                      ? null
                      : switch (_channel) {
                          _Channel.phone => _submitPhone,
                          _Channel.email => _submitEmail,
                          _Channel.password => _submitPassword,
                        },
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(switch (_channel) {
                          _Channel.phone => 'Send code',
                          _Channel.email => 'Send code',
                          _Channel.password => _isSignUp ? 'Create account' : 'Sign in',
                        },),
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
