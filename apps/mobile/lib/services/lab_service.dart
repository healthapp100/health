import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lab.dart';

/// Laboratory Test Support (public.lab_orders / public.lab_results) — booking is staff-managed
/// (see RLS in supabase/migrations/0005: patients can read, only staff insert/update orders),
/// so this service is read-only from the patient app's perspective, plus the results vault read.
class LabService {
  final SupabaseClient _client;
  const LabService(this._client);

  String get _patientId => _client.auth.currentUser!.id;

  Future<List<LabOrder>> getOwnOrders() async {
    final rows = await _client
        .from('lab_orders')
        .select()
        .eq('patient_id', _patientId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((r) => LabOrder.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// The "digital health-records vault" (BLUEPRINT.md §4.3) — persistent results, not just
  /// one-off booking artifacts.
  Future<List<LabResult>> getOwnResults() async {
    final rows = await _client
        .from('lab_results')
        .select()
        .eq('patient_id', _patientId)
        .order('reported_at', ascending: false);
    return (rows as List<dynamic>).map((r) => LabResult.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Live views so a lab-staff status update (sample collected → in lab → reported) or a new
  /// result upload reaches the patient without a manual refresh.
  Stream<List<LabOrder>> watchOwnOrders() {
    return _client
        .from('lab_orders')
        .stream(primaryKey: ['id'])
        .eq('patient_id', _patientId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(LabOrder.fromJson).toList());
  }

  Stream<List<LabResult>> watchOwnResults() {
    return _client
        .from('lab_results')
        .stream(primaryKey: ['id'])
        .eq('patient_id', _patientId)
        .order('reported_at', ascending: false)
        .map((rows) => rows.map(LabResult.fromJson).toList());
  }
}
