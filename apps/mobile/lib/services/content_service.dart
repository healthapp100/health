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

  /// Featured strip shown at the top of the Blogs section — small and un-paginated by design
  /// (an editorial highlight list is meant to stay short; if it ever needs paging, that's a
  /// product-scope change, not just a query-shape one).
  Future<List<HealthArticle>> getFeaturedArticles({String contentType = 'blog'}) async {
    final rows = await _client
        .from('health_articles')
        .select()
        .eq('content_type', contentType)
        .eq('featured', true)
        .order('published_at', ascending: false)
        .limit(10);
    return (rows as List<dynamic>)
        .map((r) => HealthArticle.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ---- Admin: authoring (blogs/articles/news share this one table+form) ----

  String get _userId => _client.auth.currentUser!.id;

  Stream<List<HealthArticle>> watchAllArticlesForAdmin({String? contentType}) {
    var query = _client.from('health_articles').stream(primaryKey: ['id']);
    return query
        .order('created_at', ascending: false)
        .map(
          (rows) => rows
              .map(HealthArticle.fromJson)
              .where((a) => contentType == null || a.contentType == contentType)
              .toList(),
        );
  }

  Future<HealthArticle> createArticle(HealthArticle article) async {
    final row = await _client
        .from('health_articles')
        .insert(article.toInsertJson(_userId))
        .select()
        .single();
    return HealthArticle.fromJson(row);
  }

  Future<void> updateArticle(String id, HealthArticle article) async {
    await _client.from('health_articles').update(article.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteArticle(String id) async {
    await _client.from('health_articles').delete().eq('id', id);
  }

  Future<void> setPublished(String id, bool published) async {
    await _client
        .from('health_articles')
        .update({'published_at': published ? DateTime.now().toUtc().toIso8601String() : null})
        .eq('id', id);
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

  /// [registrationLimit] is checked client-side before the insert — not airtight against a
  /// last-second race between two patients registering simultaneously (that would need a
  /// database-level check constraint or trigger), but sufficient at this app's registration
  /// volume, and consistent with how reordering elsewhere in this codebase favors a simple
  /// client-side approach over heavier server-side guarantees.
  Future<void> registerForSeminar(String seminarId, {int? registrationLimit}) async {
    if (registrationLimit != null) {
      final current = await getRegistrationCount(seminarId);
      if (current >= registrationLimit) {
        throw StateError('This seminar is fully booked.');
      }
    }
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

  Future<int> getRegistrationCount(String seminarId) async {
    final rows = await _client
        .from('seminar_registrations')
        .select('id')
        .eq('seminar_id', seminarId);
    return (rows as List<dynamic>).length;
  }

  // ---- Admin: seminar authoring ----

  Future<Seminar> createSeminar(Seminar seminar) async {
    final row = await _client
        .from('seminars')
        .insert(seminar.toInsertJson(_userId))
        .select()
        .single();
    return Seminar.fromJson(row);
  }

  Future<void> updateSeminar(String id, Seminar seminar) async {
    await _client.from('seminars').update(seminar.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteSeminar(String id) async {
    await _client.from('seminars').delete().eq('id', id);
  }
}
