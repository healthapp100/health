import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/state_widgets.dart';
import '../../models/vital.dart';
import 'home_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(upcomingAppointmentsProvider);
    final monitoringCalls = ref.watch(upcomingMonitoringCallsProvider);
    final latestGlucose = ref.watch(latestVitalsProvider(VitalMetric.bloodGlucose));

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(upcomingAppointmentsProvider);
          ref.invalidate(upcomingMonitoringCallsProvider);
          ref.invalidate(latestVitalsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionHeader(title: 'Next up', onSeeAll: () => context.go('/care')),
            appointments.when(
              data: (list) {
                final upcoming = list
                    .where((a) => a.scheduledAt.isAfter(DateTime.now()))
                    .toList()
                  ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
                if (upcoming.isEmpty) {
                  return const EmptyState(
                    icon: Icons.event_available_outlined,
                    title: 'No upcoming calls',
                    subtitle: 'Book a doctor call from the Care tab.',
                  );
                }
                final next = upcoming.first;
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.video_call_outlined),
                    title: Text(DateFormat('EEE, d MMM · h:mm a').format(next.scheduledAt)),
                    subtitle: Text(next.reason ?? next.mode.wireValue),
                  ),
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: '$e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Wellness check-ins', onSeeAll: () => context.go('/care')),
            monitoringCalls.when(
              data: (list) {
                final upcoming = list.where((c) => c.scheduledAt.isAfter(DateTime.now())).toList();
                if (upcoming.isEmpty) {
                  return const EmptyState(
                    icon: Icons.phone_in_talk_outlined,
                    title: 'No check-ins scheduled',
                  );
                }
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.phone_in_talk_outlined),
                    title: Text(DateFormat('EEE, d MMM · h:mm a').format(upcoming.first.scheduledAt)),
                    subtitle: const Text('Wellness & adherence check-in'),
                  ),
                );
              },
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(message: '$e'),
            ),
            const SizedBox(height: 24),
            _SectionHeader(title: 'Latest reading', onSeeAll: () => context.go('/track')),
            latestGlucose.when(
              data: (vital) {
                if (vital == null) {
                  return const EmptyState(
                    icon: Icons.monitor_heart_outlined,
                    title: 'No readings logged yet',
                    subtitle: 'Log your first vital from the Track tab.',
                  );
                }
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.bloodtype_outlined),
                    title: Text(
                      '${vital.value.toStringAsFixed(1)} ${vital.unit}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    subtitle: Text('Blood glucose · ${DateFormat('d MMM, h:mm a').format(vital.recordedAt)}'),
                  ),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;
  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}
