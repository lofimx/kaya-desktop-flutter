import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_error.freezed.dart';

/// Severity level for app errors.
enum ErrorSeverity {
  error,
  warning,
}

/// Represents an in-memory error or warning tracked by the app.
@freezed
class AppError with _$AppError {
  const factory AppError({
    required String id,
    required String message,
    required ErrorSeverity severity,
    required DateTime timestamp,
    String? details,
  }) = _AppError;
}
