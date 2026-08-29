import 'package:flutter_test/flutter_test.dart';
import 'package:ketion/core/utils/logger.dart';

void main() {
  group('AppLogger', () {
    test('Logger should initialize without crashing', () {
      expect(() => appLogger.i('Test info log'), returnsNormally);
      expect(() => appLogger.e('Test error log', Exception('Test Exception')), returnsNormally);
    });
  });
}
