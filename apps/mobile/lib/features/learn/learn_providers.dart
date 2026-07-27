import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/content.dart';

final articlesProvider =
    FutureProvider.autoDispose.family<List<HealthArticle>, String?>((ref, category) {
  return ref.watch(contentServiceProvider).getArticles(category: category);
});

final upcomingSeminarsProvider = FutureProvider.autoDispose<List<Seminar>>((ref) {
  return ref.watch(contentServiceProvider).getUpcomingSeminars();
});

final articleBySlugProvider =
    FutureProvider.autoDispose.family<HealthArticle, String>((ref, slug) {
  return ref.watch(contentServiceProvider).getArticleBySlug(slug);
});
