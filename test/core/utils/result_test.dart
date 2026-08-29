import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/utils/result.dart';
import 'package:ketion/core/errors/failures.dart';

void main() {
  group('Result', () {
    test('Success should return the value on fold', () {
      const result = Success<String>('Data');

      final folded = result.fold(
        (value) => 'Success: $value',
        (failure) => 'Failure',
      );

      expect(folded, 'Success: Data');
    });

    test('Error should return the failure on fold', () {
      const failure = UnknownFailure('Something went wrong');
      const result = Error<String>(failure);

      final folded = result.fold(
        (value) => 'Success',
        (f) => 'Failure: ${f.message}',
      );

      expect(folded, 'Failure: Something went wrong');
    });
  });
}
