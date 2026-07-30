import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/state_widgets.dart';
import '../../models/vital.dart';
import 'log_vital_sheet.dart';
import 'track_providers.dart';

/// Health Data Monitoring + Daily Meal Guidance + Medicine Reminders presented as one connected
/// loop (log → insight → coach call → adjusted plan), not disconnected tabs — the specific UX
/// lesson from Sugar.fit (BLUEPRINT.md §4.4).
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _VitalTrendCard(metricType: VitalMetric.bloodGlucose, label: 'Blood glucose', unit: 'mg/dL'),
          SizedBox(height: 16),
          _VitalTrendCard(metricType: VitalMetric.systolicBp, label: 'Systolic BP', unit: 'mmHg'),
          SizedBox(height: 24),
          _MealPlanCard(),
          SizedBox(height: 24),
          _RemindersCard(),
        ],
      ),
    );
  }
}

class _VitalTrendCard extends ConsumerWidget {
  final String metricType;
  final String label;
  final String unit;
  const _VitalTrendCard({required this.metricType, required this.label, required this.unit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendAsync = ref.watch(vitalTrendProvider(metricType));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 140,
              child: trendAsync.when(
                data: (points) {
                  if (points.isEmpty) {
                    return const EmptyState(title: 'No readings yet', icon: Icons.show_chart);
                  }
                  final spots = points
                      .asMap()
                      .entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value.value))
                      .toList();
                  return LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          dotData: const FlDotData(show: false),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const LoadingState(),
                error: (e, _) => ErrorState(message: '$e'),
              ),
            ),
          ],
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
                  return const EmptyState(
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
              loading: () => const LoadingState(),
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
            Text('Medicine reminders', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            remindersAsync.when(
              data: (reminders) {
                if (reminders.isEmpty) {
                  return const EmptyState(icon: Icons.medication_outlined, title: 'No active reminders');
                }
                return Column(
                  children: reminders
                      .map(
                        (r) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(r.medicineName),
                          subtitle: Text(r.dosage ?? ''),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: '$e'),
            ),
          ],
        ),
      ),
    );
  }
}
