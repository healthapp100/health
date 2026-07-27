import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/meal_plan.dart';

/// Daily Meal Guidance (public.meal_plans) — read-only for patients, authored by their coach.
class MealPlanService {
  final SupabaseClient _client;
  const MealPlanService(this._client);

  String get _patientId => _client.auth.currentUser!.id;

  Future<MealPlan?> getPlanForDate(DateTime date) async {
    final dateOnly = DateTime(date.year, date.month, date.day);
    final rows = await _client
        .from('meal_plans')
        .select()
        .eq('patient_id', _patientId)
        .eq('plan_date', dateOnly.toIso8601String().split('T').first)
        .limit(1);
    final list = rows as List<dynamic>;
    return list.isEmpty ? null : MealPlan.fromJson(list.first as Map<String, dynamic>);
  }

  Future<List<MealPlan>> getRecentPlans({int days = 7}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final rows = await _client
        .from('meal_plans')
        .select()
        .eq('patient_id', _patientId)
        .gte('plan_date', since.toIso8601String().split('T').first)
        .order('plan_date', ascending: false);
    return (rows as List<dynamic>).map((r) => MealPlan.fromJson(r as Map<String, dynamic>)).toList();
  }
}

/// Medicine Support — reminders/adherence only (public.medicine_reminders). Deliberately no
/// purchase/order methods here: BLUEPRINT.md §3.4 defers actual medicine sale/dispensing pending
/// legal review of the e-pharmacy regulatory gray zone.
class MedicineReminderService {
  final SupabaseClient _client;
  const MedicineReminderService(this._client);

  String get _patientId => _client.auth.currentUser!.id;

  Future<List<MedicineReminder>> getActiveReminders() async {
    final rows = await _client
        .from('medicine_reminders')
        .select()
        .eq('patient_id', _patientId)
        .eq('active', true)
        .order('medicine_name');
    return (rows as List<dynamic>)
        .map((r) => MedicineReminder.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<MedicineReminder> addReminder(MedicineReminder reminder) async {
    final row = await _client
        .from('medicine_reminders')
        .insert(reminder.toInsertJson(_patientId))
        .select()
        .single();
    return MedicineReminder.fromJson(row);
  }

  Future<void> setActive(String reminderId, bool active) async {
    await _client
        .from('medicine_reminders')
        .update({'active': active})
        .eq('id', reminderId)
        .eq('patient_id', _patientId);
  }
}
