import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/errors/failures.dart';
import 'package:ketion/features/auth/domain/services/auth_service.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';
import 'package:ketion/features/sync/domain/providers/sync_provider.dart';
import 'package:ketion/features/sync/domain/repositories/sync_engine_repository.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:ketion/features/sync/domain/repositories/sync_state_repository.dart';
import 'package:ketion/features/sync/domain/entities/sync_state_entity.dart';
import 'package:ketion/core/security/device_identity.dart';
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';
import 'package:ketion/features/sync/data/utils/sync_entity_applier.dart';

import 'package:ketion/core/database/app_database.dart';
import 'package:drift/drift.dart';


class SyncEngineRepositoryImpl implements SyncEngineRepository {
  final SyncProvider _syncProvider;
  final AuthService _authService;
  final SyncQueueRepository _queueRepository;
  final SyncStateRepository _stateRepository;
  final ConflictResolver _conflictResolver;
  final SyncEntityApplier _entityApplier;
  final AppDatabase _db;

  static const List<String> _driveScopes = [
    'https://www.googleapis.com/auth/drive.appdata',
    'https://www.googleapis.com/auth/drive.file',
  ];

  SyncEngineRepositoryImpl({
    required SyncProvider syncProvider,
    required AuthService authService,
    required SyncQueueRepository queueRepository,
    required SyncStateRepository stateRepository,
    required ConflictResolver conflictResolver,
    required SyncEntityApplier entityApplier,
    required AppDatabase db,
  })  : _syncProvider = syncProvider,
        _authService = authService,
        _queueRepository = queueRepository,
        _stateRepository = stateRepository,
        _conflictResolver = conflictResolver,
        _entityApplier = entityApplier,
        _db = db;

  bool _isSyncing = false;

  @override
  Future<Result<void>> enqueueOperation(
    String table,
    String entityId,
    String operation, {
    String? payload,
  }) async {
    final item = SyncQueueItem(
      id: const Uuid().v7(),
      entityTable: table,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now().toUtc(),
    );
    return await _queueRepository.enqueueOrCoalesce(item);
  }

  @override
  Future<Result<void>> syncNow() async {
    if (_isSyncing) {
      return const Error(SyncFailure('Sync already in progress'));
    }

    _isSyncing = true;
    try {
      // 1. Authenticate
      final tokenResult = await _authService.getAccessToken(_driveScopes);
      if (tokenResult is Error<String>) {
        return Error(tokenResult.failure);
      }
      final token = (tokenResult as Success<String>).value;

      // 2. Initialize provider
      final initResult = await _syncProvider.initialize(token);
      if (initResult is Error<void>) {
        return Error(initResult.failure);
      }

      // Fetch sync state early to get deviceId
      final deviceId = await DeviceIdentity.getDeviceId();
      final stateRes =
          await _stateRepository.getSyncState(deviceId, 'google_drive');
      SyncStateEntity syncState = SyncStateEntity(
        deviceId: deviceId,
        provider: 'google_drive',
      );
      if (stateRes is Success<SyncStateEntity?> && stateRes.value != null) {
        syncState = stateRes.value!;
      }

      // 3. Process local queue items (Upload)
      const leaseDuration = Duration(minutes: 5);
      final batchResult = await _queueRepository.claimNextBatch(
        limit: 50,
        leaseDuration: leaseDuration,
      );
      if (batchResult is Success<List<SyncQueueItem>>) {
        final claimedItems = batchResult.value;
        if (claimedItems.isNotEmpty) {
          final batchId = claimedItems.first.batchId!;

          final payload = {
            'batchId': batchId,
            'deviceId': syncState.deviceId,
            'schemaVersion': 1,
            'timestamp': DateTime.now().toUtc().toIso8601String(),
            'changes': claimedItems.map((e) {
              var p = e.payload != null ? jsonDecode(e.payload!) : null;

              int? version;
              String? updatedAt;
              if (p is Map<String, dynamic>) {
                version = p['version'] as int?;
                updatedAt = p['updatedAt'] as String?;
              }

              if (e.entityTable == 'attachments' && p is Map<String, dynamic>) {
                p.remove('localPath');
                p.remove('thumbnailPath');
                p.remove('uploadStatus');
                p.remove('isPinnedOffline');
              }
              return {
                'id': e.entityId,
                'table': e.entityTable,
                'operation': e.operation,
                if (version != null) 'version': version,
                if (updatedAt != null) 'updatedAt': updatedAt,
                'payload': p,
              };
            }).toList(),
          };

          final uploadRes = await _syncProvider.uploadChanges(batchId, payload);
          if (uploadRes is Success<void>) {
            await _db.transaction(() async {
              for (final item in claimedItems) {
                await _queueRepository.updateStatus(
                  item.id,
                  SyncQueueItemStatus.completed,
                );
              }
            });
            // Cleanup completed items
            await _queueRepository.clearCompleted();
          } else if (uploadRes is Error<void>) {
            // Bounded exponential backoff update
            await _db.transaction(() async {
              final now = DateTime.now().toUtc();
              for (final item in claimedItems) {
                final nextRetry = item.attemptCount + 1;
                if (nextRetry > 5) {
                  await _queueRepository.updateStatus(
                    item.id,
                    SyncQueueItemStatus.failed,
                    attemptCount: nextRetry,
                    lastAttemptAt: now,
                    lastError: uploadRes.failure.message,
                  );
                } else {
                  // Exponential backoff: 30s, 60s, 120s, 240s...
                  final backoffSeconds = 30 * (1 << (nextRetry - 1));
                  await _queueRepository.updateStatus(
                    item.id,
                    SyncQueueItemStatus.waiting,
                    attemptCount: nextRetry,
                    lastAttemptAt: now,
                    nextRetryAt: now.add(Duration(seconds: backoffSeconds)),
                    lastError: uploadRes.failure.message,
                  );
                }
              }
            });
          }
        }
      }

      // 4. Download remote changes (page by page)
      String? currentCursor = syncState.lastDriveCursor;
      bool hasMorePages = true;

      if (currentCursor == null) {
        // A1: Bootstrap correctness
        final startTokenRes = await _syncProvider.getStartPageToken();
        if (startTokenRes is Error<String>) return Error(startTokenRes.failure);
        final bootstrapCursor = (startTokenRes as Success<String>).value;

        String? historyCursor;
        do {
          final historyRes =
              await _syncProvider.downloadHistoricalBatches(historyCursor);
          if (historyRes is Error<SyncDownloadResult>) {
            return Error(historyRes.failure);
          }

          final historyResult =
              (historyRes as Success<SyncDownloadResult>).value;
          final changes = historyResult.changes;

          final processResult =
              await _processDownloadedChanges(changes, syncState);
          if (processResult is Error<void>) {
            return Error(processResult.failure);
          }

          historyCursor = historyResult.nextCursor;
        } while (historyCursor != null);

        currentCursor = bootstrapCursor;
      }

      while (hasMorePages) {
        final downloadRes = await _syncProvider.downloadChanges(currentCursor);
        if (downloadRes is Error<SyncDownloadResult>) {
          return Error(downloadRes.failure);
        }

        final downloadResult =
            (downloadRes as Success<SyncDownloadResult>).value;
        final changes = downloadResult.changes;

        final processResult =
            await _processDownloadedChanges(changes, syncState);
        if (processResult is Error<void>) {
          return Error(processResult.failure);
        }

        String? newCursor = downloadResult.nextCursor ?? currentCursor;
        hasMorePages = downloadResult.hasMore;

        // 5. Update sync state (advance cursor) after all batches are processed successfully
        if (newCursor != currentCursor || changes.isNotEmpty) {
          syncState = syncState.copyWith(
            lastSyncTime: DateTime.now().toUtc(),
            lastDriveCursor: newCursor,
          );
          await _stateRepository.saveSyncState(syncState);
          currentCursor = newCursor;
        }
      }

      // 6. Cleanup old tombstones
      await _db.cleanupTombstones(
        retentionDays: 30, // Using default of 30 days since it was removed from settings
      );

      return const Success(null);
    } finally {
      _isSyncing = false;
    }
  }

  Future<Result<void>> _processDownloadedChanges(
    List<Map<String, dynamic>> changes,
    SyncStateEntity syncState,
  ) async {
    // Group changes by batchId
    final batches = <String, List<Map<String, dynamic>>>{};
    final unbatchedChanges = <Map<String, dynamic>>[];
    for (final change in changes) {
      final batchId = change['batchId'] as String?;
      if (batchId != null) {
        batches.putIfAbsent(batchId, () => []).add(change);
      } else {
        unbatchedChanges.add(change);
      }
    }

    // Process each batch in its own transaction
    for (final entry in batches.entries) {
      final batchId = entry.key;
      final batchChanges = entry.value;

      try {
        await _db.transaction(() async {
          // Check idempotency
          final existingBatch = await (_db.select(_db.processedBatches)
                ..where((tbl) => tbl.batchId.equals(batchId)))
              .getSingleOrNull();
          if (existingBatch != null) return; // Skip if already processed

          // Strict batch validation
          for (final change in batchChanges) {
            final operation = change['operation'];
            final table = change['table'];
            final payload = change['payload'];
            final version = change['version'];
            final updatedAt = change['updatedAt'];
            final entityId = change['id'] ?? change['entityId'];

            if (operation == null ||
                table == null ||
                payload == null ||
                version == null ||
                updatedAt == null ||
                entityId == null) {
              throw const FormatException('Invalid protocol schema in batch');
            }
            if (operation != 'create' &&
                operation != 'update' &&
                operation != 'delete' &&
                operation != 'restore' &&
                operation != 'upsert') {
              throw const FormatException('Invalid operation in batch');
            }

            if (payload is Map<String, dynamic>) {
              if (payload['id'] != null && payload['id'] != entityId) {
                throw const FormatException(
                  'Payload id does not match change id',
                );
              }
            }
          }

          // Process all changes in the batch
          for (final change in batchChanges) {
            final remoteDeviceId = change['deviceId'] as String?;
            final table = change['table'] as String;
            final entityId = (change['id'] ?? change['entityId']) as String;
            final operation = change['operation'] as String;
            final payload = change['payload'] as Map<String, dynamic>;
            final version = change['version'] as int;
            final updatedAt = change['updatedAt'] as String;

            final resolution = await _conflictResolver.resolveConflict(
              table: table,
              entityId: entityId,
              operation: operation,
              remoteVersion: version,
              remoteUpdatedAtUtc: DateTime.parse(updatedAt),
              localDeviceId: syncState.deviceId,
              remoteDeviceId: remoteDeviceId ?? 'unknown',
            );

            if (resolution == ConflictResolution.applyRemote) {
              await _entityApplier.applyResolvedEntity(
                table,
                entityId,
                payload,
              );
            }
          }

          final remoteDeviceId = batchChanges.first['deviceId'] as String?;
          // Insert it as processed
          await _db.into(_db.processedBatches).insert(
                ProcessedBatchesCompanion(
                  batchId: Value(batchId),
                  deviceId: Value(remoteDeviceId ?? 'unknown'),
                  processedAt: Value(DateTime.now().toUtc()),
                ),
              );
        });
      } catch (e) {
        // Cursor Safety A2: Stop processing at first failed batch.
        // Do not advance cursor.
        return Error(SyncFailure('Failed processing batch $batchId: $e'));
      }
    }

    // Process unbatched changes
    for (final change in unbatchedChanges) {
      try {
        await _db.transaction(() async {
          final remoteDeviceId = change['deviceId'] as String?;
          final table = change['table'] as String?;
          final entityId =
              change['id'] as String? ?? change['entityId'] as String?;
          final operation = change['operation'] as String?;
          final payload = change['payload'] as Map<String, dynamic>?;

          if (table != null &&
              entityId != null &&
              operation != null &&
              payload != null) {
            final version =
                change['version'] as int? ?? payload['version'] as int?;
            final updatedAtStr = change['updatedAt'] as String? ??
                payload['updatedAt'] as String?;

            if (version == null || updatedAtStr == null) {
              throw const FormatException(
                'Missing version or updatedAt in unbatched change',
              );
            }

            final resolution = await _conflictResolver.resolveConflict(
              table: table,
              entityId: entityId,
              operation: operation,
              remoteVersion: version,
              remoteUpdatedAtUtc: DateTime.parse(updatedAtStr),
              localDeviceId: syncState.deviceId,
              remoteDeviceId: remoteDeviceId ?? 'unknown',
            );

            if (resolution == ConflictResolution.applyRemote) {
              await _entityApplier.applyResolvedEntity(
                table,
                entityId,
                payload,
              );
            }
          }
        });
      } catch (e) {
        return Error(SyncFailure('Failed processing unbatched change: $e'));
      }
    }
    return const Success(null);
  }
}
