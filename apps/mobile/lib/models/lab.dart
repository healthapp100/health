import 'enums.dart';

/// Mirrors public.lab_orders (supabase/migrations/0005_vitals_and_labs.sql).
class LabOrder {
  final String id;
  final String patientId;
  final String? orderedBy;
  final String testName;
  final LabOrderStatus status;
  final DateTime? scheduledAt;
  final DateTime createdAt;

  const LabOrder({
    required this.id,
    required this.patientId,
    this.orderedBy,
    required this.testName,
    required this.status,
    this.scheduledAt,
    required this.createdAt,
  });

  factory LabOrder.fromJson(Map<String, dynamic> json) => LabOrder(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        orderedBy: json['ordered_by'] as String?,
        testName: json['test_name'] as String,
        status: LabOrderStatus.fromWire(json['status'] as String),
        scheduledAt:
            json['scheduled_at'] != null ? DateTime.parse(json['scheduled_at'] as String) : null,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}

/// Mirrors public.lab_results — feeds the "digital health-records vault" (BLUEPRINT.md §4.3).
class LabResult {
  final String id;
  final String labOrderId;
  final String patientId;
  final String? resultFileUrl;
  final String? resultSummary;
  final DateTime reportedAt;
  final String? reviewedBy;

  const LabResult({
    required this.id,
    required this.labOrderId,
    required this.patientId,
    this.resultFileUrl,
    this.resultSummary,
    required this.reportedAt,
    this.reviewedBy,
  });

  factory LabResult.fromJson(Map<String, dynamic> json) => LabResult(
        id: json['id'] as String,
        labOrderId: json['lab_order_id'] as String,
        patientId: json['patient_id'] as String,
        resultFileUrl: json['result_file_url'] as String?,
        resultSummary: json['result_summary'] as String?,
        reportedAt: DateTime.parse(json['reported_at'] as String),
        reviewedBy: json['reviewed_by'] as String?,
      );
}
