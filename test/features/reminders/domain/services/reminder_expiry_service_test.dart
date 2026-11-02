import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';
import 'package:ketion/features/reminders/domain/models/reminder_notification_content.dart';
import 'package:ketion/features/reminders/domain/repositories/reminder_repository.dart';
import 'package:ketion/features/reminders/domain/services/reminder_expiry_service.dart';
import 'package:ketion/features/reminders/domain/services/reminder_snooze_reconciler.dart';
import 'package:ketion/features/reminders/presentation/services/reminder_scheduler.dart';

class FakeReminderRepository implements ReminderRepository {
  final Map<String, ReminderEntity> _store = {};

  void seed(List<ReminderEntity> reminders) {
    for (final r in reminders) {
      _store[r.id] = r;
    }
  }

  @override
  Stream<List<ReminderEntity>> watchAllActiveReminders() {
    final active = _store.values
        .where((r) => !r.completed && !r.deleted)
        .toList();
    return Stream.value(active);
  }

  @override
  Stream<List<ReminderEntity>> watchAllNotDeletedReminders() {
    final notDeleted = _store.values
        .where((r) => !r.deleted)
        .toList();
    return Stream.value(notDeleted);
  }

  @override
  Stream<List<ReminderEntity>> watchRemindersForPage(String pageId) {
    final list = _store.values
        .where((r) => r.pageId == pageId && !r.deleted)
        .toList();
    return Stream.value(list);
  }

  @override
  Future<ReminderEntity?> getReminder(String id) async => _store[id];

  @override
  Future<void> addReminder(ReminderEntity reminder) async {
    _store[reminder.id] = reminder;
  }

  @override
  Future<void> updateReminder(ReminderEntity reminder) async {
    _store[reminder.id] = reminder;
  }

  @override
  Future<void> deleteReminder(String id) async {
    final existing = _store[id];
    if (existing != null) {
      _store[id] = existing.copyWith(deleted: true);
    }
  }

  @override
  Future<void> markCompleted(String id, bool completed) async {
    final existing = _store[id];
    if (existing != null) {
      _store[id] = existing.copyWith(completed: completed);
    }
  }
}

class FakeReminderScheduler implements ReminderScheduler {
  final List<String> cancelledIds = [];

  @override
  Future<void> cancelReminder(String id) async {
    cancelledIds.add(id);
  }

  @override
  Future<void> cancelAllReminders() async {}

  @override
  Future<void> scheduleReminder(
    ReminderEntity reminder, {
    ReminderNotificationContent? content,
  }) async {}
}

void main() {
  group('ReminderExpiryService', () {
    late FakeReminderRepository repository;
    late FakeReminderScheduler scheduler;
    late ReminderExpiryService service;

    setUp(() {
      repository = FakeReminderRepository();
      scheduler = FakeReminderScheduler();
      service = ReminderExpiryService(repository, scheduler);
    });

    final now = DateTime.utc(2026, 11, 1, 12, 0, 0);

    ReminderEntity createReminder({
      required String id,
      required DateTime reminderTime,
      String? recurrenceRule,
      DateTime? snoozeUntil,
      bool completed = false,
      bool deleted = false,
      ReminderKind kind = ReminderKind.reminder,
    }) {
      return ReminderEntity(
        id: id,
        pageId: 'page-1',
        title: 'Reminder $id',
        reminderTime: reminderTime,
        recurrenceRule: recurrenceRule,
        snoozeUntil: snoozeUntil,
        completed: completed,
        deleted: deleted,
        kind: kind,
        createdAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now.subtract(const Duration(hours: 1)),
      );
    }

    group('isExpired evaluation', () {
      test('returns true if reminder is completed and expired (>= 5 minutes ago)', () {
        final completed = createReminder(
          id: '1',
          reminderTime: now.subtract(const Duration(minutes: 10)),
          completed: true,
        );
        expect(service.isExpired(completed, now: now), isTrue);
      });

      test('returns false if reminder is completed but fired less than 5 minutes ago', () {
        final completedRecent = createReminder(
          id: '1b',
          reminderTime: now.subtract(const Duration(minutes: 3)),
          completed: true,
        );
        expect(service.isExpired(completedRecent, now: now), isFalse);
      });

      test('returns false if reminder is deleted', () {
        final deleted = createReminder(
          id: '2',
          reminderTime: now.subtract(const Duration(minutes: 10)),
          deleted: true,
        );
        expect(service.isExpired(deleted, now: now), isFalse);
      });

      test('returns false if recurring even if past fire time', () {
        final recurring = createReminder(
          id: '3',
          reminderTime: now.subtract(const Duration(minutes: 10)),
          recurrenceRule: 'FREQ=DAILY',
        );

        expect(service.isExpired(recurring, now: now), isFalse);
      });

      test('returns false if reminder is scheduled in the future', () {
        final future = createReminder(
          id: '4',
          reminderTime: now.add(const Duration(minutes: 10)),
        );

        expect(service.isExpired(future, now: now), isFalse);
      });

      test('returns false if reminder fired less than 5 minutes ago', () {
        final recent = createReminder(
          id: '5',
          reminderTime: now.subtract(const Duration(minutes: 4, seconds: 59)),
        );

        expect(service.isExpired(recent, now: now), isFalse);
      });

      test('returns true if reminder fired exactly or more than 5 minutes ago', () {
        final exactlyFive = createReminder(
          id: '6',
          reminderTime: now.subtract(const Duration(minutes: 5)),
        );
        final older = createReminder(
          id: '7',
          reminderTime: now.subtract(const Duration(minutes: 15)),
        );

        expect(service.isExpired(exactlyFive, now: now), isTrue);
        expect(service.isExpired(older, now: now), isTrue);
      });

      test('returns false if reminder fired long ago but snoozeUntil is in future', () {
        final snoozedFuture = createReminder(
          id: '8',
          reminderTime: now.subtract(const Duration(minutes: 30)),
          snoozeUntil: now.add(const Duration(minutes: 5)),
        );

        expect(service.isExpired(snoozedFuture, now: now), isFalse);
      });

      test('returns false if snooze fired less than 5 minutes ago', () {
        final snoozedRecent = createReminder(
          id: '9',
          reminderTime: now.subtract(const Duration(minutes: 30)),
          snoozeUntil: now.subtract(const Duration(minutes: 3)),
        );

        expect(service.isExpired(snoozedRecent, now: now), isFalse);
      });

      test('returns true if snooze fired 5 or more minutes ago', () {
        final snoozedExpired = createReminder(
          id: '10',
          reminderTime: now.subtract(const Duration(minutes: 30)),
          snoozeUntil: now.subtract(const Duration(minutes: 6)),
        );

        expect(service.isExpired(snoozedExpired, now: now), isTrue);
      });
    });

    group('cleanupExpiredReminders', () {
      test('cleans up all and only expired one-shot reminders, including completed ones', () async {
        final rExpired1 = createReminder(
          id: 'exp-1',
          reminderTime: now.subtract(const Duration(minutes: 10)),
        );
        final rExpiredAlarm = createReminder(
          id: 'exp-alarm',
          reminderTime: now.subtract(const Duration(minutes: 6)),
          kind: ReminderKind.alarm,
        );
        final rCompletedExpired = createReminder(
          id: 'completed-exp',
          reminderTime: now.subtract(const Duration(minutes: 8)),
          completed: true,
        );
        final rCompletedRecent = createReminder(
          id: 'completed-recent',
          reminderTime: now.subtract(const Duration(minutes: 2)),
          completed: true,
        );
        final rFuture = createReminder(
          id: 'future',
          reminderTime: now.add(const Duration(minutes: 15)),
        );
        final rRecurring = createReminder(
          id: 'recurring',
          reminderTime: now.subtract(const Duration(minutes: 20)),
          recurrenceRule: 'FREQ=WEEKLY',
        );
        final rSnoozed = createReminder(
          id: 'snoozed',
          reminderTime: now.subtract(const Duration(minutes: 20)),
          snoozeUntil: now.add(const Duration(minutes: 10)),
        );

        repository.seed([
          rExpired1,
          rExpiredAlarm,
          rCompletedExpired,
          rCompletedRecent,
          rFuture,
          rRecurring,
          rSnoozed,
        ]);

        final cleanedCount = await service.cleanupExpiredReminders(now: now);

        expect(cleanedCount, 3);
        expect(scheduler.cancelledIds, containsAll(['exp-1', 'exp-alarm', 'completed-exp']));

        final exp1After = await repository.getReminder('exp-1');
        final expAlarmAfter = await repository.getReminder('exp-alarm');
        final completedExpAfter = await repository.getReminder('completed-exp');
        final completedRecentAfter = await repository.getReminder('completed-recent');
        final futureAfter = await repository.getReminder('future');
        final recurringAfter = await repository.getReminder('recurring');
        final snoozedAfter = await repository.getReminder('snoozed');

        expect(exp1After!.deleted, isTrue);
        expect(expAlarmAfter!.deleted, isTrue);
        expect(completedExpAfter!.deleted, isTrue);
        expect(completedRecentAfter!.deleted, isFalse);
        expect(futureAfter!.deleted, isFalse);
        expect(recurringAfter!.deleted, isFalse);
        expect(snoozedAfter!.deleted, isFalse);
      });
    });

    group('ReminderSnoozeReconciler', () {
      test('clears snoozeUntil only in memory and preserves persisted snoozeUntil', () async {
        final reconciler = ReminderSnoozeReconciler(repository);
        final snoozeTime = DateTime.now().subtract(const Duration(minutes: 20));
        final pastSnooze = createReminder(
          id: 'snooze-reconcile-1',
          reminderTime: DateTime.now().subtract(const Duration(hours: 1)),
          snoozeUntil: snoozeTime,
        );
        repository.seed([pastSnooze]);

        final updatedList = await reconciler.reconcileExpiredSnoozes([pastSnooze]);

        // In-memory snapshot has snoozeUntil cleared for presentation
        expect(updatedList.first.snoozeUntil, isNull);

        // Repository still retains persisted snoozeUntil for expiry service
        final persisted = await repository.getReminder('snooze-reconcile-1');
        expect(persisted!.snoozeUntil, equals(snoozeTime));
      });
    });
  });
}
