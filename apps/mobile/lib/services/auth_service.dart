import 'package:supabase_flutter/supabase_flutter.dart';

/// Phone+OTP (primary) and Google Sign-In (secondary) — BLUEPRINT.md §2.3. Actual OTP SMS
/// delivery is routed server-side through an Indian DLT-registered aggregator via a Supabase
/// Auth Hook (configured in the Supabase dashboard, not in this client code) — this service just
/// calls the standard Supabase phone-auth API either way.
class AuthService {
  final SupabaseClient _client;
  const AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  /// Sends an OTP to [phoneE164] (e.g. "+919876543210"). Throws [AuthException] on failure
  /// (invalid number, rate-limited, etc.) — callers should catch and show `error.message`.
  Future<void> sendPhoneOtp(String phoneE164) {
    return _client.auth.signInWithOtp(phone: phoneE164);
  }

  /// Verifies the OTP the user typed in. On success, Supabase's `on_auth_user_created` trigger
  /// (supabase/migrations/0002) creates the matching `profiles` row automatically.
  Future<AuthResponse> verifyPhoneOtp({
    required String phoneE164,
    required String otp,
  }) {
    return _client.auth.verifyOTP(
      phone: phoneE164,
      token: otp,
      type: OtpType.sms,
    );
  }

  /// Google Sign-In secondary path. On native platforms this expects the platform-specific
  /// Google Sign-In SDK to already have produced [idToken]/[accessToken] (wiring that up is a
  /// platform-folder-specific step, done once `flutter create` backfills android/ios — see
  /// ARCHITECTURE.md). On Flutter Web, Supabase's OAuth redirect flow is used instead via
  /// [signInWithGoogleOAuth].
  Future<AuthResponse> signInWithGoogleIdToken({
    required String idToken,
    String? accessToken,
  }) {
    return _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  Future<bool> signInWithGoogleOAuth() {
    return _client.auth.signInWithOAuth(OAuthProvider.google);
  }

  /// Email + magic link — staff-side auth only (doctors/nutritionists/lab staff/admins),
  /// per BLUEPRINT.md §2.3: avoids SMS cost for the non-patient-facing side of the platform.
  Future<void> sendMagicLink(String email) {
    return _client.auth.signInWithOtp(email: email);
  }

  Future<void> signOut() => _client.auth.signOut();
}
