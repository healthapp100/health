import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/content.dart';

final adminArticlesProvider =
    StreamProvider.autoDispose.family<List<HealthArticle>, String?>((ref, contentType) {
  return ref.watch(contentServiceProvider).watchAllArticlesForAdmin(contentType: contentType);
});
