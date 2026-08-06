import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/vital.dart';
import 'add_reminder_sheet.dart';
import 'log_vital_sheet.dart';
import 'track_providers.dart';
import 'vital_detail_screen.dart';

/// Health Data Monitoring + Daily Meal Guidance + Medicine Reminders presented as one connected
/// loop (log → insight → coach call → adjusted plan), not disconnected tabs — the specific UX
/// lesson from Sugar.fit (BLUEPRINT.md §4.4). Vitals are grouped into a glanceable summary grid
/// (related readings like systolic/diastolic BP shown together as one card) rather than five
/// stacked full-height charts — full history for any one metric is one tap away.
class TrackScreen extends ConsumerWidget {
  const TrackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Track')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showLogVitalSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Log reading'),
      ),
      body: ResponsiveContent(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            SectionHeader(title: 'Your vitals'),
            _VitalsSummaryGrid(),
            SizedBox(height: 24),
            _MealPlanCard(),
            SizedBox(height: 24),
            _RemindersCard(),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _VitalsSummaryGrid extends ConsumerWidget {
  const _VitalsSummaryGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: responsiveGridColumns(context, compact: 2, medium: 4, expanded: 4),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _MetricCard(
          metricType: VitalMetric.bloodGlucose,
          label: 'Blood glucose',
          icon: Icons.bloodtype_outlined,
          color: scheme.primary,
        ),
        _BloodPressureCard(color: scheme.secondary),
        _MetricCard(
          metricType: VitalMetric.weightKg,
          label: 'Weight',
          icon: Icons.monitor_weight_outlined,
          color: scheme.tertiary,
        ),
        _MetricCard(
          metricType: VitalMetric.heartRate,
          label: 'Heart rate',
          icon: Icons.favorite_outline,
          color: scheme.error,
        ),
      ],
    );
  }
}

class _MetricCard extends ConsumerWidget {
  final String metricType;
  final String label;
  final IconData icon;
  final Color color;
  const _MetricCard({
    required this.metricType,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latest = ref.watch(latestVitalsProvider(metricType));
    final trend = ref.watch(vitalTrendProvider(metricType));

    return latest.when(
      data: (v) => MetricSummaryCard(
        icon: icon,
        label: label,
        value: v?.value.toStringAsFixed(v.value.truncateToDouble() == v.value ? 0 : 1) ?? '--',
        unit: v?.unit ?? '',
        accentColor: color,
        trend: trend.valueOrNull?.map((e) => e.value).toList(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VitalDetailScreen(metricType: metricType, label: label, color: color),
          ),
        ),
      ),
      loading: () => const SkeletonCard(withLeadingCircle: false),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }
}

/// Systolic and diastolic shown together as one reading (e.g. "128/82") — matching how blood
/// pressure is actually read and understood, rather than as two unrelated metric cards.
class _BloodPressureCard extends ConsumerWidget {
  final Color color;
  const _BloodPressureCard({required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systolic = ref.watch(latestVitalsProvider(VitalMetric.systolicBp));
    final diastolic = ref.watch(latestVitalsProvider(VitalMetric.diastolicBp));
    final systolicTrend = ref.watch(vitalTrendProvider(VitalMetric.systolicBp));

    if (systolic.isLoading || diastolic.isLoading) {
      return const SkeletonCard(withLeadingCircle: false);
    }
    final s = systolic.valueOrNull;
    final d = diastolic.valueOrNull;
    final value = (s == null && d == null) ? '--' : '${s?.value.toStringAsFixed(0) ?? '--'}/${d?.value.toStringAsFixed(0) ?? '--'}';

    return MetricSummaryCard(
      icon: Icons.monitor_heart_outlined,
      label: 'Blood pressure',
      value: value,
      unit: 'mmHg',
      accentColor: color,
      trend: systolicTrend.valueOrNull?.map((e) => e.value).toList(),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VitalDetailScreen(
            metricType: VitalMetric.systolicBp,
            label: 'Systolic BP',
            color: color,
          ),
        ),
      ),
    );
  }
}

class _MealPlanCard extends ConsumerWidget {
  const _MealPlanCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(todaysMealPlanProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today’s meal guidance', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            planAsync.when(
              data: (plan) {
                if (plan == null) {
                  return const ActionableEmptyState(
                    icon: Icons.restaurant_outlined,
                    title: 'No plan set for today',
                    subtitle: 'Your coach will add one after your next check-in.',
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (plan.breakfast != null) _MealRow('Breakfast', plan.breakfast!),
                    if (plan.lunch != null) _MealRow('Lunch', plan.lunch!),
                    if (plan.dinner != null) _MealRow('Dinner', plan.dinner!),
                  ],
                );
              },
              loading: () => const SkeletonList(count: 2),
              error: (e, _) => ErrorState(message: '$e'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealRow extends StatelessWidget {
  final String label;
  final String value;
  const _MealRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodyMedium,
          children: [
            TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _RemindersCard extends ConsumerWidget {
  const _RemindersCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(activeRemindersProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Medicine reminders', style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Add reminder',
                  onPressed: () => showAddReminderSheet(context, ref),
                ),
              ],
            ),
            remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return const ActionableEmptyState(
                    icon: Icons.medication_outlined,
                    title: 'No active reminders',
                  );
                }
                return Column(
                  children: reminders
                      .map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(r.medicineName),
                          subtitle: Text(
                            [
                              if (r.dosage != null) r.dosage!,
                              if (r.schedule.isNotEmpty) r.schedule.first.time,
                            ].join(' · '),
                          ),
                          trailing: Switch(
                            value: r.active,
                            onChanged: (value) async {
                              try {
                                await ref
                                    .read(medicineReminderServiceProvider)
                                    .setActive(r.id, value);
                                // ownRemindersStreamProvider picks up the change via Realtime.
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(content: Text('Could not update. $e')));
                              }
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const SkeletonList(count: 2),
              error: (e, _) => ErrorState(message: '$e'),
            ),
          ],
        ),
      ),
    );
  }
}
