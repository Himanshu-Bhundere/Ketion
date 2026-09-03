import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';

class ConflictResolver {
  final AppDatabase _db;

  ConflictResolver(this._db);

  /// Resolves conflicts using Last-Writer-Wins (LWW) strategy.
  /// Applies the remote operation to the local database if it's newer.
  Future<void> resolveAndApply({
    required String table,
    required String entityId,
    required String operation,
    required Map<String, dynamic>? remotePayload,
  }) async {
    // 1. Fetch local entity's updatedAt
    final localResult = await _db.customSelect(
      'SELECT updatedAt FROM $table WHERE id = ?',
      variables: [Variable.withString(entityId)],
    ).getSingleOrNull();

    DateTime? localUpdatedAt;
    if (localResult != null && localResult.data['updatedAt'] != null) {
      final val = localResult.data['updatedAt'];
      if (val is int) {
         localUpdatedAt = DateTime.fromMillisecondsSinceEpoch(val * 1000, isUtc: true);
      } else if (val is String) {
         localUpdatedAt = DateTime.tryParse(val);
      }
    }

    // 2. Parse remote updatedAt
    DateTime? remoteUpdatedAt;
    if (remotePayload != null && remotePayload['updatedAt'] != null) {
      remoteUpdatedAt = DateTime.tryParse(remotePayload['updatedAt'] as String);
    }

    // 3. LWW logic
    bool shouldApply = false;
    if (localUpdatedAt == null) {
      // Entity does not exist locally
      shouldApply = true;
    } else if (remoteUpdatedAt != null && remoteUpdatedAt.isAfter(localUpdatedAt)) {
      // Remote is newer
      shouldApply = true;
    } else if (remoteUpdatedAt == null && operation == 'delete') {
       // A delete might not have a payload, just an entityId
       shouldApply = true;
    }

    // 4. Apply changes if needed
    if (shouldApply) {
      if (operation == 'delete' || (remotePayload != null && remotePayload['deleted'] == true)) {
        await _applyDelete(table, entityId);
      } else if (remotePayload != null) {
        await _applyUpsert(table, entityId, remotePayload, existsLocally: localUpdatedAt != null);
      }
    }
  }

  Future<void> _applyDelete(String table, String entityId) async {
    // Using soft delete as per schema (deleted = 1)
    await _db.customStatement(
      'UPDATE $table SET deleted = 1, updatedAt = ? WHERE id = ?',
      [
        Variable.withInt(DateTime.now().millisecondsSinceEpoch ~/ 1000), // Assuming seconds
        Variable.withString(entityId),
      ],
    );
  }

  Future<void> _applyUpsert(String table, String entityId, Map<String, dynamic> payload, {required bool existsLocally}) async {
    final columns = payload.keys.toList();
    final values = payload.values.map(_mapToVariable).toList();

    if (existsLocally) {
      final setClause = columns.map((c) => '$c = ?').join(', ');
      await _db.customStatement(
        'UPDATE $table SET $setClause WHERE id = ?',
        [...values, Variable.withString(entityId)],
      );
    } else {
      final columnsClause = columns.join(', ');
      final placeholdersClause = List.filled(columns.length, '?').join(', ');
      await _db.customStatement(
        'INSERT INTO $table ($columnsClause) VALUES ($placeholdersClause)',
        values,
      );
    }
  }

  Variable _mapToVariable(dynamic value) {
    if (value == null) return const Variable(null);
    if (value is String) {
        final d = DateTime.tryParse(value);
        if (d != null && (value.contains('T') || value.contains('-'))) {
             return Variable.withInt(d.millisecondsSinceEpoch ~/ 1000);
        }
        return Variable.withString(value);
    }
    if (value is int) return Variable.withInt(value);
    if (value is bool) return Variable.withInt(value ? 1 : 0);
    if (value is double) return Variable.withReal(value);
    
    return Variable.withString(value.toString());
  }
}
