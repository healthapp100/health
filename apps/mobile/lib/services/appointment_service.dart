import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/appointment.dart';
import '../models/enums.dart';

/// Doctor Calls (public.appointments) and Daily Monitoring Calls (public.monitoring_calls) —
/// kept as two methods sets on one service since both are "book a call with a named provider",
/// but never blur the two tables together (BLUEPRINT.md §3.5 scope boundary).
class AppointmentService {
  final SupabaseClient _client;
  const AppointmentService(this._client);

  String get _patientId => _client.auth.currentUser!.id;

  Stream<List<Appointment>> watchOwnAppointments() {
    return _client
        .from('appointments')
        .stream(primaryKey: ['id'])
        .eq('patient_id', _patientId)
        .order('scheduled_at')
        .map((rows) => rows.map(Appointment.fromJson).toList());
  }

  Future<Appointment> bookAppointment({
    required String providerId,
    required DateTime scheduledAt,
    required AppointmentMode mode,
    String? reason,
  }) async {
    final draft = Appointment(
      id: '',
      patientId: _patientId,
      providerId: providerId,
      scheduledAt: scheduledAt,
      mode: mode,
      status: AppointmentStatus.requested,
      reason: reason,
      createdAt: DateTime.now(),
    );
    final row =
        await _client.from('appointments').insert(draft.toInsertJson()).select().single();
    return Appointment.fromJson(row);
  }

  Future<void> cancelAppointment(String appointmentId) async {
    await _client
        .from('appointments')
        .update({'status': AppointmentStatus.cancelled.wireValue})
        .eq('id', appointmentId)
        .eq('patient_id', _patientId);
  }

  Stream<List<MonitoringCall>> watchOwnMonitoringCalls() {
    return _client
        .from('monitoring_calls')
        .stream(primaryKey: ['id'])
        .eq('patient_id', _patientId)
        .order('scheduled_at')
        .map((rows) => rows.map(MonitoringCall.fromJson).toList());
  }

  Future<void> cancelMonitoringCall(String callId) async {
    await _client
        .from('monitoring_calls')
        .update({'status': AppointmentStatus.cancelled.wireValue})
        .eq('id', callId)
        .eq('patient_id', _patientId);
  }
}
