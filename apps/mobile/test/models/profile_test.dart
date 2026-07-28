import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_platform/models/enums.dart';
import 'package:healthcare_platform/models/profile.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses a full row from public.profiles', () {
      final profile = Profile.fromJson({
        'id': 'a1b2c3d4-0000-0000-0000-000000000000',
        'role': 'doctor',
        'full_name': 'Dr. Asha Rao',
        'phone': '+919876543210',
        'email': null,
        'locale': 'en-IN',
        'avatar_url': null,
        'created_at': '2026-01-15T10:00:00.000Z',
        'updated_at': '2026-01-15T10:00:00.000Z',
      });

      expect(profile.role, AppRole.doctor);
      expect(profile.fullName, 'Dr. Asha Rao');
      expect(profile.locale, 'en-IN');
    });

    test('defaults locale when the column is null', () {
      final profile = Profile.fromJson({
        'id': 'a1b2c3d4-0000-0000-0000-000000000000',
        'role': 'patient',
        'full_name': null,
        'phone': '+919876543210',
        'email': null,
        'locale': null,
        'avatar_url': null,
        'created_at': '2026-01-15T10:00:00.000Z',
        'updated_at': '2026-01-15T10:00:00.000Z',
      });

      expect(profile.locale, 'en-IN');
    });

    test('toUpdateJson omits null fullName/avatarUrl rather than overwriting with null', () {
      final profile = Profile(
        id: 'x',
        role: AppRole.patient,
        fullName: null,
        locale: 'hi-IN',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(profile.toUpdateJson().containsKey('full_name'), isFalse);
      expect(profile.toUpdateJson()['locale'], 'hi-IN');
    });
  });

  group('ProviderDirectoryEntry.fromJson', () {
    test('parses public.provider_directory row without credential fields', () {
      final entry = ProviderDirectoryEntry.fromJson({
        'profile_id': 'p1',
        'full_name': 'Dr. Vikram Shah',
        'role': 'doctor',
        'specialty': 'Endocrinology',
        'years_experience': 12,
      });

      expect(entry.role, AppRole.doctor);
      expect(entry.specialty, 'Endocrinology');
      expect(entry.yearsExperience, 12);
    });
  });

  group('CareRelationship', () {
    test('displayName falls back when dependentDisplayName is null', () {
      final relationship = CareRelationship.fromJson({
        'id': 'r1',
        'guardian_profile_id': 'g1',
        'dependent_profile_id': 'd1',
        'dependent_display_name': null,
        'relationship': 'child',
        'created_at': '2026-01-15T10:00:00.000Z',
      });

      expect(relationship.displayName, '(linked account)');
    });
  });
}
