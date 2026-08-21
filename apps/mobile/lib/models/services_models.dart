/// Mirrors public.monitoring_messages (0016_services_module.sql). `patientId == null` is a
/// broadcast message visible to every patient; otherwise it's targeted to just that one.
class MonitoringMessage {
  final String id;
  final String? patientId;
  final String title;
  final String body;
  final String createdBy;
  final DateTime createdAt;

  const MonitoringMessage({
    required this.id,
    this.patientId,
    required this.title,
    required this.body,
    required this.createdBy,
    required this.createdAt,
  });

  factory MonitoringMessage.fromJson(Map<String, dynamic> json) => MonitoringMessage(
        id: json['id'] as String,
        patientId: json['patient_id'] as String?,
        title: json['title'] as String,
        body: json['body'] as String,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        if (patientId != null) 'patient_id': patientId,
        'title': title,
        'body': body,
        'created_by': creatorId,
      };

  bool get isBroadcast => patientId == null;
}

/// Mirrors public.daily_videos. `isCurrentlyVisible` mirrors the RLS window
/// (`publish_at <= now() and (expires_at is null or expires_at > now())`) for client-side display
/// logic (e.g. an admin's own list, which sees rows outside that window too).
class DailyVideo {
  final String id;
  final String title;
  final String? description;
  final String videoUrl;
  final String? thumbnailUrl;
  final DateTime publishAt;
  final DateTime? expiresAt;
  final String createdBy;
  final DateTime createdAt;

  const DailyVideo({
    required this.id,
    required this.title,
    this.description,
    required this.videoUrl,
    this.thumbnailUrl,
    required this.publishAt,
    this.expiresAt,
    required this.createdBy,
    required this.createdAt,
  });

  factory DailyVideo.fromJson(Map<String, dynamic> json) => DailyVideo(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        videoUrl: json['video_url'] as String,
        thumbnailUrl: json['thumbnail_url'] as String?,
        publishAt: DateTime.parse(json['publish_at'] as String),
        expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
        createdBy: json['created_by'] as String,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'title': title,
        if (description != null) 'description': description,
        'video_url': videoUrl,
        if (thumbnailUrl != null) 'thumbnail_url': thumbnailUrl,
        'publish_at': publishAt.toUtc().toIso8601String(),
        if (expiresAt != null) 'expires_at': expiresAt!.toUtc().toIso8601String(),
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'title': title,
        'description': description,
        'video_url': videoUrl,
        'thumbnail_url': thumbnailUrl,
        'publish_at': publishAt.toUtc().toIso8601String(),
        'expires_at': expiresAt?.toUtc().toIso8601String(),
      };

  bool get isCurrentlyVisible {
    final now = DateTime.now();
    return !publishAt.isAfter(now) && (expiresAt == null || expiresAt!.isAfter(now));
  }

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());
}

/// Mirrors public.lab_directory — Laboratory Test Support's browsable clinic/diagnostic-center
/// directory (distinct from public.lab_orders, which is the patient's own booked tests).
class LabDirectoryEntry {
  final String id;
  final String name;
  final String kind; // 'clinic' | 'diagnostic_center'
  final String? doctorName;
  final String? contactPhone;
  final String? contactEmail;
  final String? address;
  final String? services;
  final String? timings;
  final String? externalLink;
  final bool published;

  const LabDirectoryEntry({
    required this.id,
    required this.name,
    required this.kind,
    this.doctorName,
    this.contactPhone,
    this.contactEmail,
    this.address,
    this.services,
    this.timings,
    this.externalLink,
    required this.published,
  });

  factory LabDirectoryEntry.fromJson(Map<String, dynamic> json) => LabDirectoryEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        kind: json['kind'] as String? ?? 'diagnostic_center',
        doctorName: json['doctor_name'] as String?,
        contactPhone: json['contact_phone'] as String?,
        contactEmail: json['contact_email'] as String?,
        address: json['address'] as String?,
        services: json['services'] as String?,
        timings: json['timings'] as String?,
        externalLink: json['external_link'] as String?,
        published: json['published'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'name': name,
        'kind': kind,
        if (doctorName != null) 'doctor_name': doctorName,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (contactEmail != null) 'contact_email': contactEmail,
        if (address != null) 'address': address,
        if (services != null) 'services': services,
        if (timings != null) 'timings': timings,
        if (externalLink != null) 'external_link': externalLink,
        'published': published,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'kind': kind,
        'doctor_name': doctorName,
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'address': address,
        'services': services,
        'timings': timings,
        'external_link': externalLink,
        'published': published,
      };
}

/// Mirrors public.health_kit_directory — devices/kits/equipment patients can purchase.
class HealthKitEntry {
  final String id;
  final String name;
  final String category; // 'device' | 'kit' | 'equipment'
  final String? description;
  final String? supplierName;
  final String? purchaseLink;
  final String? instructions;
  final String? imageUrl;
  final bool published;

  const HealthKitEntry({
    required this.id,
    required this.name,
    required this.category,
    this.description,
    this.supplierName,
    this.purchaseLink,
    this.instructions,
    this.imageUrl,
    required this.published,
  });

  factory HealthKitEntry.fromJson(Map<String, dynamic> json) => HealthKitEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'device',
        description: json['description'] as String?,
        supplierName: json['supplier_name'] as String?,
        purchaseLink: json['purchase_link'] as String?,
        instructions: json['instructions'] as String?,
        imageUrl: json['image_url'] as String?,
        published: json['published'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'name': name,
        'category': category,
        if (description != null) 'description': description,
        if (supplierName != null) 'supplier_name': supplierName,
        if (purchaseLink != null) 'purchase_link': purchaseLink,
        if (instructions != null) 'instructions': instructions,
        if (imageUrl != null) 'image_url': imageUrl,
        'published': published,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category,
        'description': description,
        'supplier_name': supplierName,
        'purchase_link': purchaseLink,
        'instructions': instructions,
        'image_url': imageUrl,
        'published': published,
      };
}

/// Mirrors public.medicine_info — educational/reference info, not a purchase/dispensing flow
/// (BLUEPRINT.md §3.4 keeps that out of scope pending e-pharmacy regulatory review).
class MedicineInfo {
  final String id;
  final String name;
  final String? category;
  final String? description;
  final String? recommendations;
  final String? externalLink;
  final bool published;

  const MedicineInfo({
    required this.id,
    required this.name,
    this.category,
    this.description,
    this.recommendations,
    this.externalLink,
    required this.published,
  });

  factory MedicineInfo.fromJson(Map<String, dynamic> json) => MedicineInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String?,
        description: json['description'] as String?,
        recommendations: json['recommendations'] as String?,
        externalLink: json['external_link'] as String?,
        published: json['published'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'name': name,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (recommendations != null) 'recommendations': recommendations,
        if (externalLink != null) 'external_link': externalLink,
        'published': published,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'name': name,
        'category': category,
        'description': description,
        'recommendations': recommendations,
        'external_link': externalLink,
        'published': published,
      };
}

/// Mirrors public.doctor_contact_info — supplementary contact/availability details shown
/// alongside a provider's existing provider_directory card; booking itself is unaffected.
class DoctorContactInfo {
  final String id;
  final String providerProfileId;
  final String? contactPhone;
  final String? contactEmail;
  final String? consultationFee;
  final String? availability;
  final String? notes;
  final bool published;

  const DoctorContactInfo({
    required this.id,
    required this.providerProfileId,
    this.contactPhone,
    this.contactEmail,
    this.consultationFee,
    this.availability,
    this.notes,
    required this.published,
  });

  factory DoctorContactInfo.fromJson(Map<String, dynamic> json) => DoctorContactInfo(
        id: json['id'] as String,
        providerProfileId: json['provider_profile_id'] as String,
        contactPhone: json['contact_phone'] as String?,
        contactEmail: json['contact_email'] as String?,
        consultationFee: json['consultation_fee'] as String?,
        availability: json['availability'] as String?,
        notes: json['notes'] as String?,
        published: json['published'] as bool? ?? true,
      );

  Map<String, dynamic> toInsertJson(String creatorId) => {
        'provider_profile_id': providerProfileId,
        if (contactPhone != null) 'contact_phone': contactPhone,
        if (contactEmail != null) 'contact_email': contactEmail,
        if (consultationFee != null) 'consultation_fee': consultationFee,
        if (availability != null) 'availability': availability,
        if (notes != null) 'notes': notes,
        'published': published,
        'created_by': creatorId,
      };

  Map<String, dynamic> toUpdateJson() => {
        'contact_phone': contactPhone,
        'contact_email': contactEmail,
        'consultation_fee': consultationFee,
        'availability': availability,
        'notes': notes,
        'published': published,
      };
}
