import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

class ProfileService {
  final SupabaseClient _client;
  const ProfileService(this._client);

  Future<Profile> getOwnProfile() async {
    final userId = _client.auth.currentUser!.id;
    final row = await _client.from('profiles').select().eq('id', userId).single();
    return Profile.fromJson(row);
  }

  Future<void> updateOwnProfile(Profile profile) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('profiles').update(profile.toUpdateJson()).eq('id', userId);
  }

  /// Public-safe directory (supabase/migrations/0003) — deliberately excludes
  /// registration_number/document_url. Used by the Care tab's "book a provider" flow.
  Future<List<ProviderDirectoryEntry>> getVerifiedProviders({String? roleFilter}) async {
    var query = _client.from('provider_directory').select();
    if (roleFilter != null) {
      query = query.eq('role', roleFilter);
    }
    final rows = await query.order('full_name');
    return (rows as List<dynamic>)
        .map((r) => ProviderDirectoryEntry.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<CareRelationship>> getDependents() async {
    final userId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('care_relationships')
        .select()
        .eq('guardian_profile_id', userId)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((r) => CareRelationship.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> addDependent({
    required String displayName,
    required String relationship,
    String? dependentProfileId,
  }) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('care_relationships').insert({
      'guardian_profile_id': userId,
      'dependent_display_name': displayName,
      'relationship': relationship,
      if (dependentProfileId != null) 'dependent_profile_id': dependentProfileId,
    });
  }
}
