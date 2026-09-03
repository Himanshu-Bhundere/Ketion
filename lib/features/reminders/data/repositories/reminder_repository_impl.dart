import 'package:drift/drift.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/reminders/data/models/reminder_mapper.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';

class ReminderRepositoryImpl implements ReminderRepository {
  final AppDatabase _db;

  ReminderRepositoryImpl(this._db);

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
    await _db.into(_db.reminders).insert(
          ReminderMapper.toDbCompanion(reminder),
          mode: InsertMode.replace,
        );
  }

  @override
  Future<void> updateReminder(ReminderEntity reminder) async {
    final updated = reminder.copyWith(
      updatedAt: DateTime.now().toUtc(),
      version: reminder.version + 1,
    );
    await _db
        .update(_db.reminders)
        .replace(ReminderMapper.toDbCompanion(updated));
  }

  @override
  Future<void> deleteReminder(String id) async {
    final reminder = await getReminder(id);
    if (reminder != null) {
      final deleted = reminder.copyWith(
        deleted: true,
        updatedAt: DateTime.now().toUtc(),
        version: reminder.version + 1,
      );
      await updateReminder(deleted);
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
