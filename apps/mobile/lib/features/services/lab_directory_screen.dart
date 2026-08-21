import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import 'services_providers.dart';

class LabDirectoryScreen extends ConsumerWidget {
  const LabDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(labDirectoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Lab Test Support')),
      body: ResponsiveContent(
        child: entriesAsync.when(
          data: (entries) {
            if (entries.isEmpty) {
              return const EmptyState(
                icon: Icons.science_outlined,
                title: 'No labs listed yet',
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                entry.kind == 'clinic'
                                    ? Icons.local_hospital_outlined
                                    : Icons.science_outlined,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(entry.name, style: Theme.of(context).textTheme.titleMedium),
                              ),
                            ],
                          ),
                          if (entry.doctorName != null) ...[
                            const SizedBox(height: 4),
                            Text('Dr. ${entry.doctorName}'),
                          ],
                          if (entry.services != null) ...[
                            const SizedBox(height: 4),
                            Text(entry.services!, style: Theme.of(context).textTheme.bodySmall),
                          ],
                          if (entry.timings != null) ...[
                            const SizedBox(height: 4),
                            Text('Timings: ${entry.timings}', style: Theme.of(context).textTheme.bodySmall),
                          ],
                          if (entry.address != null) ...[
                            const SizedBox(height: 4),
                            Text(entry.address!, style: Theme.of(context).textTheme.bodySmall),
                          ],
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (entry.contactPhone != null)
                                _ActionChip(
                                  icon: Icons.call_outlined,
                                  label: entry.contactPhone!,
                                  url: 'tel:${entry.contactPhone}',
                                ),
                              if (entry.contactEmail != null)
                                _ActionChip(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  url: 'mailto:${entry.contactEmail}',
                                ),
                              if (entry.externalLink != null)
                                _ActionChip(
                                  icon: Icons.open_in_new,
                                  label: 'Website',
                                  url: entry.externalLink!,
                                ),
                            ],
                          ),
                        ],
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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _ActionChip({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: () async {
        final opened = await launchUrl(Uri.parse(url));
        if (!opened && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open')));
        }
      },
    );
  }
}
