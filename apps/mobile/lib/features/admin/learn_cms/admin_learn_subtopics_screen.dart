import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../models/learn_topic.dart';
import 'learn_cms_providers.dart';
import 'subtopic_edit_screen.dart';

/// Subtopics under one topic (e.g. Diabetes → Definition/Causes/Symptoms/Diet/FAQs). Each row
/// IS a content page — tapping one opens the full editor (SubtopicEditScreen) rather than a
/// quick-edit sheet, since its content fields (body, images, PDFs, links, YouTube) need more
/// room than a bottom sheet comfortably gives.
class AdminLearnSubtopicsScreen extends ConsumerWidget {
  final LearnTopic topic;
  const AdminLearnSubtopicsScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtopicsAsync = ref.watch(adminSubtopicsProvider(topic.id));

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SubtopicEditScreen(topicId: topic.id)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add subtopic'),
      ),
      body: ResponsiveContent(
        child: subtopicsAsync.when(
          data: (subtopics) {
            if (subtopics.isEmpty) {
              return const ActionableEmptyState(
                icon: Icons.article_outlined,
                title: 'No subtopics yet',
                subtitle: 'Add pages like "Definition", "Causes", "Symptoms", "Diet", "FAQs".',
              );
            }
            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: subtopics.length,
              onReorder: (oldIndex, newIndex) => _onReorder(ref, subtopics, oldIndex, newIndex),
              itemBuilder: (context, index) {
                final subtopic = subtopics[index];
                return Card(
                  key: ValueKey(subtopic.id),
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(subtopic.title),
                    subtitle: Text(subtopic.hasContent ? 'Has content' : 'Empty draft'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!subtopic.published)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: StatusChip(label: 'Draft', tone: StatusTone.neutral),
                          ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Delete',
                          onPressed: () => _confirmDelete(context, ref, subtopic),
                        ),
                        const Icon(Icons.drag_handle),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SubtopicEditScreen(topicId: topic.id, subtopic: subtopic),
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

  Future<void> _onReorder(
    WidgetRef ref,
    List<LearnSubtopic> subtopics,
    int oldIndex,
    int newIndex,
  ) async {
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final reordered = List<LearnSubtopic>.from(subtopics);
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(adjustedNewIndex, moved);
    await ref
        .read(learnContentServiceProvider)
        .reorderSubtopics(reordered.map((s) => s.id).toList());
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, LearnSubtopic subtopic) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete subtopic?'),
        content: Text('"${subtopic.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(learnContentServiceProvider).deleteSubtopic(subtopic.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete. $e')));
    }
  }
}
