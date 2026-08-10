import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/state_widgets.dart';
import 'learn_providers.dart';

/// Every article carries the "educational only, not medical advice" disclaimer inline
/// (BLUEPRINT.md §3.6 — cheap, non-negotiable, ASCI/DMR Act compliance) rather than relying on
/// a user having seen it once at signup.
class ArticleDetailScreen extends ConsumerWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articleAsync = ref.watch(articleBySlugProvider(slug));

    return Scaffold(
      appBar: AppBar(),
      body: articleAsync.when(
        data: (article) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(article.title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            MarkdownBody(data: article.bodyMarkdown),
            const SizedBox(height: 24),
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This content is educational only and is not a substitute for professional '
                  'medical advice, diagnosis, or treatment. Consult a doctor for guidance '
                  'specific to you.',
                  style: TextStyle(fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}
