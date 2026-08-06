import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/content.dart';

/// Health Knowledge Library, Blogs, Medical News, and Online Seminars — all public read, no
/// auth required for browsing (supabase/migrations/0007's RLS: published rows are open to
/// everyone, including `Guest` per BLUEPRINT.md §5.2's role list).
class ContentService {
  final SupabaseClient _client;
  const ContentService(this._client);

  /// Page-based (not unbounded) — a category with hundreds of articles should never pull them
  /// all into memory at once. Callers page through via [offset]; [pageSize] rows are requested,
  /// so the caller can tell "more exist" from `results.length == pageSize`.
  static const defaultPageSize = 20;

  Future<List<HealthArticle>> getArticles({
    String? category,
    String contentType = 'article',
    int offset = 0,
    int pageSize = defaultPageSize,
  }) async {
    var query = _client.from('health_articles').select().eq('content_type', contentType);
    if (category != null) {
      query = query.eq('category', category);
    }
    final rows = await query
        .order('published_at', ascending: false)
        .range(offset, offset + pageSize - 1);
    return (rows as List<dynamic>)
        .map((r) => HealthArticle.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  /// Free-text search across title/summary — powers the Learn tab's search-first browsing
  /// (replacing a wall of 22 always-visible category chips with search + a handful of curated
  /// categories, per the world-class-redesign research pass).
  Future<List<HealthArticle>> searchArticles(
    String query, {
    String contentType = 'article',
    int offset = 0,
    int pageSize = defaultPageSize,
  }) async {
    final escaped = query.replaceAll('%', '');
    final rows = await _client
        .from('health_articles')
        .select()
        .eq('content_type', contentType)
        .or('title.ilike.%$escaped%,summary.ilike.%$escaped%')
        .order('published_at', ascending: false)
        .range(offset, offset + pageSize - 1);
    return (rows as List<dynamic>)
        .map((r) => HealthArticle.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  Future<HealthArticle> getArticleBySlug(String slug) async {
    final row = await _client.from('health_articles').select().eq('slug', slug).single();
    return HealthArticle.fromJson(row);
  }

  /// Live view of all seminars, newest-scheduled first — the caller splits into upcoming/past
  /// client-side (no per-patient filter needed here since `seminars: public read all` has no
  /// row-level scoping), so a newly-published seminar or an added recording appears without a
  /// manual refresh.
  Stream<List<Seminar>> watchAllSeminars() {
    return _client
        .from('seminars')
        .stream(primaryKey: ['id'])
        .order('scheduled_at', ascending: false)
        .map((rows) => rows.map(Seminar.fromJson).toList());
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
