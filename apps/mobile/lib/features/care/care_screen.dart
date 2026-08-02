import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/appointment.dart';
import '../../models/enums.dart';
import 'book_appointment_sheet.dart';
import 'care_providers.dart';

/// Doctor Calls + Daily Monitoring Calls, presented together under one tab since both are
/// "talk to your care team" — but the two lists below map to two distinct tables/RLS policies
/// on purpose (BLUEPRINT.md §3.5's non-diagnostic scope boundary for monitoring calls).
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Care'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'My calls'),
            Tab(text: 'Find a doctor'),
            Tab(text: 'Find a nutritionist'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MyCallsTab(),
          const _FindProviderTab(role: 'doctor'),
          const _FindProviderTab(role: 'nutritionist'),
        ],
      ),
    );
  }
}

class _MyCallsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointments = ref.watch(ownAppointmentsProvider);
    final monitoringCalls = ref.watch(ownMonitoringCallsStreamProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Doctor consultations'),
        appointments.when(
          data: (list) => list.isEmpty
              ? const ActionableEmptyState(
                  icon: Icons.medical_services_outlined,
                  title: 'No consultations yet',
                  subtitle: 'Book one from the "Find a doctor" tab.',
                )
              : Column(children: list.map((a) => _AppointmentTile(appointment: a)).toList()),
          loading: () => const SkeletonList(count: 2),
          error: (e, _) => ErrorState(message: '$e'),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Wellness check-ins'),
        monitoringCalls.when(
          data: (list) => list.isEmpty
              ? const ActionableEmptyState(
                  icon: Icons.phone_in_talk_outlined,
                  title: 'No check-ins scheduled',
                )
              : Column(children: list.map((c) => _MonitoringCallTile(call: c)).toList()),
          loading: () => const SkeletonList(count: 2),
          error: (e, _) => ErrorState(message: '$e'),
        ),
      ],
    );
  }
}

// Only a call that hasn't already happened or been cancelled can be cancelled.
bool _isCancellable(AppointmentStatus status) =>
    status == AppointmentStatus.requested || status == AppointmentStatus.confirmed;

Future<bool> _confirmCancel(BuildContext context, String title) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel this call?'),
      content: Text(title),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Keep it')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Cancel call')),
      ],
    ),
  );
  return confirmed ?? false;
}

class _AppointmentTile extends ConsumerWidget {
  final Appointment appointment;
  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = DateFormat('EEE, d MMM · h:mm a').format(appointment.scheduledAt);
    return Card(
      child: ListTile(
        leading: Icon(appointment.mode.name == 'video' ? Icons.videocam_outlined : Icons.call_outlined),
        title: Text(label),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            label: appointmentStatusLabel(appointment.status),
            tone: appointmentStatusTone(appointment.status),
          ),
        ),
        trailing: _isCancellable(appointment.status)
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel',
                onPressed: () async {
                  if (!await _confirmCancel(context, label)) return;
                  try {
                    await ref.read(appointmentServiceProvider).cancelAppointment(appointment.id);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Could not cancel. $e')));
                  }
                },
              )
            : null,
      ),
    );
  }
}

class _MonitoringCallTile extends ConsumerWidget {
  final MonitoringCall call;
  const _MonitoringCallTile({required this.call});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final label = DateFormat('EEE, d MMM · h:mm a').format(call.scheduledAt);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.phone_in_talk_outlined),
        title: Text(label),
        subtitle: Align(
          alignment: Alignment.centerLeft,
          child: StatusChip(
            label: appointmentStatusLabel(call.status),
            tone: appointmentStatusTone(call.status),
          ),
        ),
        trailing: _isCancellable(call.status)
            ? IconButton(
                icon: const Icon(Icons.cancel_outlined),
                tooltip: 'Cancel',
                onPressed: () async {
                  if (!await _confirmCancel(context, label)) return;
                  try {
                    await ref.read(appointmentServiceProvider).cancelMonitoringCall(call.id);
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('Could not cancel. $e')));
                  }
                },
              )
            : null,
      ),
    );
  }
}

class _FindProviderTab extends ConsumerWidget {
  final String role;
  const _FindProviderTab({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providersAsync =
        role == 'doctor' ? ref.watch(verifiedDoctorsProvider) : ref.watch(verifiedNutritionistsProvider);

    return providersAsync.when(
      data: (providers) => providers.isEmpty
          ? const ActionableEmptyState(
              icon: Icons.person_search_outlined,
              title: 'No verified providers yet',
              subtitle: 'Check back soon — new providers are added regularly.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(provider.fullName),
                    subtitle: Text(
                      [
                        if (provider.specialty != null) provider.specialty!,
                        if (provider.yearsExperience != null)
                          '${provider.yearsExperience} yrs experience',
                      ].join(' · '),
                    ),
                    trailing: FilledButton(
                      onPressed: () => showBookAppointmentSheet(context, ref, provider),
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            ),
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: SkeletonList(count: 4),
      ),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }
}
