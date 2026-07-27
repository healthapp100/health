import 'enums.dart';

/// Mirrors public.appointments (supabase/migrations/0004_care_delivery.sql) — the Doctor Calls
/// module. BLUEPRINT.md §3.2: `notes` is the RMP's consultation record; the platform stores it
/// but does not generate clinical content into it.
class Appointment {
  final String id;
  final String patientId;
  final String providerId;
  final DateTime scheduledAt;
  final AppointmentMode mode;
  final AppointmentStatus status;
  final String? reason;
  final String? notes;
  final String? callRoomId;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.providerId,
    required this.scheduledAt,
    required this.mode,
    required this.status,
    this.reason,
    this.notes,
    this.callRoomId,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        providerId: json['provider_id'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        mode: AppointmentMode.fromWire(json['mode'] as String),
        status: AppointmentStatus.fromWire(json['status'] as String),
        reason: json['reason'] as String?,
        notes: json['notes'] as String?,
        callRoomId: json['call_room_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson() => {
        'patient_id': patientId,
        'provider_id': providerId,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'mode': mode.wireValue,
        if (reason != null) 'reason': reason,
      };
}

/// Mirrors public.monitoring_calls — Daily Monitoring Calls. Kept as a separate model/table from
/// Appointment on purpose: BLUEPRINT.md §3.5 requires this stay non-diagnostic wellness coaching,
/// structurally distinct from an RMP consultation. `escalatedToAppointmentId` is the only bridge
/// between the two, used when a coach needs to hand a patient off to a doctor.
class MonitoringCall {
  final String id;
  final String patientId;
  final String coachId;
  final DateTime scheduledAt;
  final AppointmentStatus status;
  final String? notes;
  final String? escalatedToAppointmentId;
  final DateTime createdAt;

  const MonitoringCall({
    required this.id,
    required this.patientId,
    required this.coachId,
    required this.scheduledAt,
    required this.status,
    this.notes,
    this.escalatedToAppointmentId,
    required this.createdAt,
  });

  factory MonitoringCall.fromJson(Map<String, dynamic> json) => MonitoringCall(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        coachId: json['coach_id'] as String,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        status: AppointmentStatus.fromWire(json['status'] as String),
        notes: json['notes'] as String?,
        escalatedToAppointmentId: json['escalated_to_appointment_id'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
