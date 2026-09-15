import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';

enum ConflictResolution {
  keepLocal,
  applyRemote,
}

class ConflictResolver {
  final AppDatabase _db;

  ConflictResolver(this._db);

  static ConflictResolution resolveConflictSync({
    required int localVersion,
    required int localUpdatedAt, // Using milliseconds since epoch
    required String localDeviceId,
    required int remoteVersion,
    required int remoteUpdatedAt,
    required String remoteDeviceId,
  }) {
    if (remoteUpdatedAt > localUpdatedAt) {
      return ConflictResolution.applyRemote;
    } else if (remoteUpdatedAt < localUpdatedAt) {
      return ConflictResolution.keepLocal;
    }

    if (remoteVersion > localVersion) {
      return ConflictResolution.applyRemote;
    } else if (remoteVersion < localVersion) {
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
    int localVersion = 0;

    switch (table) {
      case 'pages':
        final result = await (_db.select(_db.pages)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) {
          localUpdatedAt = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'blocks':
        final result = await (_db.select(_db.blocks)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) {
          localUpdatedAt = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'attachments':
        final result = await (_db.select(_db.attachments)..where((t) => t.id.equals(entityId))).getSingleOrNull();
        if (result != null) {
          localUpdatedAt = result.updatedAt;
          localVersion = result.version;
        }
        break;
    }

    // Parse remote updatedAt and version
    DateTime? remoteUpdatedAt;
    int remoteVersion = 0;
    if (remotePayload != null) {
      if (remotePayload['updatedAt'] != null) {
        remoteUpdatedAt = DateTime.tryParse(remotePayload['updatedAt'] as String);
      }
      if (remotePayload['version'] != null) {
        remoteVersion = remotePayload['version'] as int;
      }
    }

    // LWW logic using (updated_at, device_id)
    if (localUpdatedAt == null) {
      // Entity does not exist locally
      return ConflictResolution.applyRemote;
    } else if (remoteUpdatedAt != null) {
      if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
        return ConflictResolution.applyRemote;
      } else if (remoteUpdatedAt.isAtSameMomentAs(localUpdatedAt)) {
        if (remoteDeviceId != null && remoteDeviceId.compareTo(localDeviceId) > 0) {
          return ConflictResolution.applyRemote;
        }
      }
    } else if (remoteUpdatedAt == null && operation == 'delete') {
       // A delete might not have a payload, just an entityId
       return ConflictResolution.applyRemote;
    }

    return ConflictResolution.keepLocal;
  }
}
