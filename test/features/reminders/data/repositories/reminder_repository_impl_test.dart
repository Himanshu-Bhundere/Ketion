import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:ketion/core/database/app_database.dart';
import 'package:ketion/features/reminders/data/repositories/reminder_repository_impl.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/sync/data/repositories/sync_queue_repository_impl.dart';
import 'package:drift/drift.dart' as drift;

void main() {
  late AppDatabase database;
  late ReminderRepositoryImpl repository;
  late SyncQueueRepositoryImpl syncQueue;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    syncQueue = SyncQueueRepositoryImpl(database);
    repository = ReminderRepositoryImpl(database, syncQueue);
  });

  tearDown(() async {
    await database.close();
  });

  group('ReminderRepositoryImpl - CRUD & Sync Queue', () {
    test('addReminder creates reminder and sync_queue entry', () async {
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: 'page1',
              title: const drift.Value('Test Page'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final reminder = ReminderEntity(
        id: 'reminder1',
        pageId: 'page1',
        title: 'Test Reminder',
        reminderTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.addReminder(reminder);

      final reminderInDb = await repository.getReminder('reminder1');
      expect(reminderInDb, isNotNull);
      expect(reminderInDb!.title, 'Test Reminder');
      expect(reminderInDb.version, 1);

      final queueItems = await database.select(database.syncQueue).get();
      expect(queueItems.length, 1);
      expect(queueItems.first.entityId, 'reminder1');
      expect(queueItems.first.entityTable, 'reminders');
      expect(queueItems.first.operation, 'create');
    });

    test('updateReminder bumps version and creates sync_queue entry', () async {
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: 'page1',
              title: const drift.Value('Test Page'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final reminder = ReminderEntity(
        id: 'reminder1',
        pageId: 'page1',
        title: 'Test Reminder',
        reminderTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.addReminder(reminder);

      final updatedReminder = reminder.copyWith(title: 'Updated Reminder');
      await repository.updateReminder(updatedReminder);

      final reminderInDb = await repository.getReminder('reminder1');
      expect(reminderInDb!.title, 'Updated Reminder');
      expect(reminderInDb.version, 2);

      final queueItems = await (database.select(database.syncQueue)
            ..where((t) => t.entityId.equals('reminder1')))
          .get();
      
      expect(queueItems.length, 1); // coalesced update into create
      expect(queueItems.last.operation, 'create');
    });

    test('deleteReminder creates sync_queue entry', () async {
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: 'page1',
              title: const drift.Value('Test Page'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final reminder = ReminderEntity(
        id: 'reminder1',
        pageId: 'page1',
        title: 'Test Reminder',
        reminderTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repository.addReminder(reminder);
      await repository.deleteReminder('reminder1');

      final remindersInDb = await database.select(database.reminders).get();
      expect(remindersInDb.length, 1);
      expect(remindersInDb.single.deleted, true);

      final queueItems = await (database.select(database.syncQueue)
            ..where((t) => t.entityId.equals('reminder1')))
          .get();
      
      // 1 create + 1 delete = coalesced and removed
      expect(queueItems.length, 0); 
    });

    test('markCompleted updates completed status', () async {
      await database.into(database.pages).insert(
            PagesCompanion.insert(
              id: 'page1',
              title: const drift.Value('Test Page'),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      final reminder = ReminderEntity(
        id: 'reminder1',
        pageId: 'page1',
        title: 'Test Reminder',
        reminderTime: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        completed: false,
      );

      await repository.addReminder(reminder);
      await repository.markCompleted('reminder1', true);

      final reminderInDb = await repository.getReminder('reminder1');
      expect(reminderInDb!.completed, true);
    });
  });
}
