/// Carries which channel the OTP was sent through, so OtpVerifyScreen can call the matching
/// verify method — passed via go_router's `extra` from PhoneEntryScreen to OtpVerifyScreen.
class AuthContact {
  final String value;
  final bool isEmail;

  const AuthContact.phone(this.value) : isEmail = false;
  const AuthContact.email(this.value) : isEmail = true;
}
