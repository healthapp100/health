import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/services_models.dart';

final ownMonitoringMessagesProvider = StreamProvider.autoDispose<List<MonitoringMessage>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchOwnMessages();
});

final visibleDailyVideosProvider = StreamProvider.autoDispose<List<DailyVideo>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchVisibleVideos();
});

final labDirectoryProvider = StreamProvider.autoDispose<List<LabDirectoryEntry>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchPublishedLabDirectory();
});

final healthKitDirectoryProvider = StreamProvider.autoDispose<List<HealthKitEntry>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchPublishedHealthKits();
});

final medicineInfoProvider = StreamProvider.autoDispose<List<MedicineInfo>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchPublishedMedicines();
});

final doctorContactInfoProvider =
    FutureProvider.autoDispose.family<DoctorContactInfo?, String>((ref, providerProfileId) {
  return ref.watch(servicesDirectoryServiceProvider).getDoctorContactInfo(providerProfileId);
});
