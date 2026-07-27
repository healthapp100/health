import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/service_providers.dart';
import '../../models/profile.dart';

final ownProfileProvider = FutureProvider.autoDispose<Profile>((ref) {
  return ref.watch(profileServiceProvider).getOwnProfile();
});

final dependentsProvider = FutureProvider.autoDispose<List<CareRelationship>>((ref) {
  return ref.watch(profileServiceProvider).getDependents();
});

final consentStateProvider = FutureProvider.autoDispose<Map<String, bool>>((ref) {
  return ref.watch(consentServiceProvider).getCurrentConsentState();
});
