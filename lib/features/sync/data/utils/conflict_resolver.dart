import 'package:ketion/core/database/app_database.dart';

enum ConflictResolution {
  keepLocal,
  applyRemote,
}

class ConflictResolver {
  final AppDatabase _db;

  ConflictResolver(this._db);

  static ConflictResolution resolveConflictSync({
    required int localUpdatedAt, // Using milliseconds since epoch
    required String localDeviceId,
    required int remoteUpdatedAt,
    required String remoteDeviceId,
  }) {
    if (remoteUpdatedAt > localUpdatedAt) {
      return ConflictResolution.applyRemote;
    } else if (remoteUpdatedAt < localUpdatedAt) {
      return ConflictResolution.keepLocal;
    }

    if (remoteDeviceId.compareTo(localDeviceId) > 0) {
      return ConflictResolution.applyRemote;
    }

    return ConflictResolution.keepLocal;
  }

  /// Resolves conflicts using Last-Writer-Wins (LWW) strategy.
  /// Returns ConflictResolution.applyRemote if the remote operation should be applied to the local database.
  Future<ConflictResolution> resolveConflict({
    required String table,
    required String entityId,
    required String operation,
    required Map<String, dynamic>? remotePayload,
    required String localDeviceId,
    String? remoteDeviceId,
  }) async {
    DateTime? localUpdatedAt;

    switch (table) {
      case 'pages':
        final result = await (_db.select(_db.pages)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) localUpdatedAt = result.updatedAt;
        break;
      case 'blocks':
        final result = await (_db.select(_db.blocks)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) localUpdatedAt = result.updatedAt;
        break;
      case 'attachments':
        final result = await (_db.select(_db.attachments)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) localUpdatedAt = result.updatedAt;
        break;
      case 'collections':
        final result = await (_db.select(_db.collections)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) localUpdatedAt = result.updatedAt;
        break;
      case 'tags':
        final result = await (_db.select(_db.tags)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) localUpdatedAt = result.updatedAt;
        break;
      case 'reminders':
        final result = await (_db.select(_db.reminders)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) localUpdatedAt = result.updatedAt;
        break;
      default:
        throw Exception('SyncProtocolFailure: Unknown table $table');
    }

    // Protocol validation A3
    if (operation == 'delete' && remotePayload == null) {
      throw Exception('SyncProtocolFailure: Delete operations must include a tombstone payload');
    }

    // Parse remote updatedAt
    DateTime? remoteUpdatedAt;
    if (remotePayload != null) {
      if (remotePayload['updatedAt'] != null) {
        remoteUpdatedAt = DateTime.tryParse(remotePayload['updatedAt'] as String);
      }
    }

    if (remoteUpdatedAt == null) {
      throw Exception('SyncProtocolFailure: Entities must include an updatedAt timestamp');
    }

    // LWW logic using (updated_at, device_id)
    if (localUpdatedAt == null) {
      // Entity does not exist locally
      return ConflictResolution.applyRemote;
    } else {
      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        return ConflictResolution.applyRemote;
      } else if (remoteUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
        if (remoteDeviceId != null && remoteDeviceId.compareTo(localDeviceId) > 0) {
          return ConflictResolution.applyRemote;
        }
      }
    }

    return ConflictResolution.keepLocal;
  }
}
