import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/learn_topic.dart';

/// Admin views include unpublished drafts (unlike the patient-facing learnTopicsProvider in
/// features/learn/learn_providers.dart, which only ever sees published rows via RLS) — kept as
/// separate providers rather than one shared provider with a "show drafts" flag, since mixing
/// admin and patient query shapes in one provider makes it easy to accidentally leak drafts.
final adminTopicsProvider = StreamProvider.autoDispose<List<LearnTopic>>((ref) {
  return ref.watch(learnContentServiceProvider).watchAllTopicsForAdmin();
});

final adminSubtopicsProvider =
    StreamProvider.autoDispose.family<List<LearnSubtopic>, String>((ref, topicId) {
  return ref.watch(learnContentServiceProvider).watchAllSubtopicsForAdmin(topicId);
});

/// Lowercase, hyphenated slug from a title — used as the default when an admin hasn't
/// hand-edited the slug field themselves.
String slugify(String input) {
  final lower = input.trim().toLowerCase();
  final hyphenated = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  return hyphenated.replaceAll(RegExp(r'^-+|-+$'), '');
}
