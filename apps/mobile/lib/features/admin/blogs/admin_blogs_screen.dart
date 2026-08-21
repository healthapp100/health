import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/providers/service_providers.dart';
import '../../../core/widgets/design_system.dart';
import '../../../core/widgets/responsive.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../models/content.dart';
import 'admin_blogs_providers.dart';
import 'blog_edit_screen.dart';

/// Admin authoring for Blogs & Articles & Medical News — all three share one table/form,
/// distinguished by the `contentType` tab (mirrors how health_articles itself models them).
class AdminBlogsScreen extends ConsumerStatefulWidget {
  const AdminBlogsScreen({super.key});

  @override
  ConsumerState<AdminBlogsScreen> createState() => _AdminBlogsScreenState();
}

class _AdminBlogsScreenState extends ConsumerState<AdminBlogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  static const _types = ['blog', 'article', 'news'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
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
        title: const Text('Blogs & Articles'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Blogs'), Tab(text: 'Articles'), Tab(text: 'News')],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BlogEditScreen(contentType: _types[_tabController.index]),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ResponsiveContent(
        child: TabBarView(
          controller: _tabController,
          children: _types.map((t) => _BlogList(contentType: t)).toList(),
        ),
      ),
    );
  }
}

class _BlogList extends ConsumerWidget {
  final String contentType;
  const _BlogList({required this.contentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articlesAsync = ref.watch(adminArticlesProvider(contentType));

    return articlesAsync.when(
      data: (articles) {
        if (articles.isEmpty) {
          return const ActionableEmptyState(
            icon: Icons.article_outlined,
            title: 'Nothing here yet',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: articles.length,
          itemBuilder: (context, index) {
            final article = articles[index];
            final isPublished =
                article.publishedAt != null && article.publishedAt!.isBefore(DateTime.now());
            final isScheduled =
                article.publishedAt != null && article.publishedAt!.isAfter(DateTime.now());
            return AnimatedListEntry(
              index: index,
              child: Card(
                child: ListTile(
                  title: Text(article.title),
                  subtitle: Text(
                    [
                      article.category,
                      if (isScheduled)
                        'Scheduled ${DateFormat('d MMM, h:mm a').format(article.publishedAt!)}'
                      else if (isPublished)
                        'Published ${DateFormat('d MMM').format(article.publishedAt!)}'
                      else
                        'Draft',
                    ].join(' · '),
                  ),
                  leading: article.featured
                      ? const Icon(Icons.star, color: Colors.amber)
                      : const Icon(Icons.article_outlined),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StatusChip(
                        label: isPublished ? 'Published' : (isScheduled ? 'Scheduled' : 'Draft'),
                        tone: isPublished
                            ? StatusTone.success
                            : (isScheduled ? StatusTone.info : StatusTone.neutral),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, ref, article),
                      ),
                    ],
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => BlogEditScreen(contentType: contentType, article: article),
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref, HealthArticle article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete?'),
        content: Text('"${article.title}" will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(contentServiceProvider).deleteArticle(article.id);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete. $e')));
    }
  }
}
