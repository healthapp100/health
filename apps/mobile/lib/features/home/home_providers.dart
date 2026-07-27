import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/appointment.dart';
import '../../models/vital.dart';

/// Dashboard data — BLUEPRINT.md §4.4: present the care loop (appointments, monitoring calls,
/// recent vitals) at a glance rather than as disconnected tabs the user has to go find.
final upcomingAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  return ref.watch(appointmentServiceProvider).watchOwnAppointments();
});

final upcomingMonitoringCallsProvider = StreamProvider.autoDispose<List<MonitoringCall>>((ref) {
  return ref.watch(appointmentServiceProvider).watchOwnMonitoringCalls();
});

final latestVitalsProvider =
    FutureProvider.autoDispose.family<Vital?, String>((ref, metricType) {
  return ref.watch(vitalsServiceProvider).getLatest(metricType);
});
