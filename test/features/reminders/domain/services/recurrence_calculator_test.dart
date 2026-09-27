import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/features/reminders/domain/services/recurrence_calculator.dart';

void main() {
  group('RecurrenceCalculator', () {
    late RecurrenceCalculator calculator;

    setUp(() {
      calculator = RecurrenceCalculator();
    });

    test('daily recurrence adds 1 day', () {
      final current = DateTime.utc(2026, 1, 1, 10, 0); // Local would be whatever, testing logic via UTC for simplicity if we don't care about the DST gap in test
      final next = calculator.nextOccurrence(current: current, rule: 'DAILY');
      
      expect(next?.day, 2);
      expect(next?.month, 1);
      expect(next?.year, 2026);
    });

    test('weekly recurrence adds 7 days', () {
      final current = DateTime.utc(2026, 1, 1, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: 'WEEKLY');
      
      expect(next?.day, 8);
      expect(next?.month, 1);
      expect(next?.year, 2026);
    });

    test('monthly recurrence adds 1 month normally', () {
      final current = DateTime.utc(2026, 1, 15, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: 'MONTHLY');
      
      expect(next?.day, 15);
      expect(next?.month, 2);
      expect(next?.year, 2026);
    });

    test('monthly recurrence clamps days at month-end', () {
      final current = DateTime.utc(2026, 1, 31, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: 'MONTHLY');
      
      // Feb 2026 has 28 days
      expect(next?.day, 28);
      expect(next?.month, 2);
      expect(next?.year, 2026);
    });

    test('monthly recurrence clamps days at month-end for leap year', () {
      final current = DateTime.utc(2024, 1, 31, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: 'MONTHLY');
      
      // Feb 2024 has 29 days
      expect(next?.day, 29);
      expect(next?.month, 2);
      expect(next?.year, 2024);
    });

    test('monthly recurrence crosses year boundary', () {
      final current = DateTime.utc(2025, 12, 15, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: 'MONTHLY');
      
      expect(next?.day, 15);
      expect(next?.month, 1);
      expect(next?.year, 2026);
    });
    
    test('returns null for null rule', () {
      final current = DateTime.utc(2026, 1, 1, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: null);
      
      expect(next, isNull);
    });
    
    test('returns null for invalid rule', () {
      final current = DateTime.utc(2026, 1, 1, 10, 0);
      final next = calculator.nextOccurrence(current: current, rule: 'YEARLY');
      
      expect(next, isNull);
    });
  });
}
