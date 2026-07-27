import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/appointment.dart';
import '../../models/profile.dart';

final ownAppointmentsProvider = StreamProvider.autoDispose<List<Appointment>>((ref) {
  return ref.watch(appointmentServiceProvider).watchOwnAppointments();
});

final ownMonitoringCallsStreamProvider = StreamProvider.autoDispose<List<MonitoringCall>>((ref) {
  return ref.watch(appointmentServiceProvider).watchOwnMonitoringCalls();
});

/// Verified providers only — never the raw provider_credentials table (BLUEPRINT.md §3.2 due
/// diligence + the RLS design in supabase/migrations/0003 that hides registration_number/
/// document_url from patients).
final verifiedDoctorsProvider = FutureProvider.autoDispose<List<ProviderDirectoryEntry>>((ref) {
  return ref.watch(profileServiceProvider).getVerifiedProviders(roleFilter: 'doctor');
});

final verifiedNutritionistsProvider = FutureProvider.autoDispose<List<ProviderDirectoryEntry>>((ref) {
  return ref.watch(profileServiceProvider).getVerifiedProviders(roleFilter: 'nutritionist');
});
