import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/reminders/presentation/utils/reminder_display_formatter.dart';

void main() {
  group('ReminderDisplayFormatter', () {
    testWidgets('formatTime returns correct time using locale',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final dt = DateTime(2026, 9, 20, 15, 30); // 3:30 PM
            final formatted = ReminderDisplayFormatter.formatTime(context, dt);
            expect(formatted, contains('3:30'));
            return const SizedBox();
          },
        ),
      ),);
    });

    testWidgets('formatDueLabel formats today correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) {
            final now = DateTime.now();
            final dt =
                DateTime(now.year, now.month, now.day, 14, 0); // 2:00 PM today
            final formatted =
                ReminderDisplayFormatter.formatDueLabel(context, dt);
            expect(formatted, contains('Due:'));
            expect(formatted, contains('2:00'));
            return const SizedBox();
          },
        ),
      ),);
    });

    test('formatNotificationBody formats tomorrow correctly', () {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, 9, 0)
          .add(const Duration(days: 1));
      final formatted = ReminderDisplayFormatter.formatNotificationBody(dt);
      expect(formatted, 'Due tomorrow at 9:00 AM');
    });

    test('formatRecurrence handles daily', () {
      expect(ReminderDisplayFormatter.formatRecurrence('FREQ=DAILY'), 'daily');
    });
  });
}
