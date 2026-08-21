import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/design_system.dart';
import '../../core/widgets/responsive.dart';
import '../../core/widgets/state_widgets.dart';
import 'services_providers.dart';

/// Playback is external (url_launcher opens the YouTube/Drive link) rather than an embedded
/// player — this app has no video-player/WebView dependency declared, and adding one risks
/// breaking the Flutter Web build (see the earlier decision against youtube_player_flutter for
/// the Learn module's video links, same reasoning here).
class DailyVideosScreen extends ConsumerWidget {
  const DailyVideosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosAsync = ref.watch(visibleDailyVideosProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Videos')),
      body: ResponsiveContent(
        child: videosAsync.when(
          data: (videos) {
            if (videos.isEmpty) {
              return const EmptyState(
                icon: Icons.play_circle_outline,
                title: 'No videos available right now',
                subtitle: 'Check back soon — new videos are added regularly.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: videos.length,
              itemBuilder: (context, index) {
                final video = videos[index];
                return AnimatedListEntry(
                  index: index,
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text(video.title),
                      subtitle: video.description != null ? Text(video.description!) : null,
                      trailing: const Icon(Icons.open_in_new),
                      onTap: () async {
                        final uri = Uri.parse(video.videoUrl);
                        final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!opened && context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(content: Text('Could not open the video')));
                        }
                      },
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
