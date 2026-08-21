/// Mirrors public.health_articles (0007_content_library.sql + 0014_blogs_extend.sql) — Health
/// Knowledge Library, Blogs, and Medical News all share this one table via `contentType`.
/// `publishedAt` doubles as scheduled publish: the RLS policy hides a row until that instant.
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
  final bool featured;
  final List<String> tags;
  final String? externalLink;
  final String? youtubeUrl;

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
    this.featured = false,
    this.tags = const [],
    this.externalLink,
    this.youtubeUrl,
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
        featured: json['featured'] as bool? ?? false,
        tags: ((json['tags'] as List<dynamic>?) ?? []).cast<String>(),
        externalLink: json['external_link'] as String?,
        youtubeUrl: json['youtube_url'] as String?,
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'slug': slug,
        'title': title,
        'category': category,
        'content_type': contentType,
        'body_markdown': bodyMarkdown,
        if (summary != null) 'summary': summary,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        if (publishedAt != null) 'published_at': publishedAt!.toUtc().toIso8601String(),
        'featured': featured,
        'tags': tags,
        if (externalLink != null) 'external_link': externalLink,
        if (youtubeUrl != null) 'youtube_url': youtubeUrl,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'slug': slug,
        'title': title,
        'category': category,
        'content_type': contentType,
        'body_markdown': bodyMarkdown,
        'summary': summary,
        'cover_image_url': coverImageUrl,
        'published_at': publishedAt?.toUtc().toIso8601String(),
        'featured': featured,
        'tags': tags,
        'external_link': externalLink,
        'youtube_url': youtubeUrl,
      };
}

/// Mirrors public.seminars (0007 + 0015_seminars_extend.sql) — Online and Offline Seminars.
class Seminar {
  final String id;
  final String title;
  final String? description;
  final String speakerName;
  final String? speakerBio;
  final DateTime scheduledAt;
  final String? joinUrl;
  final String? recordingUrl;
  final String mode; // 'online' | 'offline'
  final int? durationMinutes;
  final String? meetingPassword;
  final String? venue;
  final String? bannerUrl;
  final int? registrationLimit;
  final String status; // 'scheduled' | 'cancelled' | 'completed'
  final String? notes;

  const Seminar({
    required this.id,
    required this.title,
    this.description,
    required this.speakerName,
    this.speakerBio,
    required this.scheduledAt,
    this.joinUrl,
    this.recordingUrl,
    this.mode = 'online',
    this.durationMinutes,
    this.meetingPassword,
    this.venue,
    this.bannerUrl,
    this.registrationLimit,
    this.status = 'scheduled',
    this.notes,
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
        mode: json['mode'] as String? ?? 'online',
        durationMinutes: json['duration_minutes'] as int?,
        meetingPassword: json['meeting_password'] as String?,
        venue: json['venue'] as String?,
        bannerUrl: json['banner_url'] as String?,
        registrationLimit: json['registration_limit'] as int?,
        status: json['status'] as String? ?? 'scheduled',
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'title': title,
        if (description != null) 'description': description,
        'speaker_name': speakerName,
        if (speakerBio != null) 'speaker_bio': speakerBio,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        if (joinUrl != null) 'join_url': joinUrl,
        if (recordingUrl != null) 'recording_url': recordingUrl,
        'mode': mode,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (meetingPassword != null) 'meeting_password': meetingPassword,
        if (venue != null) 'venue': venue,
        if (bannerUrl != null) 'banner_url': bannerUrl,
        if (registrationLimit != null) 'registration_limit': registrationLimit,
        'status': status,
        if (notes != null) 'notes': notes,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'speaker_name': speakerName,
        'speaker_bio': speakerBio,
        'scheduled_at': scheduledAt.toUtc().toIso8601String(),
        'join_url': joinUrl,
        'recording_url': recordingUrl,
        'mode': mode,
        'duration_minutes': durationMinutes,
        'meeting_password': meetingPassword,
        'venue': venue,
        'banner_url': bannerUrl,
        'registration_limit': registrationLimit,
        'status': status,
        'notes': notes,
      };

  bool get hasRecording => recordingUrl != null && recordingUrl!.isNotEmpty;
  bool get isPast => scheduledAt.isBefore(DateTime.now());
  bool get isOnline => mode == 'online';
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
