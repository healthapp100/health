import 'enums.dart';

/// Mirrors public.profiles (supabase/migrations/0001_roles_and_profiles.sql).
class Profile {
  final String id;
  final AppRole role;
  final String? fullName;
  final String? phone;
  final String? email;
  final String locale;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.role,
    this.fullName,
    this.phone,
    this.email,
    this.locale = 'en-IN',
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        role: AppRole.fromWire(json['role'] as String),
        fullName: json['full_name'] as String?,
        phone: json['phone'] as String?,
        email: json['email'] as String?,
        locale: json['locale'] as String? ?? 'en-IN',
        avatarUrl: json['avatar_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toUpdateJson() => {
        if (fullName != null) 'full_name': fullName,
        'locale': locale,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      };
}

/// Mirrors public.provider_directory (supabase/migrations/0003_provider_verification.sql) —
/// the public-safe subset patients browse; never carries registration_number/document_url.
class ProviderDirectoryEntry {
  final String profileId;
  final String fullName;
  final AppRole role;
  final String? specialty;
  final int? yearsExperience;

  const ProviderDirectoryEntry({
    required this.profileId,
    required this.fullName,
    required this.role,
    this.specialty,
    this.yearsExperience,
  });

  factory ProviderDirectoryEntry.fromJson(Map<String, dynamic> json) => ProviderDirectoryEntry(
        profileId: json['profile_id'] as String,
        fullName: json['full_name'] as String,
        role: AppRole.fromWire(json['role'] as String),
        specialty: json['specialty'] as String?,
        yearsExperience: json['years_experience'] as int?,
      );
}

/// Mirrors public.care_relationships — a patient's dependent/family profiles (BLUEPRINT.md §5.1).
class CareRelationship {
  final String id;
  final String guardianProfileId;
  final String? dependentProfileId;
  final String? dependentDisplayName;
  final String relationship;
  final DateTime createdAt;

  const CareRelationship({
    required this.id,
    required this.guardianProfileId,
    this.dependentProfileId,
    this.dependentDisplayName,
    required this.relationship,
    required this.createdAt,
  });

  factory CareRelationship.fromJson(Map<String, dynamic> json) => CareRelationship(
        id: json['id'] as String,
        guardianProfileId: json['guardian_profile_id'] as String,
        dependentProfileId: json['dependent_profile_id'] as String?,
        dependentDisplayName: json['dependent_display_name'] as String?,
        relationship: json['relationship'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  String get displayName => dependentDisplayName ?? '(linked account)';
}
