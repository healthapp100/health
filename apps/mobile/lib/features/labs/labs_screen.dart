import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/service_providers.dart';
import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import '../../models/lab.dart';

final _ownLabOrdersProvider = FutureProvider.autoDispose<List<LabOrder>>((ref) {
  return ref.watch(labServiceProvider).getOwnOrders();
});

final _ownLabResultsProvider = FutureProvider.autoDispose<List<LabResult>>((ref) {
  return ref.watch(labServiceProvider).getOwnResults();
});

/// Laboratory Test Support + the "digital health-records vault" (BLUEPRINT.md §4.3) — booking
/// itself is staff-managed (RLS in supabase/migrations/0005), so this screen is a read-only
/// view of orders/results plus a "vault" tab for past reports.
class LabsScreen extends ConsumerWidget {
  const LabsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(_ownLabOrdersProvider);
    final resultsAsync = ref.watch(_ownLabResultsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lab Tests'),
          bottom: const TabBar(tabs: [Tab(text: 'Orders'), Tab(text: 'Results vault')]),
        ),
        body: ResponsiveContent(
          child: TabBarView(
          children: [
            ordersAsync.when(
              data: (orders) => AsyncListView<LabOrder>(
                data: orders,
                error: null,
                isLoading: false,
                emptyTitle: 'No lab orders yet',
                itemBuilder: (context, order, index) => AnimatedListEntry(
                  index: index,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(order.testName),
                      subtitle: Align(
                        alignment: Alignment.centerLeft,
                        child: StatusChip(
                          label: labOrderStatusLabel(order.status),
                          tone: labOrderStatusTone(order.status),
                        ),
                      ),
                      trailing: order.scheduledAt != null
                          ? Text(DateFormat('d MMM').format(order.scheduledAt!))
                          : null,
                    ),
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(count: 3),
              ),
              error: (e, _) => ErrorState(message: '$e'),
            ),
            resultsAsync.when(
              data: (results) => AsyncListView<LabResult>(
                data: results,
                error: null,
                isLoading: false,
                emptyTitle: 'No results in your vault yet',
                itemBuilder: (context, result, index) => AnimatedListEntry(
                  index: index,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(result.resultSummary ?? 'Lab report'),
                      subtitle: Text(DateFormat('d MMM yyyy').format(result.reportedAt)),
                      trailing:
                          result.resultFileUrl != null ? const Icon(Icons.download_outlined) : null,
                      onTap: result.resultFileUrl == null
                          ? null
                          : () async {
                              final uri = Uri.parse(result.resultFileUrl!);
                              final opened =
                                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                              if (!opened && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Could not open the report')),
                                );
                              }
                            },
                    ),
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: SkeletonList(count: 3),
              ),
              error: (e, _) => ErrorState(message: '$e'),
            ),
          ],
          ),
        ),
      ),
    );
  }
}
