/// Mirrors public.meal_plans (supabase/migrations/0004_care_delivery.sql). Coach/nutritionist
/// authored, patient read-only — Daily Meal Guidance is presented to the patient, not self-edited.
class MealPlan {
  final String id;
  final String patientId;
  final String createdBy;
  final DateTime planDate;
  final String? breakfast;
  final String? lunch;
  final String? dinner;
  final String? notes;

  const MealPlan({
    required this.id,
    required this.patientId,
    required this.createdBy,
    required this.planDate,
    this.breakfast,
    this.lunch,
    this.dinner,
    this.notes,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) => MealPlan(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        createdBy: json['created_by'] as String,
        planDate: DateTime.parse(json['plan_date'] as String),
        breakfast: json['breakfast'] as String?,
        lunch: json['lunch'] as String?,
        dinner: json['dinner'] as String?,
        notes: json['notes'] as String?,
      );
}

/// Mirrors public.medicine_reminders. Reminders/adherence only — deliberately no
/// purchase/dispensing fields, per the MVP scope decision in BLUEPRINT.md §3.4.
class MedicineReminder {
  final String id;
  final String patientId;
  final String medicineName;
  final String? dosage;
  final List<MedicineScheduleEntry> schedule;
  final bool active;

  const MedicineReminder({
    required this.id,
    required this.patientId,
    required this.medicineName,
    this.dosage,
    required this.schedule,
    required this.active,
  });

  factory MedicineReminder.fromJson(Map<String, dynamic> json) => MedicineReminder(
        id: json['id'] as String,
        patientId: json['patient_id'] as String,
        medicineName: json['medicine_name'] as String,
        dosage: json['dosage'] as String?,
        schedule: ((json['schedule'] as List<dynamic>?) ?? [])
            .map((e) => MedicineScheduleEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertJson(String patientIdValue) => {
        'patient_id': patientIdValue,
        'medicine_name': medicineName,
        if (dosage != null) 'dosage': dosage,
        'schedule': schedule.map((e) => e.toJson()).toList(),
        'active': active,
      };
}

class MedicineScheduleEntry {
  /// 24h "HH:mm" local time.
  final String time;
  final List<String> days;

  const MedicineScheduleEntry({required this.time, required this.days});

  factory MedicineScheduleEntry.fromJson(Map<String, dynamic> json) => MedicineScheduleEntry(
        time: json['time'] as String,
        days: ((json['days'] as List<dynamic>?) ?? []).cast<String>(),
      );

  Map<String, dynamic> toJson() => {'time': time, 'days': days};
}
