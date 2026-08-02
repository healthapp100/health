import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content.dart';

/// Health Knowledge Library, Blogs, Medical News, and Online Seminars — all public read, no
/// auth required for browsing (supabase/migrations/0007's RLS: published rows are open to
/// everyone, including `Guest` per BLUEPRINT.md §5.2's role list).
class ContentService {
  final SupabaseClient _client;
  const ContentService(this._client);

  Future<List<HealthArticle>> getArticles({String? category, String contentType = 'article'}) async {
    var query = _client.from('health_articles').select().eq('content_type', contentType);
    if (category != null) {
      query = query.eq('category', category);
    }
    final rows = await query.order('published_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => HealthArticle.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<HealthArticle> getArticleBySlug(String slug) async {
    final row = await _client.from('health_articles').select().eq('slug', slug).single();
    return HealthArticle.fromJson(row);
  }

  Future<List<Seminar>> getUpcomingSeminars() async {
    final rows = await _client
        .from('seminars')
        .select()
        .gte('scheduled_at', DateTime.now().toUtc().toIso8601String())
        .order('scheduled_at');
    return (rows as List<dynamic>).map((r) => Seminar.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Seminar>> getPastSeminarsWithRecordings() async {
    final rows = await _client
        .from('seminars')
        .select()
        .lt('scheduled_at', DateTime.now().toUtc().toIso8601String())
        .not('recording_url', 'is', null)
        .order('scheduled_at', ascending: false);
    return (rows as List<dynamic>).map((r) => Seminar.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<void> registerForSeminar(String seminarId) async {
    final patientId = _client.auth.currentUser!.id;
    await _client.from('seminar_registrations').insert({
      'seminar_id': seminarId,
      'patient_id': patientId,
    });
  }

  Future<bool> isRegistered(String seminarId) async {
    final patientId = _client.auth.currentUser!.id;
    final rows = await _client
        .from('seminar_registrations')
        .select('id')
        .eq('seminar_id', seminarId)
        .eq('patient_id', patientId)
        .limit(1);
    return (rows as List<dynamic>).isNotEmpty;
  }

  Future<void> cancelRegistration(String seminarId) async {
    final patientId = _client.auth.currentUser!.id;
    await _client
        .from('seminar_registrations')
        .delete()
        .eq('seminar_id', seminarId)
        .eq('patient_id', patientId);
  }
}
