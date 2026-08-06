import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// True when the device has no network path at all. This is a coarse, client-side signal (it
/// doesn't confirm Supabase itself is reachable) — good enough to distinguish "you're offline,
/// here's what we last synced" from a genuine server error, which is the actual UX gap this
/// closes: every screen previously showed the same generic ErrorState for both.
final isOfflineProvider = StreamProvider<bool>((ref) async* {
  yield (await Connectivity().checkConnectivity()).every((r) => r == ConnectivityResult.none);
  yield* Connectivity()
      .onConnectivityChanged
      .map((results) => results.every((r) => r == ConnectivityResult.none));
});
