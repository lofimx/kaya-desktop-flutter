import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart' as pkg;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'logger_service.g.dart';

/// Dual-output logging service: console + file.
class LoggerService {
  final pkg.Logger _logger;
  final File? _logFile;

  LoggerService(this._logger, this._logFile);

  void d(String message) {
    _logger.d(message);
    _writeToFile('DEBUG', message);
  }

  void i(String message) {
    _logger.i(message);
    _writeToFile('INFO', message);
  }

  void w(String message) {
    _logger.w(message);
    _writeToFile('WARN', message);
  }

  void e(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
    _writeToFile('ERROR', '$message${error != null ? '\n$error' : ''}');
  }

  void _writeToFile(String level, String message) {
    if (_logFile == null) return;
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      _logFile.writeAsStringSync(
        '[$timestamp] $level: $message\n',
        mode: FileMode.append,
      );
    } catch (_) {
      // Silently ignore file write errors
    }
  }

  /// Reads the log file contents.
  Future<String> readLogs() async {
    if (_logFile == null || !_logFile.existsSync()) return '';
    return await _logFile.readAsString();
  }

  /// Clears the log file.
  Future<void> clearLogs() async {
    if (_logFile != null && _logFile.existsSync()) {
      await _logFile.writeAsString('');
    }
  }

  /// Gets the log file path.
  String? get logFilePath => _logFile?.path;
}

@Riverpod(keepAlive: true)
LoggerService loggerService(Ref ref) {
  final logger = pkg.Logger(
    printer: pkg.PrettyPrinter(methodCount: 0),
  );

  // Set up log file in ~/.kaya/
  final home = Platform.environment['HOME'] ??
      Platform.environment['USERPROFILE'] ??
      '.';
  final logDir = Directory('$home/.kaya');
  if (!logDir.existsSync()) {
    logDir.createSync(recursive: true);
  }
  final logFile = File('${logDir.path}/desktop-app-log');

  return LoggerService(logger, logFile);
}

/// Convenience provider alias matching kaya-flutter pattern.
@riverpod
LoggerService logger(Ref ref) {
  return ref.watch(loggerServiceProvider);
}
