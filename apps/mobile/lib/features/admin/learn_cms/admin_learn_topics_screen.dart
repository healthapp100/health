import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../models/learn_topic.dart';
import 'admin_learn_subtopics_screen.dart';
import 'learn_cms_providers.dart';
import 'topic_form_sheet.dart';

/// Admin authoring for the Learn module's top level (Topic → Subtopic → Content). Drag to
/// reorder — sort_order is what the patient-facing screen renders by, so this list IS the
/// authoring of that order, not a separate preview.
class AdminLearnTopicsScreen extends ConsumerWidget {
  const AdminLearnTopicsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(adminTopicsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Learn: Topics')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTopicFormSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add topic'),
      ),
      body: ResponsiveContent(
        child: topicsAsync.when(
          data: (topics) {
            if (topics.isEmpty) {
              return const ActionableEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No topics yet',
                subtitle: 'Add a topic like "Diabetes" or "Blood Pressure" to get started.',
              );
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: topics.length,
              onReorder: (oldIndex, newIndex) => _onReorder(ref, topics, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final topic = topics[index];
                return Card(
                  key: ValueKey(topic.id),
                  child: ListTile(
                    leading: Icon(_iconFor(topic.icon)),
                    title: Text(topic.title),
                    subtitle: Text(topic.summary ?? topic.slug),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!topic.published)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: StatusChip(label: 'Draft', tone: StatusTone.neutral),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit',
                          onPressed: () => showTopicFormSheet(context, ref, topic: topic),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, ref, topic),
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AdminLearnSubtopicsScreen(topic: topic),
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

  IconData _iconFor(String? name) {
    const map = {
      'bloodtype_outlined': Icons.bloodtype_outlined,
      'monitor_heart_outlined': Icons.monitor_heart_outlined,
      'favorite_outline': Icons.favorite_outline,
      'psychology_outlined': Icons.psychology_outlined,
      'restaurant_outlined': Icons.restaurant_outlined,
      'fitness_center_outlined': Icons.fitness_center_outlined,
    };
    return map[name] ?? Icons.menu_book_outlined;
  }

  Future<void> _onReorder(WidgetRef ref, List<LearnTopic> topics, int oldIndex, int newIndex) async {
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final reordered = List<LearnTopic>.from(topics);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjustedNewIndex, moved);
    await ref.read(learnContentServiceProvider).reorderTopics(reordered.map((t) => t.id).toList());
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, LearnTopic topic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete topic?'),
        content: Text('"${topic.title}" and all of its subtopics will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(learnContentServiceProvider).deleteTopic(topic.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete. $e')));
    }
  }
}
