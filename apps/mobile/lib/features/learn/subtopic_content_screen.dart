import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/state_widgets.dart';
import 'learn_providers.dart';

/// Renders one subtopic's content page — the leaf of Learn's Topic → Subtopic → Content
/// hierarchy. Same "educational only" disclaimer pattern as ArticleDetailScreen.
class SubtopicContentScreen extends ConsumerWidget {
  final String topicId;
  final String subtopicId;
  const SubtopicContentScreen({super.key, required this.topicId, required this.subtopicId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtopicsAsync = ref.watch(learnSubtopicsProvider(topicId));

    return Scaffold(
      appBar: AppBar(),
      body: subtopicsAsync.when(
        data: (subtopics) {
          final matches = subtopics.where((s) => s.id == subtopicId);
          final subtopic = matches.isEmpty ? null : matches.first;
          if (subtopic == null) {
            return const ErrorState(message: 'This content is no longer available.');
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(subtopic.title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              if (subtopic.bodyMarkdown != null) MarkdownBody(data: subtopic.bodyMarkdown!),
              for (final imageUrl in subtopic.imageUrls) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ],
              if (subtopic.youtubeUrl != null) ...[
                const SizedBox(height: 16),
                _LinkTile(
                  icon: Icons.play_circle_outline,
                  label: 'Watch video',
                  url: subtopic.youtubeUrl!,
                ),
              ],
              for (final pdfUrl in subtopic.pdfUrls) ...[
                const SizedBox(height: 8),
                _LinkTile(icon: Icons.picture_as_pdf_outlined, label: 'View PDF', url: pdfUrl),
              ],
              for (final link in subtopic.externalLinks) ...[
                const SizedBox(height: 8),
                _LinkTile(icon: Icons.link, label: link.label, url: link.url),
              ],
              if (subtopic.referencesText != null) ...[
                const SizedBox(height: 24),
                Text('References', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(subtopic.referencesText!, style: Theme.of(context).textTheme.bodySmall),
              ],
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
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(message: '$e'),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String url;
  const _LinkTile({required this.icon, required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.open_in_new),
        onTap: () async {
          final uri = Uri.parse(url);
          final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
          if (!opened && context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Could not open the link')));
          }
        },
      ),
    );
  }
}
