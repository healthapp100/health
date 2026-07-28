import 'package:flutter_test/flutter_test.dart';
import 'package:healthcare_platform/models/enums.dart';
import 'package:healthcare_platform/models/vital.dart';

void main() {
  test('Vital.fromJson parses a public.vitals row', () {
    final vital = Vital.fromJson({
      'id': 'v1',
      'patient_id': 'p1',
      'metric_type': VitalMetric.bloodGlucose,
      'value': 118, // int in JSON — Postgres numeric can arrive as int or double
      'unit': 'mg/dL',
      'source': 'manual',
      'recorded_at': '2026-07-20T08:30:00.000Z',
    });

    expect(vital.value, 118.0);
    expect(vital.source, VitalSource.manual);
  });

  test('toInsertJson sends recordedAt as UTC ISO8601', () {
    final vital = Vital(
      id: '',
      patientId: 'p1',
      metricType: VitalMetric.weightKg,
      value: 72.5,
      unit: 'kg',
      source: VitalSource.device,
      recordedAt: DateTime.utc(2026, 7, 20, 8, 30),
    );

    final json = vital.toInsertJson('p1');
    expect(json['recorded_at'], '2026-07-20T08:30:00.000Z');
    expect(json['source'], 'device');
  });
}
