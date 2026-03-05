import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kaya_desktop/core/services/logger_service.dart';
import 'package:kaya_desktop/features/account/services/account_repository.dart';
import 'package:kaya_desktop/features/anga/services/anga_repository.dart';
import 'package:kaya_desktop/features/anga/services/file_storage_service.dart';
import 'package:kaya_desktop/features/errors/services/error_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_service.g.dart';

/// Result of a sync operation.
class SyncResult {
  final int angaDownloaded;
  final int angaUploaded;
  final int metaDownloaded;
  final int metaUploaded;
  final int faviconDownloaded;
  final int wordsDownloaded;
  final List<String> errors;
  final bool isConnectionError;

  SyncResult({
    this.angaDownloaded = 0,
    this.angaUploaded = 0,
    this.metaDownloaded = 0,
    this.metaUploaded = 0,
    this.faviconDownloaded = 0,
    this.wordsDownloaded = 0,
    this.errors = const [],
    this.isConnectionError = false,
  });

  bool get hasChanges =>
      angaDownloaded > 0 ||
      angaUploaded > 0 ||
      metaDownloaded > 0 ||
      metaUploaded > 0 ||
      faviconDownloaded > 0 ||
      wordsDownloaded > 0;

  bool get hasErrors => errors.isNotEmpty;
}

/// Service for syncing local files with the Kaya server.
class SyncService {
  final FileStorageService _storage;
  final AccountRepository _accountRepo;
  final LoggerService? _logger;
  final ErrorService _errorService;

  SyncService(
    this._storage,
    this._accountRepo,
    this._logger,
    this._errorService,
  );

  /// Performs a full sync with the server.
  Future<SyncResult> sync() async {
    final settings = await _accountRepo.loadSettings();
    if (!settings.canSync) {
      return SyncResult(errors: ['No credentials configured']);
    }

    final email = settings.email!;
    final password = await _accountRepo.getPassword();
    if (password == null) {
      return SyncResult(errors: ['Password not set']);
    }

    final baseUrl = settings.serverUrl;
    final errors = <String>[];
    var isConnectionError = false;

    var angaDownloaded = 0;
    var angaUploaded = 0;
    var metaDownloaded = 0;
    var metaUploaded = 0;
    var faviconDownloaded = 0;
    var wordsDownloaded = 0;

    try {
      // Sync anga files
      final angaResult = await _syncDir(
        baseUrl, email, password,
        serverPath: 'anga',
        listLocal: () => _storage.listAngaFiles(),
        localDirPath: _storage.angaPath,
        upload: true,
      );
      angaDownloaded = angaResult.downloaded;
      angaUploaded = angaResult.uploaded;
      errors.addAll(angaResult.errors);
      if (angaResult.isConnectionError) {
        isConnectionError = true;
      }

      // Sync meta files
      if (!isConnectionError) {
        final metaResult = await _syncDir(
          baseUrl, email, password,
          serverPath: 'meta',
          listLocal: () => _storage.listMetaFiles(),
          localDirPath: _storage.metaPath,
          upload: true,
        );
        metaDownloaded = metaResult.downloaded;
        metaUploaded = metaResult.uploaded;
        errors.addAll(metaResult.errors);
        if (metaResult.isConnectionError) isConnectionError = true;
      }

      // Sync favicons from cache (download only)
      if (!isConnectionError) {
        final faviconResult = await _syncFavicons(baseUrl, email, password);
        faviconDownloaded = faviconResult.downloaded;
        errors.addAll(faviconResult.errors);
        if (faviconResult.isConnectionError) isConnectionError = true;
      }

      // Sync words (download only)
      if (!isConnectionError) {
        final wordsResult = await _syncWords(baseUrl, email, password);
        wordsDownloaded = wordsResult.downloaded;
        errors.addAll(wordsResult.errors);
        if (wordsResult.isConnectionError) isConnectionError = true;
      }
    } on SocketException catch (e) {
      isConnectionError = true;
      _logger?.w('Sync connection error: $e');
    } on http.ClientException catch (e) {
      isConnectionError = true;
      _logger?.w('Sync connection error: $e');
    } catch (e) {
      errors.add('Sync failed: $e');
      _logger?.e('Sync failed', e);
    }

    final result = SyncResult(
      angaDownloaded: angaDownloaded,
      angaUploaded: angaUploaded,
      metaDownloaded: metaDownloaded,
      metaUploaded: metaUploaded,
      faviconDownloaded: faviconDownloaded,
      wordsDownloaded: wordsDownloaded,
      errors: errors,
      isConnectionError: isConnectionError,
    );

    if (result.hasChanges) {
      _logger?.i(
        'Sync complete: ${angaDownloaded + metaDownloaded + faviconDownloaded + wordsDownloaded} downloaded, '
        '${angaUploaded + metaUploaded} uploaded',
      );
    }

    if (result.hasErrors && !result.isConnectionError) {
      for (final error in errors) {
        _errorService.addError(error);
      }
    }

    return result;
  }

  /// Tests the connection to the server.
  Future<bool> testConnection() async {
    final settings = await _accountRepo.loadSettings();
    if (!settings.canSync) return false;

    final email = settings.email!;
    final password = await _accountRepo.getPassword();
    if (password == null) return false;

    try {
      final response = await _makeRequest(
        'GET',
        '${settings.serverUrl}/api/v1/${Uri.encodeComponent(email)}/anga',
        email,
        password,
      );
      return response.statusCode == 200;
    } catch (e) {
      _logger?.e('Connection test failed', e);
      return false;
    }
  }

  Future<_SyncDirResult> _syncDir(
    String baseUrl,
    String email,
    String password, {
    required String serverPath,
    required Future<List<String>> Function() listLocal,
    required String localDirPath,
    required bool upload,
  }) async {
    final result = _SyncDirResult();

    try {
      final serverFiles = await _fetchFileList(
        '$baseUrl/api/v1/${Uri.encodeComponent(email)}/$serverPath',
        email,
        password,
      );

      final localFiles = await listLocal();

      final toDownload = serverFiles.where((f) => !localFiles.contains(f));
      final toUpload =
          upload ? localFiles.where((f) => !serverFiles.contains(f)) : <String>[];

      for (final filename in toDownload) {
        try {
          final response = await _makeRequest(
            'GET',
            '$baseUrl/api/v1/${Uri.encodeComponent(email)}/$serverPath/$filename',
            email,
            password,
          );
          if (response.statusCode == 200) {
            final path = '$localDirPath/$filename';
            await File(path).writeAsBytes(response.bodyBytes);
            result.downloaded++;
            _logger?.i('[${serverPath.toUpperCase()} DOWNLOAD] $filename');
          }
        } catch (e) {
          if (_isConnectionError(e)) {
            result.isConnectionError = true;
            return result;
          }
          result.errors.add('Failed to download $filename: $e');
        }
      }

      for (final filename in toUpload) {
        try {
          final path = '$localDirPath/$filename';
          final file = File(path);
          final bytes = await file.readAsBytes();

          final response = await _uploadFile(
            '$baseUrl/api/v1/${Uri.encodeComponent(email)}/$serverPath/$filename',
            email,
            password,
            filename,
            bytes,
          );

          if (response.statusCode == 201 || response.statusCode == 200) {
            result.uploaded++;
            _logger?.i('[${serverPath.toUpperCase()} UPLOAD] $filename');
          } else if (response.statusCode == 409) {
            _logger?.w(
              '[${serverPath.toUpperCase()} SKIP] $filename (already exists)',
            );
          } else {
            result.errors.add(
              'Failed to upload $filename: ${response.statusCode}',
            );
          }
        } catch (e) {
          if (_isConnectionError(e)) {
            result.isConnectionError = true;
            return result;
          }
          result.errors.add('Failed to upload $filename: $e');
        }
      }
    } catch (e) {
      if (_isConnectionError(e)) {
        result.isConnectionError = true;
        return result;
      }
      result.errors.add('$serverPath sync failed: $e');
    }

    return result;
  }

  bool _isFaviconFile(String filename) {
    final lower = filename.toLowerCase();
    return lower.contains('favicon') ||
        lower == 'icon.png' ||
        lower == 'icon.ico';
  }

  Future<_SyncDirResult> _syncFavicons(
    String baseUrl,
    String email,
    String password,
  ) async {
    final result = _SyncDirResult();

    try {
      final serverBookmarks = await _fetchFileList(
        '$baseUrl/api/v1/${Uri.encodeComponent(email)}/cache',
        email,
        password,
      );

      for (final bookmark in serverBookmarks) {
        if (await _storage.hasFaviconOrMarker(bookmark)) continue;

        final serverFiles = await _fetchFileList(
          '$baseUrl/api/v1/${Uri.encodeComponent(email)}/cache/$bookmark',
          email,
          password,
        );

        final faviconFiles = serverFiles.where(_isFaviconFile).toList();

        if (faviconFiles.isEmpty) {
          await _storage.createNoFaviconMarker(bookmark);
          continue;
        }

        for (final filename in faviconFiles) {
          try {
            final response = await _makeRequest(
              'GET',
              '$baseUrl/api/v1/${Uri.encodeComponent(email)}/cache/$bookmark/$filename',
              email,
              password,
            );
            if (response.statusCode == 200) {
              await _storage.saveCacheFile(
                bookmark,
                filename,
                response.bodyBytes,
              );
              result.downloaded++;
              _logger?.i('[FAVICON DOWNLOAD] $bookmark/$filename');
            }
          } catch (e) {
            if (_isConnectionError(e)) {
              result.isConnectionError = true;
              return result;
            }
            result.errors.add(
              'Failed to download favicon $bookmark/$filename: $e',
            );
          }
        }
      }
    } catch (e) {
      if (_isConnectionError(e)) {
        result.isConnectionError = true;
        return result;
      }
      result.errors.add('Favicon sync failed: $e');
    }

    return result;
  }

  Future<_SyncDirResult> _syncWords(
    String baseUrl,
    String email,
    String password,
  ) async {
    final result = _SyncDirResult();

    try {
      final serverAngas = await _fetchFileList(
        '$baseUrl/api/v1/${Uri.encodeComponent(email)}/words',
        email,
        password,
      );

      final localAngas = await _storage.listWordsAngas();
      final toSync = serverAngas.where((a) => !localAngas.contains(a));

      for (final anga in toSync) {
        final serverFiles = await _fetchFileList(
          '$baseUrl/api/v1/${Uri.encodeComponent(email)}/words/$anga',
          email,
          password,
        );

        for (final filename in serverFiles) {
          try {
            final response = await _makeRequest(
              'GET',
              '$baseUrl/api/v1/${Uri.encodeComponent(email)}/words/$anga/$filename',
              email,
              password,
            );
            if (response.statusCode == 200) {
              await _storage.saveWordsFile(anga, filename, response.bodyBytes);
              result.downloaded++;
              _logger?.i('[WORDS DOWNLOAD] $anga/$filename');
            }
          } catch (e) {
            if (_isConnectionError(e)) {
              result.isConnectionError = true;
              return result;
            }
            result.errors.add('Failed to download words $anga/$filename: $e');
          }
        }
      }
    } catch (e) {
      if (_isConnectionError(e)) {
        result.isConnectionError = true;
        return result;
      }
      result.errors.add('Words sync failed: $e');
    }

    return result;
  }

  Future<List<String>> _fetchFileList(
    String url,
    String email,
    String password,
  ) async {
    final response = await _makeRequest('GET', url, email, password);
    if (response.statusCode == 200) {
      return response.body
          .split('\n')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList();
    }
    return [];
  }

  Future<http.Response> _makeRequest(
    String method,
    String url,
    String email,
    String password,
  ) async {
    final uri = Uri.parse(url);
    final request = http.Request(method, uri);
    request.headers['Authorization'] =
        'Basic ${base64Encode(utf8.encode('$email:$password'))}';

    final client = http.Client();
    try {
      final streamedResponse = await client.send(request);
      return await http.Response.fromStream(streamedResponse);
    } finally {
      client.close();
    }
  }

  Future<http.Response> _uploadFile(
    String url,
    String email,
    String password,
    String filename,
    List<int> bytes,
  ) async {
    final uri = Uri.parse(url);
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] =
        'Basic ${base64Encode(utf8.encode('$email:$password'))}';
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );

    final streamedResponse = await request.send();
    return await http.Response.fromStream(streamedResponse);
  }
}

class _SyncDirResult {
  int downloaded = 0;
  int uploaded = 0;
  final List<String> errors = [];
  bool isConnectionError = false;
}

bool _isConnectionError(Object e) {
  if (e is SocketException) return true;
  if (e is http.ClientException) {
    return e.toString().contains('SocketException');
  }
  return false;
}

@Riverpod(keepAlive: true)
Future<SyncService> syncService(Ref ref) async {
  final storage = await ref.watch(fileStorageServiceProvider.future);
  final accountRepo = await ref.watch(accountRepositoryProvider.future);
  final logger = ref.watch(loggerProvider);
  final errorService = ref.watch(errorServiceProvider.notifier);
  return SyncService(storage, accountRepo, logger, errorService);
}

/// State for sync status.
enum SyncStatus { idle, syncing, error }

/// State for server connection status.
enum SyncConnectionStatus {
  notConfigured,
  connected,
  disconnected,
}

/// Provider for tracking connection status separately from sync status.
@Riverpod(keepAlive: true)
class SyncConnectionStatusNotifier extends _$SyncConnectionStatusNotifier {
  @override
  SyncConnectionStatus build() => SyncConnectionStatus.notConfigured;

  void setConnected() {
    state = SyncConnectionStatus.connected;
  }

  void setDisconnected() {
    state = SyncConnectionStatus.disconnected;
  }

  void setNotConfigured() {
    state = SyncConnectionStatus.notConfigured;
  }
}

/// Convenience provider for reading connection status.
@riverpod
SyncConnectionStatus syncConnectionStatus(Ref ref) {
  return ref.watch(syncConnectionStatusNotifierProvider);
}

/// Notifier for managing sync state and scheduling.
@Riverpod(keepAlive: true)
class SyncController extends _$SyncController {
  Timer? _syncTimer;
  static const _syncInterval = Duration(seconds: 60);

  @override
  SyncStatus build() {
    ref.onDispose(() {
      _syncTimer?.cancel();
    });

    _startSyncTimer();
    // Trigger an immediate sync check instead of waiting for the first
    // 60-second timer tick.
    Future.microtask(() => _triggerSync());
    return SyncStatus.idle;
  }

  void _startSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncInterval, (_) {
      _triggerSync();
    });
  }

  Future<void> _triggerSync() async {
    final settings = await ref.read(accountSettingsNotifierProvider.future);
    if (!settings.canSync) {
      ref
          .read(syncConnectionStatusNotifierProvider.notifier)
          .setNotConfigured();
      return;
    }

    await sync();
  }

  /// Performs a sync and updates state.
  Future<SyncResult> sync() async {
    state = SyncStatus.syncing;

    final connectionNotifier = ref.read(
      syncConnectionStatusNotifierProvider.notifier,
    );

    try {
      final service = await ref.read(syncServiceProvider.future);
      final result = await service.sync();

      if (result.isConnectionError) {
        connectionNotifier.setDisconnected();
        state = SyncStatus.idle;
      } else {
        connectionNotifier.setConnected();
        if (result.hasErrors) {
          state = SyncStatus.error;
        } else {
          state = SyncStatus.idle;
        }
      }

      if (result.angaDownloaded > 0 ||
          result.metaDownloaded > 0 ||
          result.wordsDownloaded > 0) {
        ref.read(angaRepositoryProvider.notifier).refresh();
      }

      return result;
    } catch (e) {
      connectionNotifier.setDisconnected();
      state = SyncStatus.idle;
      return SyncResult(isConnectionError: true);
    }
  }

  /// Tests the connection to the server.
  Future<bool> testConnection() async {
    final service = await ref.read(syncServiceProvider.future);
    return await service.testConnection();
  }

  /// Forces a sync immediately.
  Future<SyncResult> forceSync() async {
    return await sync();
  }
}
