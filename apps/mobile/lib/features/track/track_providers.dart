import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/meal_plan.dart';
import '../../models/vital.dart';

/// One Realtime subscription for all of the patient's vitals (rather than one channel per metric
/// type) — trend/latest below are pure derivations of this, so a doctor/lab updating a reading
/// reaches every screen watching any metric without a manual refresh.
final ownVitalsStreamProvider = StreamProvider.autoDispose<List<Vital>>((ref) {
  return ref.watch(vitalsServiceProvider).watchOwnVitals();
});

/// `Provider.family` (not `FutureProvider`) returning `AsyncValue<T>` directly — this is a pure
/// synchronous derivation of [ownVitalsStreamProvider]'s AsyncValue, not a new async operation,
/// so call sites are unaffected: `ref.watch(vitalTrendProvider(metric))` still yields
/// `AsyncValue<List<Vital>>` exactly as it did when this was a `FutureProvider`.
final vitalTrendProvider = Provider.autoDispose.family<AsyncValue<List<Vital>>, String>((ref, metricType) {
  return ref.watch(ownVitalsStreamProvider).whenData((vitals) {
    final filtered = vitals.where((v) => v.metricType == metricType).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return filtered;
  });
});

final latestVitalsProvider = Provider.autoDispose.family<AsyncValue<Vital?>, String>((ref, metricType) {
  return ref.watch(ownVitalsStreamProvider).whenData((vitals) {
    final filtered = vitals.where((v) => v.metricType == metricType).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtered.isEmpty ? null : filtered.first;
  });
});

final ownMealPlansStreamProvider = StreamProvider.autoDispose<List<MealPlan>>((ref) {
  return ref.watch(mealPlanServiceProvider).watchOwnPlans();
});

final todaysMealPlanProvider = Provider.autoDispose<AsyncValue<MealPlan?>>((ref) {
  final today = DateTime.now();
  final todayOnly = DateTime(today.year, today.month, today.day);
  return ref.watch(ownMealPlansStreamProvider).whenData((plans) {
    for (final plan in plans) {
      if (plan.planDate.year == todayOnly.year &&
          plan.planDate.month == todayOnly.month &&
          plan.planDate.day == todayOnly.day) {
        return plan;
      }
    }
    return null;
  });
});

final ownRemindersStreamProvider = StreamProvider.autoDispose<List<MedicineReminder>>((ref) {
  return ref.watch(medicineReminderServiceProvider).watchOwnReminders();
});

final activeRemindersProvider = Provider.autoDispose<AsyncValue<List<MedicineReminder>>>((ref) {
  return ref.watch(ownRemindersStreamProvider).whenData(
        (reminders) => reminders.where((r) => r.active).toList(),
      );
});
