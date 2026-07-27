import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/widgets/state_widgets.dart';
import '../../models/appointment.dart';
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
    _tabController = TabController(length: 2, vsync: this);
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
        bottom: TabBar(controller: _tabController, tabs: const [
          Tab(text: 'My calls'),
          Tab(text: 'Find a doctor'),
        ]),
      ),
      body: TabBarView(controller: _tabController, children: [
        _MyCallsTab(),
        _FindProviderTab(role: 'doctor'),
      ]),
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
        Text('Doctor consultations', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        appointments.when(
          data: (list) => list.isEmpty
              ? const EmptyState(icon: Icons.medical_services_outlined, title: 'No consultations yet')
              : Column(children: list.map((a) => _AppointmentTile(appointment: a)).toList()),
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: '$e'),
        ),
        const SizedBox(height: 24),
        Text('Wellness check-ins', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        monitoringCalls.when(
          data: (list) => list.isEmpty
              ? const EmptyState(icon: Icons.phone_in_talk_outlined, title: 'No check-ins scheduled')
              : Column(children: list.map((c) => _MonitoringCallTile(call: c)).toList()),
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(message: '$e'),
        ),
      ],
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  const _AppointmentTile({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(appointment.mode.name == 'video' ? Icons.videocam_outlined : Icons.call_outlined),
        title: Text(DateFormat('EEE, d MMM · h:mm a').format(appointment.scheduledAt)),
        subtitle: Text(appointment.status.name),
      ),
    );
  }
}

class _MonitoringCallTile extends StatelessWidget {
  final MonitoringCall call;
  const _MonitoringCallTile({required this.call});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.phone_in_talk_outlined),
        title: Text(DateFormat('EEE, d MMM · h:mm a').format(call.scheduledAt)),
        subtitle: Text(call.status.name),
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
          ? const EmptyState(icon: Icons.person_search_outlined, title: 'No verified providers yet')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(provider.fullName),
                    subtitle: Text([
                      if (provider.specialty != null) provider.specialty!,
                      if (provider.yearsExperience != null) '${provider.yearsExperience} yrs experience',
                    ].join(' · ')),
                    trailing: FilledButton(
                      onPressed: () => showBookAppointmentSheet(context, ref, provider),
                      child: const Text('Book'),
                    ),
                  ),
                );
              },
            ),
      loading: () => const LoadingState(),
      error: (e, _) => ErrorState(message: '$e'),
    );
  }
}
