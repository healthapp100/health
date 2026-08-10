import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/learn_topic.dart';

/// Learn module CMS (public.learn_topics / public.learn_subtopics — 0013_learn_topics.sql).
/// Read methods are used by the patient-facing browsing screens; the same write methods back
/// the admin authoring screens — RLS (`is_staff()`) is the actual enforcement, this service
/// doesn't duplicate that check client-side.
class LearnContentService {
  final SupabaseClient _client;
  const LearnContentService(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ---- Patient-facing reads (published only, via RLS) ----

  Stream<List<LearnTopic>> watchPublishedTopics() {
    return _client
        .from('learn_topics')
        .stream(primaryKey: ['id'])
        .order('sort_order')
        .map((rows) => rows.map(LearnTopic.fromJson).where((t) => t.published).toList());
  }

  Stream<List<LearnSubtopic>> watchPublishedSubtopics(String topicId) {
    return _client
        .from('learn_subtopics')
        .stream(primaryKey: ['id'])
        .eq('topic_id', topicId)
        .order('sort_order')
        .map((rows) => rows.map(LearnSubtopic.fromJson).where((s) => s.published).toList());
  }

  Future<LearnTopic> getTopicById(String id) async {
    final row = await _client.from('learn_topics').select().eq('id', id).single();
    return LearnTopic.fromJson(row);
  }

  // ---- Admin reads (including unpublished drafts) ----

  Stream<List<LearnTopic>> watchAllTopicsForAdmin() {
    return _client
        .from('learn_topics')
        .stream(primaryKey: ['id'])
        .order('sort_order')
        .map((rows) => rows.map(LearnTopic.fromJson).toList());
  }

  Stream<List<LearnSubtopic>> watchAllSubtopicsForAdmin(String topicId) {
    return _client
        .from('learn_subtopics')
        .stream(primaryKey: ['id'])
        .eq('topic_id', topicId)
        .order('sort_order')
        .map((rows) => rows.map(LearnSubtopic.fromJson).toList());
  }

  // ---- Admin writes ----

  Future<LearnTopic> createTopic(LearnTopic topic) async {
    final row = await _client
        .from('learn_topics')
        .insert(topic.toInsertJson(_userId))
        .select()
        .single();
    return LearnTopic.fromJson(row);
  }

  Future<void> updateTopic(String id, LearnTopic topic) async {
    await _client.from('learn_topics').update(topic.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteTopic(String id) async {
    await _client.from('learn_topics').delete().eq('id', id);
  }

  Future<void> reorderTopics(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _client.from('learn_topics').update({'sort_order': i}).eq('id', orderedIds[i]);
    }
  }

  Future<LearnSubtopic> createSubtopic(LearnSubtopic subtopic) async {
    final row = await _client
        .from('learn_subtopics')
        .insert(subtopic.toInsertJson(_userId))
        .select()
        .single();
    return LearnSubtopic.fromJson(row);
  }

  Future<void> updateSubtopic(String id, LearnSubtopic subtopic) async {
    await _client.from('learn_subtopics').update(subtopic.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteSubtopic(String id) async {
    await _client.from('learn_subtopics').delete().eq('id', id);
  }

  Future<void> reorderSubtopics(List<String> orderedIds) async {
    for (var i = 0; i < orderedIds.length; i++) {
      await _client.from('learn_subtopics').update({'sort_order': i}).eq('id', orderedIds[i]);
    }
  }
}
