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

  /// Email OTP — available to any user, not just staff. Originally added for the staff-only
  /// magic-link path (BLUEPRINT.md §2.3, avoids SMS cost for non-patient-facing auth); now also
  /// used as the patient-facing login method until a DLT-registered SMS aggregator is set up for
  /// phone OTP (that needs Indian telecom compliance work, tracked separately — see
  /// PhoneEntryScreen). Whether this delivers a clickable link or a typed code depends on the
  /// "Magic Link" email template configured in the Supabase dashboard, not this client code.
  Future<void> sendEmailOtp(String email) {
    return _client.auth.signInWithOtp(email: email);
  }

  /// Verifies the code from [sendEmailOtp] when the dashboard's email template sends a token
  /// (not a link) — mirrors [verifyPhoneOtp] but for the email/OtpType.email channel.
  Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String otp,
  }) {
    return _client.auth.verifyOTP(
      email: email,
      token: otp,
      type: OtpType.email,
    );
  }

  /// Creates a new account with email+password. Supabase's "Confirm email" setting (dashboard →
  /// Authentication → Providers → Email) gates sign-in until the user clicks the confirmation
  /// link sent to [email] — same verification principle as OTP, just a one-time check instead of
  /// every login.
  Future<AuthResponse> signUpWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signUp(email: email, password: password);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> resetPasswordForEmail(String email) {
    return _client.auth.resetPasswordForEmail(email);
  }

  /// Supabase's `AuthChangeEvent.signedOut` fires both when the user taps "Sign out" AND when a
  /// token refresh fails (session actually expired) — the SDK gives no way to tell them apart
  /// from the event alone. This flag lets whoever calls [signOut] mark the next `signedOut` event
  /// as intentional, so the app-wide listener (main.dart) only shows a "session expired" message
  /// for the unexpected case.
  static bool _expectedSignOut = false;
  static bool consumeExpectedSignOut() {
    final was = _expectedSignOut;
    _expectedSignOut = false;
    return was;
  }

  Future<void> signOut() {
    _expectedSignOut = true;
    return _client.auth.signOut();
  }
}
