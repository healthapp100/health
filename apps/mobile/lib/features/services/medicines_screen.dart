import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import 'services_providers.dart';

class MedicinesScreen extends ConsumerWidget {
  const MedicinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicinesAsync = ref.watch(medicineInfoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Medicines')),
      body: ResponsiveContent(
        child: medicinesAsync.when(
          data: (medicines) {
            if (medicines.isEmpty) {
              return const EmptyState(
                icon: Icons.medication_outlined,
                title: 'No medicine information published yet',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final medicine = medicines[index];
                return AnimatedListEntry(
                  index: index,
                  child: Card(
                    child: ExpansionTile(
                      leading: const Icon(Icons.medication_outlined),
                      title: Text(medicine.name),
                      subtitle: medicine.category != null ? Text(medicine.category!) : null,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (medicine.description != null) Text(medicine.description!),
                              if (medicine.recommendations != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Recommendations',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                Text(medicine.recommendations!),
                              ],
                            ],
                          ),
                        ),
                      ],
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
