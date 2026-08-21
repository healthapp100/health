import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/services_models.dart';

/// Backs the Services module's sub-sections: Daily Monitoring messages, Daily Videos, and the
/// Lab/Health-Kit/Medicine/Doctor-contact reference directories (0016_services_module.sql).
class ServicesDirectoryService {
  final SupabaseClient _client;
  const ServicesDirectoryService(this._client);

  String get _userId => _client.auth.currentUser!.id;

  // ---- Daily Monitoring messages ----

  /// Own targeted messages plus every broadcast message — matches the RLS select policy
  /// (`patient_id is null or patient_id = auth.uid()`) exactly, so this stream never needs a
  /// second query to merge two result sets.
  Stream<List<MonitoringMessage>> watchOwnMessages() {
    return _client
        .from('monitoring_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MonitoringMessage.fromJson).toList());
  }

  Future<MonitoringMessage> createMonitoringMessage(MonitoringMessage message) async {
    final row = await _client
        .from('monitoring_messages')
        .insert(message.toInsertJson(_userId))
        .select()
        .single();
    return MonitoringMessage.fromJson(row);
  }

  Future<void> deleteMonitoringMessage(String id) async {
    await _client.from('monitoring_messages').delete().eq('id', id);
  }

  Stream<List<MonitoringMessage>> watchAllMessagesForAdmin() {
    return _client
        .from('monitoring_messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MonitoringMessage.fromJson).toList());
  }

  // ---- Daily Videos ----

  Stream<List<DailyVideo>> watchVisibleVideos() {
    return _client
        .from('daily_videos')
        .stream(primaryKey: ['id'])
        .order('publish_at', ascending: false)
        .map((rows) => rows.map(DailyVideo.fromJson).where((v) => v.isCurrentlyVisible).toList());
  }

  Stream<List<DailyVideo>> watchAllVideosForAdmin() {
    return _client
        .from('daily_videos')
        .stream(primaryKey: ['id'])
        .order('publish_at', ascending: false)
        .map((rows) => rows.map(DailyVideo.fromJson).toList());
  }

  Future<DailyVideo> createVideo(DailyVideo video) async {
    final row =
        await _client.from('daily_videos').insert(video.toInsertJson(_userId)).select().single();
    return DailyVideo.fromJson(row);
  }

  Future<void> updateVideo(String id, DailyVideo video) async {
    await _client.from('daily_videos').update(video.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteVideo(String id) async {
    await _client.from('daily_videos').delete().eq('id', id);
  }

  // ---- Lab directory ----

  Stream<List<LabDirectoryEntry>> watchPublishedLabDirectory() {
    return _client
        .from('lab_directory')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(LabDirectoryEntry.fromJson).where((e) => e.published).toList());
  }

  Stream<List<LabDirectoryEntry>> watchAllLabDirectoryForAdmin() {
    return _client
        .from('lab_directory')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(LabDirectoryEntry.fromJson).toList());
  }

  Future<LabDirectoryEntry> createLabEntry(LabDirectoryEntry entry) async {
    final row = await _client
        .from('lab_directory')
        .insert(entry.toInsertJson(_userId))
        .select()
        .single();
    return LabDirectoryEntry.fromJson(row);
  }

  Future<void> updateLabEntry(String id, LabDirectoryEntry entry) async {
    await _client.from('lab_directory').update(entry.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteLabEntry(String id) async {
    await _client.from('lab_directory').delete().eq('id', id);
  }

  // ---- Health kit directory ----

  Stream<List<HealthKitEntry>> watchPublishedHealthKits() {
    return _client
        .from('health_kit_directory')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(HealthKitEntry.fromJson).where((e) => e.published).toList());
  }

  Stream<List<HealthKitEntry>> watchAllHealthKitsForAdmin() {
    return _client
        .from('health_kit_directory')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(HealthKitEntry.fromJson).toList());
  }

  Future<HealthKitEntry> createHealthKit(HealthKitEntry entry) async {
    final row = await _client
        .from('health_kit_directory')
        .insert(entry.toInsertJson(_userId))
        .select()
        .single();
    return HealthKitEntry.fromJson(row);
  }

  Future<void> updateHealthKit(String id, HealthKitEntry entry) async {
    await _client.from('health_kit_directory').update(entry.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteHealthKit(String id) async {
    await _client.from('health_kit_directory').delete().eq('id', id);
  }

  // ---- Medicine info ----

  Stream<List<MedicineInfo>> watchPublishedMedicines() {
    return _client
        .from('medicine_info')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(MedicineInfo.fromJson).where((e) => e.published).toList());
  }

  Stream<List<MedicineInfo>> watchAllMedicinesForAdmin() {
    return _client
        .from('medicine_info')
        .stream(primaryKey: ['id'])
        .order('name')
        .map((rows) => rows.map(MedicineInfo.fromJson).toList());
  }

  Future<MedicineInfo> createMedicine(MedicineInfo entry) async {
    final row = await _client
        .from('medicine_info')
        .insert(entry.toInsertJson(_userId))
        .select()
        .single();
    return MedicineInfo.fromJson(row);
  }

  Future<void> updateMedicine(String id, MedicineInfo entry) async {
    await _client.from('medicine_info').update(entry.toUpdateJson()).eq('id', id);
  }

  Future<void> deleteMedicine(String id) async {
    await _client.from('medicine_info').delete().eq('id', id);
  }

  // ---- Doctor contact info ----

  Future<DoctorContactInfo?> getDoctorContactInfo(String providerProfileId) async {
    final rows = await _client
        .from('doctor_contact_info')
        .select()
        .eq('provider_profile_id', providerProfileId)
        .eq('published', true)
        .limit(1);
    final list = rows as List<dynamic>;
    return list.isEmpty ? null : DoctorContactInfo.fromJson(list.first as Map<String, dynamic>);
  }

  Stream<List<DoctorContactInfo>> watchAllDoctorContactInfoForAdmin() {
    return _client
        .from('doctor_contact_info')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(DoctorContactInfo.fromJson).toList());
  }

  Future<void> upsertDoctorContactInfo(DoctorContactInfo info) async {
    if (info.id.isEmpty) {
      await _client.from('doctor_contact_info').insert(info.toInsertJson(_userId));
    } else {
      await _client.from('doctor_contact_info').update(info.toUpdateJson()).eq('id', info.id);
    }
  }
}
