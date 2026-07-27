/// Mirrors public.consent_records (supabase/migrations/0006_consent_and_audit.sql) — the DPDP
/// consent trail. Matches docs/consent-flow-draft.md's per-toggle consent_type strings exactly;
/// keep those two in sync if either changes.
class ConsentRecord {
  final String id;
  final String profileId;
  final String consentType;
  final String policyVersion;
  final bool granted;
  final DateTime? grantedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;

  const ConsentRecord({
    required this.id,
    required this.profileId,
    required this.consentType,
    required this.policyVersion,
    required this.granted,
    this.grantedAt,
    this.revokedAt,
    required this.createdAt,
  });

  factory ConsentRecord.fromJson(Map<String, dynamic> json) => ConsentRecord(
        id: json['id'] as String,
        profileId: json['profile_id'] as String,
        consentType: json['consent_type'] as String,
        policyVersion: json['policy_version'] as String,
        granted: json['granted'] as bool,
        grantedAt:
            json['granted_at'] != null ? DateTime.parse(json['granted_at'] as String) : null,
        revokedAt:
            json['revoked_at'] != null ? DateTime.parse(json['revoked_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// consent_type string constants — docs/consent-flow-draft.md §Screen 2/3 defines these exactly.
class ConsentType {
  ConsentType._();
  static const termsOfService = 'terms_of_service';
  static const platformRoleDisclaimer = 'platform_role_disclaimer';
  static const healthDataSharingWithProvider = 'health_data_sharing_with_provider';
  static const reminderComms = 'reminder_comms';
  static const marketingComms = 'marketing_comms';

  static const essential = [termsOfService, platformRoleDisclaimer];
  static const optional = [healthDataSharingWithProvider, reminderComms, marketingComms];
}
