import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vital.dart';

/// Health Data Monitoring (public.vitals). Plain-Postgres time-series per BLUEPRINT.md §2.2 —
/// no TimescaleDB needed at this scale; queries below are simple range scans on an indexed
/// (patient_id, recorded_at) column pair (see supabase/migrations/0005's vitals_patient_recorded_idx).
class VitalsService {
  final SupabaseClient _client;
  const VitalsService(this._client);

  String get _patientId => _client.auth.currentUser!.id;

  Future<Vital> logVital({
    required String metricType,
    required double value,
    required String unit,
    required VitalSource source,
    DateTime? recordedAt,
  }) async {
    final vital = Vital(
      id: '',
      patientId: _patientId,
      metricType: metricType,
      value: value,
      unit: unit,
      source: source,
      recordedAt: recordedAt ?? DateTime.now(),
    );
    final row =
        await _client.from('vitals').insert(vital.toInsertJson(_patientId)).select().single();
    return Vital.fromJson(row);
  }

  /// Trend data for a chart — BLUEPRINT.md §4.4 wants this presented as part of one integrated
  /// log→insight→coach-call loop, not an isolated table.
  Future<List<Vital>> getTrend(String metricType, {int days = 90}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await _client
        .from('vitals')
        .select()
        .eq('patient_id', _patientId)
        .eq('metric_type', metricType)
        .gte('recorded_at', since.toUtc().toIso8601String())
        .order('recorded_at');
    return (rows as List<dynamic>).map((r) => Vital.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Vital?> getLatest(String metricType) async {
    final rows = await _client
        .from('vitals')
        .select()
        .eq('patient_id', _patientId)
        .eq('metric_type', metricType)
        .order('recorded_at', ascending: false)
        .limit(1);
    final list = rows as List<dynamic>;
    return list.isEmpty ? null : Vital.fromJson(list.first as Map<String, dynamic>);
  }
}
