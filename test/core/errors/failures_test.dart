import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/errors/failures.dart';

void main() {
  group('Failures', () {
    test('ValidationFailure should hold message and toString correctly', () {
      const failure = ValidationFailure('Invalid input');
      expect(failure.message, 'Invalid input');
      expect(failure.toString(), 'ValidationFailure: Invalid input');
    });

    test('StorageFailure should hold message and toString correctly', () {
      const failure = StorageFailure('Database error');
      expect(failure.message, 'Database error');
      expect(failure.toString(), 'StorageFailure: Database error');
    });

    test('SyncFailure should hold message and toString correctly', () {
      const failure = SyncFailure('Network timeout during sync');
      expect(failure.message, 'Network timeout during sync');
      expect(failure.toString(), 'SyncFailure: Network timeout during sync');
    });

    test('NetworkFailure should hold message and toString correctly', () {
      const failure = NetworkFailure('No internet');
      expect(failure.message, 'No internet');
      expect(failure.toString(), 'NetworkFailure: No internet');
    });

    test('UnknownFailure should hold message and toString correctly', () {
      const failure = UnknownFailure('Unknown error occurred');
      expect(failure.message, 'Unknown error occurred');
      expect(failure.toString(), 'UnknownFailure: Unknown error occurred');
    });
  });
}
