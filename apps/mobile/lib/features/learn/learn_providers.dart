import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/content.dart';
import '../../models/learn_topic.dart';

final learnTopicsProvider = StreamProvider.autoDispose<List<LearnTopic>>((ref) {
  return ref.watch(learnContentServiceProvider).watchPublishedTopics();
});

final learnSubtopicsProvider =
    StreamProvider.autoDispose.family<List<LearnSubtopic>, String>((ref, topicId) {
  return ref.watch(learnContentServiceProvider).watchPublishedSubtopics(topicId);
});

final featuredBlogsProvider = FutureProvider.autoDispose<List<HealthArticle>>((ref) {
  return ref.watch(contentServiceProvider).getFeaturedArticles();
});

final learnTopicByIdProvider =
    FutureProvider.autoDispose.family<LearnTopic, String>((ref, topicId) {
  return ref.watch(learnContentServiceProvider).getTopicById(topicId);
});

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

/// One shared subscription for every seminar the current patient is registered to — avoids an
/// N+1 query pattern in the seminars list (one `isRegistered` call per row).
final ownRegisteredSeminarIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  return ref.watch(contentServiceProvider).watchOwnRegisteredSeminarIds();
});
