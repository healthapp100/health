/// Mirrors public.health_articles (supabase/migrations/0007_content_library.sql) — Health
/// Knowledge Library, Blogs, and Medical News all share this one table via `contentType`.
class HealthArticle {
  final String id;
  final String slug;
  final String title;
  final String category;
  final String contentType; // 'article' | 'blog' | 'news'
  final String bodyMarkdown;
  final String? summary;
  final String? coverImageUrl;
  final DateTime? publishedAt;

  const HealthArticle({
    required this.id,
    required this.slug,
    required this.title,
    required this.category,
    required this.contentType,
    required this.bodyMarkdown,
    this.summary,
    this.coverImageUrl,
    this.publishedAt,
  });

  factory HealthArticle.fromJson(Map<String, dynamic> json) => HealthArticle(
        id: json['id'] as String,
        slug: json['slug'] as String,
        title: json['title'] as String,
        category: json['category'] as String,
        contentType: json['content_type'] as String,
        bodyMarkdown: json['body_markdown'] as String,
        summary: json['summary'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        publishedAt:
            json['published_at'] != null ? DateTime.parse(json['published_at'] as String) : null,
      );
}

/// Mirrors public.seminars — Online Seminars module.
class Seminar {
  final String id;
  final String title;
  final String? description;
  final String speakerName;
  final String? speakerBio;
  final DateTime scheduledAt;
  final String? joinUrl;
  final String? recordingUrl;

  const Seminar({
    required this.id,
    required this.title,
    this.description,
    required this.speakerName,
    this.speakerBio,
    required this.scheduledAt,
    this.joinUrl,
    this.recordingUrl,
  });

  factory Seminar.fromJson(Map<String, dynamic> json) => Seminar(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        speakerName: json['speaker_name'] as String,
        speakerBio: json['speaker_bio'] as String?,
        scheduledAt: DateTime.parse(json['scheduled_at'] as String),
        joinUrl: json['join_url'] as String?,
        recordingUrl: json['recording_url'] as String?,
      );

  bool get hasRecording => recordingUrl != null && recordingUrl!.isNotEmpty;
  bool get isPast => scheduledAt.isBefore(DateTime.now());
}

/// Mirrors public.seminar_registrations.
class SeminarRegistration {
  final String id;
  final String seminarId;
  final String patientId;
  final DateTime registeredAt;
  final bool reminded;

  const SeminarRegistration({
    required this.id,
    required this.seminarId,
    required this.patientId,
    required this.registeredAt,
    required this.reminded,
  });

  factory SeminarRegistration.fromJson(Map<String, dynamic> json) => SeminarRegistration(
        id: json['id'] as String,
        seminarId: json['seminar_id'] as String,
        patientId: json['patient_id'] as String,
        registeredAt: DateTime.parse(json['registered_at'] as String),
        reminded: json['reminded'] as bool? ?? false,
      );
}
