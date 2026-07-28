import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_platform/models/appointment.dart';
import 'package:healthcare_platform/models/consent_record.dart';
import 'package:healthcare_platform/models/enums.dart';

void main() {
  group('Appointment', () {
    test('fromJson parses a public.appointments row', () {
      final appointment = Appointment.fromJson({
        'id': 'a1',
        'patient_id': 'p1',
        'provider_id': 'doc1',
        'scheduled_at': '2026-08-01T04:30:00.000Z',
        'mode': 'video',
        'status': 'confirmed',
        'reason': 'Follow-up',
        'notes': null,
        'call_room_id': null,
        'created_at': '2026-07-20T08:30:00.000Z',
      });

      expect(appointment.mode, AppointmentMode.video);
      expect(appointment.status, AppointmentStatus.confirmed);
    });

    test('toInsertJson never includes patient-set status (server defaults to requested)', () {
      final appointment = Appointment(
        id: '',
        patientId: 'p1',
        providerId: 'doc1',
        scheduledAt: DateTime.utc(2026, 8, 1, 4, 30),
        mode: AppointmentMode.audio,
        status: AppointmentStatus.requested,
        createdAt: DateTime.utc(2026, 7, 20),
      );

      final json = appointment.toInsertJson();
      expect(json.containsKey('status'), isFalse);
      expect(json['mode'], 'audio');
    });
  });

  group('MonitoringCall', () {
    test('fromJson parses a public.monitoring_calls row', () {
      final call = MonitoringCall.fromJson({
        'id': 'm1',
        'patient_id': 'p1',
        'coach_id': 'coach1',
        'scheduled_at': '2026-08-01T04:30:00.000Z',
        'status': 'requested',
        'notes': null,
        'escalated_to_appointment_id': null,
        'created_at': '2026-07-20T08:30:00.000Z',
      });

      expect(call.status, AppointmentStatus.requested);
      expect(call.escalatedToAppointmentId, isNull);
    });
  });

  group('ConsentType', () {
    test('essential and optional lists are disjoint', () {
      final overlap = ConsentType.essential.toSet().intersection(ConsentType.optional.toSet());
      expect(overlap, isEmpty);
    });

    test('essential list matches docs/consent-flow-draft.md Screen 2', () {
      expect(ConsentType.essential, [
        ConsentType.termsOfService,
        ConsentType.platformRoleDisclaimer,
      ]);
    });
  });
}
