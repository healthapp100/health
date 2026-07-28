import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_platform/models/enums.dart';

/// These round-trip checks exist because the wire values are hand-typed against the Postgres
/// enum labels in supabase/migrations — a typo here silently breaks every query/insert using
/// that enum, with no compile-time signal.
void main() {
  group('AppRole', () {
    for (final role in AppRole.values) {
      test('${role.name} round-trips through wire value', () {
        expect(AppRole.fromWire(role.wireValue), role);
      });
    }

    test('wire values match supabase/migrations/0001 app_role labels', () {
      expect(AppRole.labStaff.wireValue, 'lab_staff');
      expect(AppRole.superAdmin.wireValue, 'super_admin');
    });

    test('isStaff is false only for patient', () {
      expect(AppRole.patient.isStaff, isFalse);
      expect(AppRole.doctor.isStaff, isTrue);
      expect(AppRole.support.isStaff, isTrue);
    });

    test('fromWire throws on unknown value', () {
      expect(() => AppRole.fromWire('not_a_role'), throwsArgumentError);
    });
  });

  group('AppointmentStatus', () {
    for (final status in AppointmentStatus.values) {
      test('${status.name} round-trips through wire value', () {
        expect(AppointmentStatus.fromWire(status.wireValue), status);
      });
    }

    test('wire values match supabase/migrations/0004 appointment_status labels', () {
      expect(AppointmentStatus.inProgress.wireValue, 'in_progress');
      expect(AppointmentStatus.noShow.wireValue, 'no_show');
    });
  });

  group('LabOrderStatus', () {
    for (final status in LabOrderStatus.values) {
      test('${status.name} round-trips through wire value', () {
        expect(LabOrderStatus.fromWire(status.wireValue), status);
      });
    }

    test('wire values match supabase/migrations/0005 lab_order_status labels', () {
      expect(LabOrderStatus.sampleCollected.wireValue, 'sample_collected');
      expect(LabOrderStatus.inLab.wireValue, 'in_lab');
    });
  });

  group('VitalSource', () {
    for (final source in VitalSource.values) {
      test('${source.name} round-trips through wire value', () {
        expect(VitalSource.fromWire(source.wireValue), source);
      });
    }
  });

  group('AppointmentMode', () {
    for (final mode in AppointmentMode.values) {
      test('${mode.name} round-trips through wire value', () {
        expect(AppointmentMode.fromWire(mode.wireValue), mode);
      });
    }
  });
}
