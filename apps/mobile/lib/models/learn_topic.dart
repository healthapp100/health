/// Mirrors public.learn_topics (supabase/migrations/0013_learn_topics.sql) — the top level of
/// the Learn module's Topic → Subtopic hierarchy (e.g. "Diabetes", "Blood Pressure").
class LearnTopic {
  final String id;
  final String slug;
  final String title;
  final String? summary;
  final String? icon;
  final String? coverImageUrl;
  final int sortOrder;
  final bool published;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearnTopic({
    required this.id,
    required this.slug,
    required this.title,
    this.summary,
    this.icon,
    this.coverImageUrl,
    required this.sortOrder,
    required this.published,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearnTopic.fromJson(Map<String, dynamic> json) => LearnTopic(
        id: json['id'] as String,
        slug: json['slug'] as String,
        title: json['title'] as String,
        summary: json['summary'] as String?,
        icon: json['icon'] as String?,
        coverImageUrl: json['cover_image_url'] as String?,
        sortOrder: json['sort_order'] as int? ?? 0,
        published: json['published'] as bool? ?? true,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'slug': slug,
        'title': title,
        if (summary != null) 'summary': summary,
        if (icon != null) 'icon': icon,
        if (coverImageUrl != null) 'cover_image_url': coverImageUrl,
        'sort_order': sortOrder,
        'published': published,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'slug': slug,
        'title': title,
        'summary': summary,
        'icon': icon,
        'cover_image_url': coverImageUrl,
        'sort_order': sortOrder,
        'published': published,
      };
}

/// A reference/attachment link shown alongside a subtopic's content — kept as a plain
/// label+url pair stored in the `external_links` jsonb array rather than a separate join table,
/// since a subtopic only ever has a handful of these.
class ExternalLink {
  final String label;
  final String url;
  const ExternalLink({required this.label, required this.url});

  factory ExternalLink.fromJson(Map<String, dynamic> json) => ExternalLink(
        label: json['label'] as String,
        url: json['url'] as String,
      );

  Map<String, dynamic> toJson() => {'label': label, 'url': url};
}

/// Mirrors public.learn_subtopics — each row IS a content page (e.g. "Definition", "Causes",
/// "Diet") under a topic; there's no further nesting beyond this.
class LearnSubtopic {
  final String id;
  final String topicId;
  final String slug;
  final String title;
  final int sortOrder;
  final bool published;
  final String? bodyMarkdown;
  final List<String> imageUrls;
  final List<String> pdfUrls;
  final List<ExternalLink> externalLinks;
  final String? youtubeUrl;
  final String? referencesText;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearnSubtopic({
    required this.id,
    required this.topicId,
    required this.slug,
    required this.title,
    required this.sortOrder,
    required this.published,
    this.bodyMarkdown,
    this.imageUrls = const [],
    this.pdfUrls = const [],
    this.externalLinks = const [],
    this.youtubeUrl,
    this.referencesText,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LearnSubtopic.fromJson(Map<String, dynamic> json) => LearnSubtopic(
        id: json['id'] as String,
        topicId: json['topic_id'] as String,
        slug: json['slug'] as String,
        title: json['title'] as String,
        sortOrder: json['sort_order'] as int? ?? 0,
        published: json['published'] as bool? ?? true,
        bodyMarkdown: json['body_markdown'] as String?,
        imageUrls: ((json['image_urls'] as List<dynamic>?) ?? []).cast<String>(),
        pdfUrls: ((json['pdf_urls'] as List<dynamic>?) ?? []).cast<String>(),
        externalLinks: ((json['external_links'] as List<dynamic>?) ?? [])
            .map((e) => ExternalLink.fromJson(e as Map<String, dynamic>))
            .toList(),
        youtubeUrl: json['youtube_url'] as String?,
        referencesText: json['references_text'] as String?,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'topic_id': topicId,
        'slug': slug,
        'title': title,
        'sort_order': sortOrder,
        'published': published,
        if (bodyMarkdown != null) 'body_markdown': bodyMarkdown,
        'image_urls': imageUrls,
        'pdf_urls': pdfUrls,
        'external_links': externalLinks.map((e) => e.toJson()).toList(),
        if (youtubeUrl != null) 'youtube_url': youtubeUrl,
        if (referencesText != null) 'references_text': referencesText,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'slug': slug,
        'title': title,
        'sort_order': sortOrder,
        'published': published,
        'body_markdown': bodyMarkdown,
        'image_urls': imageUrls,
        'pdf_urls': pdfUrls,
        'external_links': externalLinks.map((e) => e.toJson()).toList(),
        'youtube_url': youtubeUrl,
        'references_text': referencesText,
      };

  bool get hasContent =>
      (bodyMarkdown?.isNotEmpty ?? false) ||
      imageUrls.isNotEmpty ||
      pdfUrls.isNotEmpty ||
      externalLinks.isNotEmpty ||
      (youtubeUrl?.isNotEmpty ?? false);
}
