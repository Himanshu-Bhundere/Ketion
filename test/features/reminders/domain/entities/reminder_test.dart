import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/reminders/domain/entities/reminder.dart';
import 'package:ketion/features/reminders/domain/models/reminder_kind.dart';

void main() {
  group('ReminderEntity JSON Serialization', () {
    test('fromJson defaults kind to reminder if missing', () {
      final json = {
        'id': 'test-1',
        'pageId': 'page-1',
        'title': 'Test Reminder',
        'reminderTime': '2025-01-01T12:00:00.000Z',
        'timezone': 'UTC',
        'completed': false,
        'version': 1,
        'createdAt': '2025-01-01T10:00:00.000Z',
        'updatedAt': '2025-01-01T10:00:00.000Z',
        'deleted': false,
      };

      final reminder = ReminderEntity.fromJson(json);

      expect(reminder.kind, ReminderKind.reminder);
    });

    test('fromJson handles unknown kind gracefully', () {
      final json = {
        'id': 'test-1',
        'pageId': 'page-1',
        'title': 'Test Reminder',
        'reminderTime': '2025-01-01T12:00:00.000Z',
        'timezone': 'UTC',
        'kind': 'some_unknown_kind',
        'completed': false,
        'version': 1,
        'createdAt': '2025-01-01T10:00:00.000Z',
        'updatedAt': '2025-01-01T10:00:00.000Z',
        'deleted': false,
      };

      final reminder = ReminderEntity.fromJson(json);

      expect(reminder.kind, ReminderKind.reminder);
    });

    test('fromJson parses alarm kind correctly', () {
      final json = {
        'id': 'test-1',
        'pageId': 'page-1',
        'title': 'Test Alarm',
        'reminderTime': '2025-01-01T12:00:00.000Z',
        'timezone': 'UTC',
        'kind': 'alarm',
        'completed': false,
        'version': 1,
        'createdAt': '2025-01-01T10:00:00.000Z',
        'updatedAt': '2025-01-01T10:00:00.000Z',
        'deleted': false,
      };

      final reminder = ReminderEntity.fromJson(json);

      expect(reminder.kind, ReminderKind.alarm);
    });

    test('toJson serializes kind correctly', () {
      final reminder = ReminderEntity(
        id: 'test-1',
        pageId: 'page-1',
        title: 'Test Alarm',
        reminderTime: DateTime.parse('2025-01-01T12:00:00.000Z'),
        timezone: 'UTC',
        kind: ReminderKind.alarm,
        createdAt: DateTime.parse('2025-01-01T10:00:00.000Z'),
        updatedAt: DateTime.parse('2025-01-01T10:00:00.000Z'),
      );

      final json = reminder.toJson();

      expect(json['kind'], 'alarm');
    });
  });
}
