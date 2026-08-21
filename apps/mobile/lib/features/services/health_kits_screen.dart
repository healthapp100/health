import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import 'services_providers.dart';

class HealthKitsScreen extends ConsumerWidget {
  const HealthKitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(healthKitDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Health Kit Support')),
      body: ResponsiveContent(
        child: entriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const EmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'No devices listed yet',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return AnimatedListEntry(
                  index: index,
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center_outlined),
                      title: Text(entry.name),
                      subtitle: Text(
                        [
                          if (entry.supplierName != null) entry.supplierName!,
                          if (entry.description != null) entry.description!,
                        ].join(' · '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: entry.purchaseLink != null
                          ? OutlinedButton(
                              onPressed: () async {
                                await launchUrl(Uri.parse(entry.purchaseLink!));
                              },
                              child: const Text('Buy'),
                            )
                          : null,
                      onTap: entry.instructions == null
                          ? null
                          : () => showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(entry.name),
                                  content: Text(entry.instructions!),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: const Text('Close'),
                                    ),
                                  ],
                                ),
                              ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(count: 3),
          ),
          error: (e, _) => ErrorState(message: '$e'),
        ),
      ),
    );
  }
}
