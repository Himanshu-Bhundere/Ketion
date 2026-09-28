import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/reminders/data/models/reminder_mapper.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/sync/domain/repositories/sync_queue_repository.dart';
import 'package:ketion/features/sync/domain/entities/sync_queue_item.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final AppDatabase _db;
  final SyncQueueRepository _syncQueue;

  ReminderRepositoryImpl(this._db, this._syncQueue);

  @override
  Stream<List<ReminderEntity>> watchRemindersForPage(String pageId) {
    final query = _db.select(_db.reminders)
      ..where((tbl) => tbl.pageId.equals(pageId) & tbl.deleted.equals(false));
    return query
        .watch()
        .map((rows) => rows.map(ReminderMapper.fromDb).toList());
  }

  @override
  Stream<List<ReminderEntity>> watchAllActiveReminders() {
    final query = _db.select(_db.reminders)
      ..where((tbl) => tbl.completed.equals(false) & tbl.deleted.equals(false));
    return query
        .watch()
        .map((rows) => rows.map(ReminderMapper.fromDb).toList());
  }

  @override
  Future<ReminderEntity?> getReminder(String id) async {
    final query = _db.select(_db.reminders)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return ReminderMapper.fromDb(row);
  }

  @override
  Future<void> addReminder(ReminderEntity reminder) async {
    final newReminder =
        reminder.copyWith(version: 1, updatedAt: DateTime.now().toUtc());
    await _db.transaction(() async {
      await _db.into(_db.reminders).insert(
            ReminderMapper.toDbCompanion(newReminder),
            mode: InsertMode.replace,
          );
      await _syncQueue.enqueueOrCoalesce(
        SyncQueueItem(
          id: const Uuid().v7(),
          entityTable: 'reminders',
          entityId: newReminder.id,
          operation: 'create',
          payload: jsonEncode(newReminder.toJson()),
          batchId: null,
          version: newReminder.version,
          updatedAt: newReminder.updatedAt,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  @override
  Future<void> updateReminder(ReminderEntity reminder) async {
    await _db.transaction(() async {
      final existingRecord = await (_db.select(_db.reminders)
            ..where((t) => t.id.equals(reminder.id)))
          .getSingleOrNull();
      if (existingRecord == null) {
        throw Exception('Reminder not found');
      }

      final newVersion = existingRecord.version + 1;
      final updated = reminder.copyWith(
        updatedAt: DateTime.now().toUtc(),
        version: newVersion,
      );

      await _db
          .update(_db.reminders)
          .replace(ReminderMapper.toDbCompanion(updated));
      await _syncQueue.enqueueOrCoalesce(
        SyncQueueItem(
          id: const Uuid().v7(),
          entityTable: 'reminders',
          entityId: updated.id,
          operation: 'update',
          payload: jsonEncode(updated.toJson()),
          batchId: null,
          version: updated.version,
          updatedAt: updated.updatedAt,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  @override
  Future<void> deleteReminder(String id) async {
    final reminder = await getReminder(id);
    if (reminder != null) {
      await _db.transaction(() async {
        final existingRecord = await (_db.select(_db.reminders)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();
        if (existingRecord == null) {
          return;
        }

        final newVersion = existingRecord.version + 1;
        final deleted = reminder.copyWith(
          deleted: true,
          updatedAt: DateTime.now().toUtc(),
          version: newVersion,
        );

        await _db
            .update(_db.reminders)
            .replace(ReminderMapper.toDbCompanion(deleted));
        await _syncQueue.enqueueOrCoalesce(
          SyncQueueItem(
            id: const Uuid().v7(),
            entityTable: 'reminders',
            entityId: id,
            operation: 'delete',
            payload: jsonEncode(deleted.toJson()),
            batchId: null,
            version: deleted.version,
            updatedAt: deleted.updatedAt,
            createdAt: DateTime.now().toUtc(),
          ),
        );
      });
    }
  }

  @override
  Future<void> markCompleted(String id, bool completed) async {
    final reminder = await getReminder(id);
    if (reminder != null) {
      final updated = reminder.copyWith(completed: completed);
      await updateReminder(updated);
    }
  }
}
