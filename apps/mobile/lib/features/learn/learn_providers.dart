import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/content.dart';

final articlesProvider =
    FutureProvider.autoDispose.family<List<HealthArticle>, String?>((ref, category) {
  return ref.watch(contentServiceProvider).getArticles(category: category);
});

final articleSearchProvider =
    FutureProvider.autoDispose.family<List<HealthArticle>, String>((ref, query) {
  return ref.watch(contentServiceProvider).searchArticles(query);
});

final upcomingSeminarsProvider = FutureProvider.autoDispose<List<Seminar>>((ref) {
  return ref.watch(contentServiceProvider).getUpcomingSeminars();
});

final articleBySlugProvider =
    FutureProvider.autoDispose.family<HealthArticle, String>((ref, slug) {
  return ref.watch(contentServiceProvider).getArticleBySlug(slug);
});

final pastSeminarsProvider = FutureProvider.autoDispose<List<Seminar>>((ref) {
  return ref.watch(contentServiceProvider).getPastSeminarsWithRecordings();
});

final seminarRegisteredProvider =
    FutureProvider.autoDispose.family<bool, String>((ref, seminarId) {
  return ref.watch(contentServiceProvider).isRegistered(seminarId);
});
