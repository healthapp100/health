import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/consent_record.dart';

/// Implements docs/consent-flow-draft.md exactly: each consent is its own row, granting writes
/// a fresh row rather than mutating history, and withdrawal writes a new revoked row rather than
/// deleting — preserving the audit trail DPDP expects (BLUEPRINT.md §3.1).
class ConsentService {
  final SupabaseClient _client;

  /// Bump this when the Terms of Service / Privacy Notice changes materially — every consent
  /// write is stamped with the version in effect at grant time. Keep in sync with the actual
  /// published policy version (docs/privacy-notice-draft.md).
  static const currentPolicyVersion = '2026-07-27-draft';

  const ConsentService(this._client);

  String get _profileId => _client.auth.currentUser!.id;

  Future<void> grant(String consentType) async {
    await _client.from('consent_records').insert({
      'profile_id': _profileId,
      'consent_type': consentType,
      'policy_version': currentPolicyVersion,
      'granted': true,
      'granted_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> revoke(String consentType) async {
    await _client.from('consent_records').insert({
      'profile_id': _profileId,
      'consent_type': consentType,
      'policy_version': currentPolicyVersion,
      'granted': false,
      'revoked_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Latest known state per consent_type (most recent row wins) — drives both the onboarding
  /// screen's initial checkbox state and the Settings → Privacy toggle list.
  Future<Map<String, bool>> getCurrentConsentState() async {
    final rows = await _client
        .from('consent_records')
        .select()
        .eq('profile_id', _profileId)
        .order('created_at', ascending: false);
    final records = (rows as List<dynamic>)
        .map((r) => ConsentRecord.fromJson(r as Map<String, dynamic>))
        .toList();
    final latestByType = <String, bool>{};
    for (final record in records) {
      latestByType.putIfAbsent(record.consentType, () => record.granted);
    }
    return latestByType;
  }

  Future<bool> hasEssentialConsent() async {
    final state = await getCurrentConsentState();
    return ConsentType.essential.every((type) => state[type] == true);
  }
}
