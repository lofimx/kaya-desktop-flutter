import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kaya_desktop/features/errors/models/app_error.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'error_service.g.dart';

/// In-memory error tracking service.
@Riverpod(keepAlive: true)
class ErrorService extends _$ErrorService {
  int _nextId = 0;

  @override
  List<AppError> build() => [];

  /// Adds an error.
  void addError(String message, {String? details}) {
    final error = AppError(
      id: 'error-${_nextId++}',
      message: message,
      severity: ErrorSeverity.error,
      timestamp: DateTime.now().toUtc(),
      details: details,
    );
    state = [error, ...state];
  }

  /// Adds a warning.
  void addWarning(String message, {String? details}) {
    final warning = AppError(
      id: 'warning-${_nextId++}',
      message: message,
      severity: ErrorSeverity.warning,
      timestamp: DateTime.now().toUtc(),
      details: details,
    );
    state = [warning, ...state];
  }

  /// Removes an error by ID.
  void removeError(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  /// Clears all errors.
  void clearAll() {
    state = [];
  }
}

/// Whether there are any active errors.
@riverpod
bool hasErrors(Ref ref) {
  return ref.watch(errorServiceProvider).isNotEmpty;
}

/// Count of active errors.
@riverpod
int errorCount(Ref ref) {
  return ref.watch(errorServiceProvider).length;
}
