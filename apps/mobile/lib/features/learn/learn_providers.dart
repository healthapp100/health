import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/content.dart';

// Articles are paginated (see _PaginatedArticlesList in learn_screen.dart) rather than a plain
// FutureProvider, since a category/search result set isn't bounded — a category with hundreds
// of articles shouldn't be pulled into memory in one unbounded query.

/// One Realtime subscription for all seminars — upcoming/past below are pure derivations, so a
/// newly-published seminar or an added recording appears without a manual refresh.
final allSeminarsStreamProvider = StreamProvider.autoDispose<List<Seminar>>((ref) {
  return ref.watch(contentServiceProvider).watchAllSeminars();
});

final upcomingSeminarsProvider = Provider.autoDispose<AsyncValue<List<Seminar>>>((ref) {
  return ref.watch(allSeminarsStreamProvider).whenData(
        (seminars) => seminars.where((s) => !s.isPast).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt)),
      );
});

final articleBySlugProvider =
    FutureProvider.autoDispose.family<HealthArticle, String>((ref, slug) {
  return ref.watch(contentServiceProvider).getArticleBySlug(slug);
});

final pastSeminarsProvider = Provider.autoDispose<AsyncValue<List<Seminar>>>((ref) {
  return ref.watch(allSeminarsStreamProvider).whenData(
        (seminars) => seminars.where((s) => s.isPast && s.hasRecording).toList(),
      );
});

final seminarRegisteredProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, seminarId) {
  return ref.watch(contentServiceProvider).isRegistered(seminarId);
});
