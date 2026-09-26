import 'package:ketion/core/database/app_database.dart';

enum ConflictResolution {
  keepLocal,
  applyRemote,
}

/// The synchronization system uses a deterministic Revision-Wins policy.
/// `version` is the primary ordering key. `updatedAtUtc` and `deviceId` are deterministic tie-breakers.
class ConflictResolver {
  final AppDatabase _db;

  ConflictResolver(this._db);

  static ConflictResolution resolveConflictSync({
    required int localVersion,
    required int remoteVersion,
    required DateTime localUpdatedAtUtc,
    required String localDeviceId,
    required DateTime remoteUpdatedAtUtc,
    required String remoteDeviceId,
  }) {
    if (remoteVersion > localVersion) {
      return ConflictResolution.applyRemote;
    } else if (remoteVersion < localVersion) {
      return ConflictResolution.keepLocal;
    }

    if (remoteUpdatedAtUtc.isAfter(localUpdatedAtUtc)) {
      return ConflictResolution.applyRemote;
    } else if (remoteUpdatedAtUtc.isBefore(localUpdatedAtUtc)) {
      return ConflictResolution.keepLocal;
    }

    if (remoteDeviceId.compareTo(localDeviceId) > 0) {
      return ConflictResolution.applyRemote;
    }

    return ConflictResolution.keepLocal;
  }

  /// Resolves conflicts using Deterministic Revision-Wins strategy.
  /// Returns ConflictResolution.applyRemote if the remote operation should be applied to the local database.
  Future<ConflictResolution> resolveConflict({
    required String table,
    required String entityId,
    required String operation,
    required int remoteVersion,
    required DateTime remoteUpdatedAtUtc,
    required String localDeviceId,
    required String remoteDeviceId,
  }) async {
    DateTime? localUpdatedAtUtc;
    int? localVersion;

    switch (table) {
      case 'pages':
        final result = await (_db.select(_db.pages)
              ..where((t) => t.id.equals(entityId)))
            .getSingleOrNull();
        if (result != null) {
          localUpdatedAtUtc = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'blocks':
        final result = await (_db.select(_db.blocks)
              ..where((t) => t.id.equals(entityId)))
            .getSingleOrNull();
        if (result != null) {
          localUpdatedAtUtc = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'attachments':
        final result = await (_db.select(_db.attachments)
              ..where((t) => t.id.equals(entityId)))
            .getSingleOrNull();
        if (result != null) {
          localUpdatedAtUtc = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'collections':
        final result = await (_db.select(_db.collections)
              ..where((t) => t.id.equals(entityId)))
            .getSingleOrNull();
        if (result != null) {
          localUpdatedAtUtc = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'tags':
        final result = await (_db.select(_db.tags)
              ..where((t) => t.id.equals(entityId)))
            .getSingleOrNull();
        if (result != null) {
          localUpdatedAtUtc = result.updatedAt;
          localVersion = result.version;
        }
        break;
      case 'reminders':
        final result = await (_db.select(_db.reminders)
              ..where((t) => t.id.equals(entityId)))
            .getSingleOrNull();
        if (result != null) {
          localUpdatedAtUtc = result.updatedAt;
          localVersion = result.version;
        }
        break;
      default:
        throw Exception('SyncProtocolFailure: Unknown table $table');
    }

    // Deterministic Revision-Wins logic using (version, updatedAtUtc, deviceId)
    if (localVersion == null || localUpdatedAtUtc == null) {
      // Entity does not exist locally
      return ConflictResolution.applyRemote;
    }

    return resolveConflictSync(
      localVersion: localVersion,
      remoteVersion: remoteVersion,
      localUpdatedAtUtc: localUpdatedAtUtc,
      localDeviceId: localDeviceId,
      remoteUpdatedAtUtc: remoteUpdatedAtUtc,
      remoteDeviceId: remoteDeviceId,
    );
  }
}
