import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/state_widgets.dart';
import 'learn_providers.dart';

/// Topic browsing — the Learn module's primary structured navigation (Topic → Subtopic →
/// Content, e.g. Diabetes → Definition/Causes/Symptoms/Diet/FAQs), distinct from the free-form
/// Articles tab (informal reading, not a curated outline).
class LearnTopicsTab extends ConsumerWidget {
  const LearnTopicsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topicsAsync = ref.watch(learnTopicsProvider);

    return topicsAsync.when(
      data: (topics) {
        if (topics.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'No topics published yet',
            subtitle: 'Check back soon — new health topics are added regularly.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
          ),
          itemCount: topics.length,
          itemBuilder: (context, index) {
            final topic = topics[index];
            return AnimatedListEntry(
              index: index,
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.push('/learn/topic/${topic.id}'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(_iconFor(topic.icon), color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(height: 12),
                        Text(topic.title, style: Theme.of(context).textTheme.titleMedium),
                        if (topic.summary != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            topic.summary!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
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
        child: SkeletonList(count: 4),
      ),
      error: (e, _) => ErrorState(message: '$e'),
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
}

class TopicSubtopicListScreen extends ConsumerWidget {
  final String topicId;
  const TopicSubtopicListScreen({super.key, required this.topicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtopicsAsync = ref.watch(learnSubtopicsProvider(topicId));
    final topicAsync = ref.watch(learnTopicByIdProvider(topicId));

    return Scaffold(
      appBar: AppBar(title: Text(topicAsync.valueOrNull?.title ?? '')),
      body: subtopicsAsync.when(
        data: (subtopics) {
          if (subtopics.isEmpty) {
            return const EmptyState(
              icon: Icons.article_outlined,
              title: 'No content published for this topic yet',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: subtopics.length,
            itemBuilder: (context, index) {
              final subtopic = subtopics[index];
              return AnimatedListEntry(
                index: index,
                child: Card(
                  child: ListTile(
                    leading: const Icon(Icons.article_outlined),
                    title: Text(subtopic.title),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/learn/topic/$topicId/${subtopic.id}'),
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
    );
  }
}
