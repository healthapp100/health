import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/meal_plan.dart';
import '../../models/vital.dart';

final vitalTrendProvider =
    FutureProvider.autoDispose.family<List<Vital>, String>((ref, metricType) {
  return ref.watch(vitalsServiceProvider).getTrend(metricType);
});

final latestVitalsProvider =
    FutureProvider.autoDispose.family<Vital?, String>((ref, metricType) {
  return ref.watch(vitalsServiceProvider).getLatest(metricType);
});

final todaysMealPlanProvider = FutureProvider.autoDispose<MealPlan?>((ref) {
  return ref.watch(mealPlanServiceProvider).getPlanForDate(DateTime.now());
});

final activeRemindersProvider = FutureProvider.autoDispose<List<MedicineReminder>>((ref) {
  return ref.watch(medicineReminderServiceProvider).getActiveReminders();
});
