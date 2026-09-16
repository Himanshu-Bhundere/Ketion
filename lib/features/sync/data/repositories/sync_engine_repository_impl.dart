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
import 'package:ketion/features/sync/data/utils/conflict_resolver.dart';
import 'package:ketion/features/sync/data/utils/sync_entity_applier.dart';

import 'package:ketion/core/database/app_database.dart';
import 'package:drift/drift.dart';

import 'package:ketion/features/settings/domain/repositories/settings_repository.dart';

class SyncEngineRepositoryImpl implements SyncEngineRepository {
  final SyncProvider _syncProvider;
  final AuthService _authService;
  final SyncQueueRepository _queueRepository;
  final SyncStateRepository _stateRepository;
  final ConflictResolver _conflictResolver;
  final SyncEntityApplier _entityApplier;
  final SettingsRepository _settingsRepository;
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
    required SettingsRepository settingsRepository,
    required AppDatabase db,
  })  : _syncProvider = syncProvider,
        _authService = authService,
        _queueRepository = queueRepository,
        _stateRepository = stateRepository,
        _conflictResolver = conflictResolver,
        _entityApplier = entityApplier,
        _settingsRepository = settingsRepository,
        _db = db;

  bool _isSyncing = false;

  @override
  Future<Result<void>> enqueueOperation(
    String table,
    String entityId,
    String operation, {
    String? payload,
  }) async {
    final pendingResult = await _queueRepository.findPendingItem(table, entityId);
    if (pendingResult is Success<SyncQueueItem?> && pendingResult.value != null) {
      final existing = pendingResult.value!;
      final newOp = (existing.operation == 'create' && operation == 'update') 
          ? 'create' 
          : operation;
      
      final updatedItem = existing.copyWith(
        operation: newOp,
        payload: payload,
        createdAt: DateTime.now(),
      );
      return await _queueRepository.enqueue(updatedItem);
    }

    final item = SyncQueueItem(
      id: const Uuid().v7(),
      entityTable: table,
      entityId: entityId,
      operation: operation,
      payload: payload,
      createdAt: DateTime.now(),
    );
    return await _queueRepository.enqueue(item);
  }

  @override
  Future<Result<void>> syncNow() async {
    if (_isSyncing) {
      return Error(SyncFailure('Sync already in progress'));
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
      final stateRes = await _stateRepository.getSyncState('local_device', 'google_drive');
      SyncStateEntity syncState = const SyncStateEntity(
        deviceId: 'local_device',
        provider: 'google_drive',
      );
      if (stateRes is Success<SyncStateEntity?> && stateRes.value != null) {
        syncState = stateRes.value!;
      }

      // 3. Process local queue items (Upload)
      final pendingResult = await _queueRepository.getPendingItems();
      if (pendingResult is Success<List<SyncQueueItem>>) {
        final items = pendingResult.value;
        if (items.isNotEmpty) {
        
        // Lease items by marking them as processing
        await _db.transaction(() async {
          for (final item in items) {
            await _queueRepository.updateStatus(item.id, SyncQueueItemStatus.processing);
          }
        });

        final batchId = const Uuid().v7();
        final payload = {
          'batchId': batchId,
          'deviceId': syncState.deviceId,
          'timestamp': DateTime.now().toIso8601String(),
          'changes': items
              .map((e) {
                  var p = e.payload != null ? jsonDecode(e.payload!) : null;
                  if (e.entityTable == 'attachments' && p is Map<String, dynamic>) {
                    p.remove('localPath');
                    p.remove('thumbnailPath');
                    p.remove('uploadStatus');
                    p.remove('isPinnedOffline');
                  }
                  return {
                    'id': e.id,
                    'table': e.entityTable,
                    'entityId': e.entityId,
                    'operation': e.operation,
                    'payload': p,
                  };
              }).toList(),
        };

        final uploadRes = await _syncProvider.uploadChanges(batchId, payload);
        if (uploadRes is Success<void>) {
          await _db.transaction(() async {
            for (final item in items) {
              await _queueRepository.updateStatus(item.id, SyncQueueItemStatus.completed);
            }
          });
        } else if (uploadRes is Error<void>) {
          // Bounded exponential backoff update
          await _db.transaction(() async {
            for (final item in items) {
              final nextRetry = item.attemptCount + 1;
              if (nextRetry > 5) {
                await _queueRepository.updateStatus(
                  item.id,
                  SyncQueueItemStatus.failed,
                  attemptCount: nextRetry,
                  lastError: uploadRes.failure.message,
                );
              } else {
                await _queueRepository.updateStatus(
                  item.id,
                  SyncQueueItemStatus.waiting,
                  attemptCount: nextRetry,
                  lastError: uploadRes.failure.message,
                );
              }
            }
          });
        }
      }
    }

    // 4. Download remote changes
    String? lastCursor = syncState.lastAppliedGeneration > 0 ? syncState.lastAppliedGeneration.toString() : null;

    final downloadRes = await _syncProvider.downloadChanges(lastCursor);
    if (downloadRes is Error<SyncDownloadResult>) {
      return Error(downloadRes.failure);
    }
    
    final downloadResult = (downloadRes as Success<SyncDownloadResult>).value;
    final changes = downloadResult.changes;
    String? newCursor = downloadResult.nextCursor ?? lastCursor;

    // Apply all changes and advance cursor atomically
    await _db.transaction(() async {
      final processedBatchIds = <String>{};
      
      for (final change in changes) {
         final batchId = change['batchId'] as String?;
         final remoteDeviceId = change['deviceId'] as String?;
         
         if (batchId != null) {
            if (processedBatchIds.contains(batchId)) {
               // We've already verified this batch in this run, but we still need to process its changes.
            } else {
               // Check if the batch was already processed
               final existingBatch = await (_db.select(_db.processedBatches)..where((tbl) => tbl.batchId.equals(batchId))).getSingleOrNull();
               if (existingBatch != null) {
                 processedBatchIds.add(batchId);
               } else {
                 // Insert it as processed so we don't process it again next time
                 await _db.into(_db.processedBatches).insert(ProcessedBatchesCompanion(
                   batchId: Value(batchId),
                   deviceId: Value(remoteDeviceId ?? 'unknown'),
                   processedAt: Value(DateTime.now()),
                 ));
                 // But wait, we shouldn't add to processedBatchIds until we finish the loop?
                 // No, we are in a transaction. If it fails, everything rolls back.
               }
            }
            if (processedBatchIds.contains(batchId)) {
               continue; // Skip this change because its batch was already processed
            }
         }

         final table = change['table'] as String?;
         final entityId = change['entityId'] as String?;
         final operation = change['operation'] as String?;
         final payload = change['payload'] as Map<String, dynamic>?;

         if (table != null && entityId != null && operation != null) {
            final resolution = await _conflictResolver.resolveConflict(
               table: table,
               entityId: entityId,
               operation: operation,
               remotePayload: payload,
               localDeviceId: syncState.deviceId,
               remoteDeviceId: remoteDeviceId,
            );
            
            if (resolution == ConflictResolution.applyRemote) {
              if (operation == 'delete' || (payload != null && payload['deleted'] == true)) {
                await _entityApplier.applyDelete(table, entityId);
              } else if (payload != null) {
                await _entityApplier.applyUpsert(table, entityId, payload);
              }
            }
         }
         // batchId can still be used for debugging or other purposes, but the cursor is handled by nextCursor
      }

      // 5. Update sync state within the same transaction
      if (newCursor != lastCursor || changes.isNotEmpty) {
        final newState = syncState.copyWith(
          lastSyncTime: DateTime.now(),
          lastAppliedGeneration: newCursor != null ? (int.tryParse(newCursor!) ?? syncState.lastAppliedGeneration) : syncState.lastAppliedGeneration,
          pageCursor: newCursor,
        );
        await _stateRepository.saveSyncState(newState);
      }
    });

    // 6. Cleanup old tombstones
    final settings = await _settingsRepository.getSettings();
    await _db.cleanupTombstones(retentionDays: settings.tombstoneRetentionDays);

    return const Success(null);
    } finally {
      _isSyncing = false;
    }
  }
}
