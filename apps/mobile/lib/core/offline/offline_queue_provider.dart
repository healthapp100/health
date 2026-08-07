import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../providers/connectivity_provider.dart';
import '../providers/service_providers.dart';
import 'offline_queue_service.dart';

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) => OfflineQueueService());

/// Bumped after every successful replay so any UI watching it (e.g. a "N changes pending sync"
/// badge) invalidates and re-reads the queue — plain int counter, not the data itself.
final _pendingQueueVersionProvider = StateProvider<int>((ref) => 0);

final pendingQueueCountProvider = FutureProvider.autoDispose<int>((ref) {
  ref.watch(_pendingQueueVersionProvider);
  return ref.watch(offlineQueueServiceProvider).pendingCount();
});

/// Operation-type constants shared between the enqueue call site and the replay switch below —
/// a typo in either place fails loudly (unknown case) rather than silently never replaying.
class OfflineOp {
  OfflineOp._();
  static const logVital = 'log_vital';
}

/// A `Provider` (not autoDispose) so Riverpod constructs [OfflineQueueProcessor] exactly once per
/// app lifetime and reuses that instance — the constructor registers a `ref.listen` callback, so
/// constructing it again on every rebuild would stack duplicate listeners. main.dart just
/// `ref.watch`es this once to trigger that one-time construction.
final offlineQueueProcessorProvider = Provider<OfflineQueueProcessor>((ref) {
  return OfflineQueueProcessor(ref);
});

/// Watches connectivity and replays queued writes the moment the device comes back online.
/// Wired once, app-wide, from main.dart — mirrors the pattern used for the session-expiration
/// listener (both are "react to a stream, no widget of their own").
class OfflineQueueProcessor {
  final Ref ref;
  bool _wasOffline = false;

  OfflineQueueProcessor(this.ref) {
    ref.listen(isOfflineProvider, (previous, next) {
      final isOffline = next.valueOrNull ?? false;
      if (_wasOffline && !isOffline) {
        _processQueue();
      }
      _wasOffline = isOffline;
    });
  }

  Future<void> _processQueue() async {
    final queue = ref.read(offlineQueueServiceProvider);
    if (!queue.isSupported) return;
    final pending = await queue.getPending();
    for (final item in pending) {
      try {
        await _replay(item);
        await queue.remove(item.id);
      } catch (_) {
        // Still failing (e.g. briefly online then dropped again, or a real server error) —
        // leave it queued; the next online transition retries it.
      }
    }
    ref.read(_pendingQueueVersionProvider.notifier).state++;
  }

  Future<void> processNow() => _processQueue();

  Future<void> _replay(QueuedWrite item) async {
    switch (item.operationType) {
      case OfflineOp.logVital:
        await ref.read(vitalsServiceProvider).logVital(
              metricType: item.payload['metricType'] as String,
              value: (item.payload['value'] as num).toDouble(),
              unit: item.payload['unit'] as String,
              source: VitalSource.fromWire(item.payload['source'] as String),
              recordedAt: DateTime.parse(item.payload['recordedAt'] as String),
            );
      default:
        throw StateError('Unknown queued operation type: ${item.operationType}');
    }
  }
}
