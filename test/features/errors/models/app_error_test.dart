import 'package:flutter_test/flutter_test.dart';
import 'package:kaya_desktop/features/errors/models/app_error.dart';

void main() {
  group('AppError', () {
    test('creates error with required fields', () {
      final error = AppError(
        id: 'test-1',
        message: 'Something went wrong',
        severity: ErrorSeverity.error,
        timestamp: DateTime.utc(2026, 3, 1),
      );

      expect(error.id, equals('test-1'));
      expect(error.message, equals('Something went wrong'));
      expect(error.severity, equals(ErrorSeverity.error));
      expect(error.details, isNull);
    });

    test('creates error with optional details', () {
      final error = AppError(
        id: 'test-2',
        message: 'Sync failed',
        severity: ErrorSeverity.error,
        timestamp: DateTime.utc(2026, 3, 1),
        details: 'Connection refused: 192.168.1.1:443',
      );

      expect(error.details, equals('Connection refused: 192.168.1.1:443'));
    });

    test('creates warning', () {
      final warning = AppError(
        id: 'test-3',
        message: 'Slow connection',
        severity: ErrorSeverity.warning,
        timestamp: DateTime.utc(2026, 3, 1),
      );

      expect(warning.severity, equals(ErrorSeverity.warning));
    });

    test('freezed equality works', () {
      final a = AppError(
        id: 'test-1',
        message: 'Error',
        severity: ErrorSeverity.error,
        timestamp: DateTime.utc(2026, 3, 1),
      );
      final b = AppError(
        id: 'test-1',
        message: 'Error',
        severity: ErrorSeverity.error,
        timestamp: DateTime.utc(2026, 3, 1),
      );

      expect(a, equals(b));
    });
  });

  group('ErrorSeverity', () {
    test('has error and warning values', () {
      expect(ErrorSeverity.values, contains(ErrorSeverity.error));
      expect(ErrorSeverity.values, contains(ErrorSeverity.warning));
    });
  });
}
