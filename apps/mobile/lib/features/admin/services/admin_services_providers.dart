import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/service_providers.dart';
import '../../../models/services_models.dart';

final adminMonitoringMessagesProvider =
    StreamProvider.autoDispose<List<MonitoringMessage>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllMessagesForAdmin();
});

final adminDailyVideosProvider = StreamProvider.autoDispose<List<DailyVideo>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllVideosForAdmin();
});

final adminLabDirectoryProvider = StreamProvider.autoDispose<List<LabDirectoryEntry>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllLabDirectoryForAdmin();
});

final adminHealthKitsProvider = StreamProvider.autoDispose<List<HealthKitEntry>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllHealthKitsForAdmin();
});

final adminMedicinesProvider = StreamProvider.autoDispose<List<MedicineInfo>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllMedicinesForAdmin();
});

final adminDoctorContactInfoProvider =
    StreamProvider.autoDispose<List<DoctorContactInfo>>((ref) {
  return ref.watch(servicesDirectoryServiceProvider).watchAllDoctorContactInfo();
});
