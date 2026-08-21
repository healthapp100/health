import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../models/content.dart';
import '../../learn/learn_providers.dart';
import 'seminar_edit_screen.dart';

class AdminSeminarsScreen extends ConsumerWidget {
  const AdminSeminarsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seminarsAsync = ref.watch(allSeminarsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Seminars')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const SeminarEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add seminar'),
      ),
      body: ResponsiveContent(
        child: seminarsAsync.when(
          data: (seminars) {
            if (seminars.isEmpty) {
              return const ActionableEmptyState(
                icon: Icons.event_outlined,
                title: 'No seminars yet',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: seminars.length,
              itemBuilder: (context, index) {
                final seminar = seminars[index];
                return AnimatedListEntry(
                  index: index,
                  child: Card(
                    child: ListTile(
                      leading: Icon(
                        seminar.isOnline ? Icons.videocam_outlined : Icons.location_on_outlined,
                      ),
                      title: Text(seminar.title),
                      subtitle: Text(
                        '${seminar.speakerName} · '
                        '${DateFormat('d MMM yyyy, h:mm a').format(seminar.scheduledAt)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          StatusChip(
                            label: seminar.status,
                            tone: switch (seminar.status) {
                              'cancelled' => StatusTone.danger,
                              'completed' => StatusTone.neutral,
                              _ => StatusTone.success,
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(context, ref, seminar),
                          ),
                        ],
                      ),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SeminarEditScreen(seminar: seminar)),
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: SkeletonList(count: 4),
          ),
          error: (e, _) => ErrorState(message: '$e'),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, Seminar seminar) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete seminar?'),
        content: Text('"${seminar.title}" and its registrations will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentServiceProvider).deleteSeminar(seminar.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete. $e')));
    }
  }
}
