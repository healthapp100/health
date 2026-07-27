import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/service_providers.dart';

class OtpVerifyScreen extends ConsumerStatefulWidget {
  final String phoneE164;
  const OtpVerifyScreen({super.key, required this.phoneE164});

  @override
  ConsumerState<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends ConsumerState<OtpVerifyScreen> {
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otpController.text.trim().length < 4) {
      setState(() => _errorText = 'Enter the code you received');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });
    try {
      await ref.read(authServiceProvider).verifyPhoneOtp(
            phoneE164: widget.phoneE164,
            otp: _otpController.text.trim(),
          );
      if (!mounted) return;
      // Screen 2/3 of docs/consent-flow-draft.md is required before the app is usable — a
      // brand-new user has no consent_records rows yet, so route them there first.
      final hasEssential = await ref.read(consentServiceProvider).hasEssentialConsent();
      if (!mounted) return;
      context.go(hasEssential ? '/home' : '/onboarding/consent');
    } catch (e) {
      setState(() => _errorText = 'Incorrect or expired code. $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Enter the code', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Sent to ${widget.phoneE164}'),
              const SizedBox(height: 24),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(labelText: 'OTP', errorText: _errorText),
                onSubmitted: (_) => _verify(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _verify,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isSubmitting
                    ? null
                    : () => ref.read(authServiceProvider).sendPhoneOtp(widget.phoneE164),
                child: const Text('Resend code'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
