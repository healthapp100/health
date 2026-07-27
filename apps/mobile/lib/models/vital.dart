import 'enums.dart';

/// Mirrors public.vitals (supabase/migrations/0005_vitals_and_labs.sql) — Health Data Monitoring.
/// `metricType` is a free-text tag (e.g. 'blood_glucose', 'systolic_bp', 'weight_kg') rather
/// than an enum, matching the table's design (new metric types shouldn't need a migration).
class Vital {
  final String id;
  final String patientId;
  final String metricType;
  final double value;
  final String unit;
  final VitalSource source;
  final DateTime recordedAt;

  const Vital({
    required this.id,
    required this.patientId,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.source,
    required this.recordedAt,
  });

  factory Vital.fromJson(Map<String, dynamic> json) => Vital(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        metricType: json['metric_type'] as String,
        value: (json['value'] as num).toDouble(),
        unit: json['unit'] as String,
        source: VitalSource.fromWire(json['source'] as String),
        recordedAt: DateTime.parse(json['recorded_at'] as String),
      );

  Map<String, dynamic> toInsertJson(String patientIdValue) => {
        'patient_id': patientIdValue,
        'metric_type': metricType,
        'value': value,
        'unit': unit,
        'source': source.wireValue,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
      };
}

/// Common vital metric types, centralized so screens/services agree on the exact tag strings
/// used in the `metric_type` column (BLUEPRINT.md §5.1 chronic-disease modules: diabetes, BP).
class VitalMetric {
  VitalMetric._();
  static const bloodGlucose = 'blood_glucose';
  static const systolicBp = 'systolic_bp';
  static const diastolicBp = 'diastolic_bp';
  static const weightKg = 'weight_kg';
  static const hba1c = 'hba1c';
  static const heartRate = 'heart_rate';
}
