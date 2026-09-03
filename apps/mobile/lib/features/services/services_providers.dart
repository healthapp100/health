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

/// One shared subscription for every doctor's contact info, keyed into a map — used by Care's
/// provider list so displaying N providers costs one query, not N (see
/// ServicesDirectoryService.watchAllDoctorContactInfo's doc comment for why this single stream
/// is RLS-safe for a plain patient too, not just admin).
final allDoctorContactInfoProvider = StreamProvider.autoDispose<Map<String, DoctorContactInfo>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllDoctorContactInfo().map(
        (list) => {for (final info in list) info.providerProfileId: info},
      );
});
