import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// One row per mutation that failed to reach Supabase while offline. [operationType] identifies
/// which service call to replay (see OfflineQueueProcessor) and [payloadJson] carries its
/// arguments — kept as a JSON blob rather than typed columns so adding a new queueable operation
/// never needs a schema migration, just a new case in the processor's replay switch.
class QueuedWrite {
  final int id;
  final String operationType;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  const QueuedWrite({
    required this.id,
    required this.operationType,
    required this.payload,
    required this.createdAt,
  });
}

/// Local persistence for writes made while offline — the piece the earlier offline-banner pass
/// deliberately left unbuilt (SECURITY_AND_SCALABILITY.md §5): that pass only covered offline
/// *reads* (stale-but-visible cached data); this covers offline *writes* so a vital logged with
/// no signal isn't silently lost, using the `sqflite` dependency that was declared but unused
/// since the very first scaffold of this app.
class OfflineQueueService {
  static const _dbName = 'offline_queue.db';
  Database? _db;

  /// `sqflite` has no web implementation — on Flutter Web, callers should check this before
  /// enqueueing and fall back to the plain "could not save, try again" error path instead
  /// (the only difference on web vs. native is that offline writes aren't queued for auto-retry).
  bool get isSupported => !kIsWeb;

  Future<Database> _database() async {
    if (kIsWeb) {
      throw UnsupportedError('OfflineQueueService is not available on Flutter Web — check isSupported first.');
    }
    final existing = _db;
    if (existing != null) return existing;
    final dir = await getDatabasesPath();
    final db = await openDatabase(
      p.join(dir, _dbName),
      version: 1,
      onCreate: (db, version) => db.execute('''
        create table pending_writes (
          id integer primary key autoincrement,
          operation_type text not null,
          payload_json text not null,
          created_at text not null
        )
      '''),
    );
    _db = db;
    return db;
  }

  Future<void> enqueue(String operationType, Map<String, dynamic> payload) async {
    final db = await _database();
    await db.insert('pending_writes', {
      'operation_type': operationType,
      'payload_json': jsonEncode(payload),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<QueuedWrite>> getPending() async {
    if (!isSupported) return const [];
    final db = await _database();
    final rows = await db.query('pending_writes', orderBy: 'id');
    return rows
        .map(
          (r) => QueuedWrite(
            id: r['id'] as int,
            operationType: r['operation_type'] as String,
            payload: jsonDecode(r['payload_json'] as String) as Map<String, dynamic>,
            createdAt: DateTime.parse(r['created_at'] as String),
          ),
        )
        .toList();
  }

  Future<void> remove(int id) async {
    final db = await _database();
    await db.delete('pending_writes', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> pendingCount() async {
    if (!isSupported) return 0;
    final db = await _database();
    final result = await db.rawQuery('select count(*) as c from pending_writes');
    return (result.first['c'] as int?) ?? 0;
  }
}
