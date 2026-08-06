import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/appointment.dart';
import '../../models/vital.dart';
import '../track/log_vital_sheet.dart';
import '../track/track_providers.dart';
import 'home_providers.dart';

/// Redesigned as a real "today" dashboard rather than three disconnected list sections:
/// a greeting, one unified "what's next" hero (whichever of appointment/check-in is soonest),
/// glanceable vitals with trend sparklines, and one-tap quick actions — the pattern Apple Health
/// and Ada Health converge on for a chronic-care home screen (lead with status, not a table).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(upcomingAppointmentsProvider);
    final monitoringCalls = ref.watch(upcomingMonitoringCallsProvider);
    final glucose = ref.watch(latestVitalsProvider(VitalMetric.bloodGlucose));
    final glucoseTrend = ref.watch(vitalTrendProvider(VitalMetric.bloodGlucose));
    final systolic = ref.watch(latestVitalsProvider(VitalMetric.systolicBp));
    final systolicTrend = ref.watch(vitalTrendProvider(VitalMetric.systolicBp));

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          // These are all Realtime streams now — pull-to-refresh re-establishes the
          // subscriptions (useful after being backgrounded/offline) rather than one-shot refetches.
          onRefresh: () async {
            ref.invalidate(upcomingAppointmentsProvider);
            ref.invalidate(upcomingMonitoringCallsProvider);
            ref.invalidate(ownVitalsStreamProvider);
          },
          child: ResponsiveContent(
            child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(_greeting(), style: Theme.of(context).textTheme.headlineMedium),
              Text(
                DateFormat('EEEE, d MMMM').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              _NextUpHero(appointments: appointments, monitoringCalls: monitoringCalls),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Your vitals'),
              Row(
                children: [
                  Expanded(
                    child: glucose.when(
                      data: (v) => MetricSummaryCard(
                        icon: Icons.bloodtype_outlined,
                        label: 'Blood glucose',
                        value: v?.value.toStringAsFixed(0) ?? '--',
                        unit: v?.unit ?? 'mg/dL',
                        accentColor: Theme.of(context).colorScheme.primary,
                        trend: glucoseTrend.valueOrNull?.map((e) => e.value).toList(),
                        onTap: () => context.go('/track'),
                      ),
                      loading: () => const SkeletonCard(withLeadingCircle: false),
                      error: (e, _) => ErrorState(message: '$e'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: systolic.when(
                      data: (v) => MetricSummaryCard(
                        icon: Icons.monitor_heart_outlined,
                        label: 'Systolic BP',
                        value: v?.value.toStringAsFixed(0) ?? '--',
                        unit: v?.unit ?? 'mmHg',
                        accentColor: Theme.of(context).colorScheme.secondary,
                        trend: systolicTrend.valueOrNull?.map((e) => e.value).toList(),
                        onTap: () => context.go('/track'),
                      ),
                      loading: () => const SkeletonCard(withLeadingCircle: false),
                      error: (e, _) => ErrorState(message: '$e'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Quick actions'),
              _QuickActionsRow(),
            ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NextUpHero extends StatelessWidget {
  final AsyncValue<List<Appointment>> appointments;
  final AsyncValue<List<MonitoringCall>> monitoringCalls;
  const _NextUpHero({required this.appointments, required this.monitoringCalls});

  @override
  Widget build(BuildContext context) {
    if (appointments.isLoading || monitoringCalls.isLoading) {
      return const SkeletonCard();
    }
    if (appointments.hasError) return ErrorState(message: '${appointments.error}');
    if (monitoringCalls.hasError) return ErrorState(message: '${monitoringCalls.error}');

    final now = DateTime.now();
    final nextAppointment = (appointments.valueOrNull ?? const [])
        .where((a) => a.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    final nextCall = (monitoringCalls.valueOrNull ?? const [])
        .where((c) => c.scheduledAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final appointment = nextAppointment.isNotEmpty ? nextAppointment.first : null;
    final call = nextCall.isNotEmpty ? nextCall.first : null;

    // Show whichever of the two is soonest — a patient shouldn't have to check two sections to
    // know what's actually next.
    final showAppointment =
        appointment != null && (call == null || appointment.scheduledAt.isBefore(call.scheduledAt));

    if (appointment == null && call == null) {
      return ActionableEmptyState(
        icon: Icons.event_available_outlined,
        title: 'Nothing scheduled yet',
        subtitle: 'Book a doctor call or wellness check-in to get started.',
        actionLabel: 'Go to Care',
        onAction: () => context.go('/care'),
      );
    }

    final theme = Theme.of(context);
    final kind = showAppointment ? 'Doctor consultation' : 'Wellness check-in';
    final when = DateFormat('EEEE, d MMM · h:mm a')
        .format(showAppointment ? appointment.scheduledAt : call!.scheduledAt);
    final status = appointmentStatusLabel(showAppointment ? appointment.status : call!.status);
    final semanticLabel = [
      'Next: $kind',
      when,
      if (showAppointment && appointment.reason != null) appointment.reason!,
      status,
      'Opens Care tab',
    ].join(', ');

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Semantics(
        button: true,
        label: semanticLabel,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.go('/care'),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      showAppointment ? Icons.videocam_outlined : Icons.phone_in_talk_outlined,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next: $kind',
                      style: theme.textTheme.labelLarge
                          ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  when,
                  style: theme.textTheme.headlineMedium
                      ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                ),
                if (showAppointment && appointment.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    appointment.reason!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                  ),
                ],
                const SizedBox(height: 12),
                StatusChip(
                  label: status,
                  tone: appointmentStatusTone(showAppointment ? appointment.status : call!.status),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionsRow extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = [
      (Icons.add_chart_outlined, 'Log reading', () => showLogVitalSheet(context, ref)),
      (Icons.medical_services_outlined, 'Book a call', () => context.go('/care')),
      (Icons.school_outlined, 'Seminars', () => context.go('/learn')),
      (Icons.science_outlined, 'Lab tests', () => context.go('/labs')),
    ];
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: actions
          .map(
            (a) => Semantics(
              button: true,
              label: a.$2,
              excludeSemantics: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: a.$3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(a.$1, color: Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.$2,
                      style: Theme.of(context).textTheme.labelSmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
