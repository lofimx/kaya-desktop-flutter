import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kaya_desktop/features/anga/models/anga.dart';
import 'package:kaya_desktop/features/anga/models/anga_type.dart';
import 'package:kaya_desktop/features/anga/services/file_storage_service.dart';

void main() {
  late Directory tempDir;
  late FileStorageService service;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kaya_test_');
    service = FileStorageService(tempDir.path, null);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('FileStorageService', () {
    group('ensureDirectories', () {
      test('creates all required directories', () async {
        await service.ensureDirectories();

        expect(Directory(service.angaPath).existsSync(), isTrue);
        expect(Directory(service.metaPath).existsSync(), isTrue);
        expect(Directory(service.cachePath).existsSync(), isTrue);
        expect(Directory(service.wordsPath).existsSync(), isTrue);
      });
    });

    group('saveBookmark', () {
      test('saves bookmark as .url file', () async {
        final anga = await service.saveBookmark('https://example.com/');

        expect(anga.type, equals(AngaType.bookmark));
        expect(anga.filename, endsWith('.url'));
        expect(anga.url, equals('https://example.com/'));

        // Verify file exists on disk
        final file = File(anga.path);
        expect(file.existsSync(), isTrue);

        final content = file.readAsStringSync();
        expect(content, contains('[InternetShortcut]'));
        expect(content, contains('URL=https://example.com/'));
      });

      test('generates filename with sanitized domain', () async {
        final anga =
            await service.saveBookmark('https://www.example.com/path?q=1');

        expect(anga.filename, contains('www-example-com'));
      });
    });

    group('saveNote', () {
      test('saves note as .md file', () async {
        final anga = await service.saveNote('My test note');

        expect(anga.type, equals(AngaType.note));
        expect(anga.filename, endsWith('-note.md'));
        expect(anga.content, equals('My test note'));

        final file = File(anga.path);
        expect(file.existsSync(), isTrue);
        expect(file.readAsStringSync(), equals('My test note'));
      });
    });

    group('saveFile', () {
      test('copies file to anga directory', () async {
        // Create a source file
        final sourceDir = Directory.systemTemp.createTempSync('kaya_src_');
        final sourceFile = File('${sourceDir.path}/test-image.png');
        sourceFile.writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]); // PNG header

        final anga =
            await service.saveFile(sourceFile.path, 'test-image.png');

        expect(anga.type, equals(AngaType.file));
        expect(anga.filename, contains('test-image.png'));

        final savedFile = File(anga.path);
        expect(savedFile.existsSync(), isTrue);
        expect(savedFile.readAsBytesSync(), equals([0x89, 0x50, 0x4E, 0x47]));

        sourceDir.deleteSync(recursive: true);
      });
    });

    group('saveFileBytes', () {
      test('saves raw bytes as file', () async {
        final bytes = [0x25, 0x50, 0x44, 0x46]; // PDF header
        final anga = await service.saveFileBytes(bytes, 'document.pdf');

        expect(anga.filename, contains('document.pdf'));

        final savedFile = File(anga.path);
        expect(savedFile.readAsBytesSync(), equals(bytes));
      });
    });

    group('listAngaFiles', () {
      test('returns empty list when no files', () async {
        await service.ensureDirectories();
        final files = await service.listAngaFiles();
        expect(files, isEmpty);
      });

      test('lists saved anga files', () async {
        await service.saveBookmark('https://example.com/');
        await service.saveNote('test');

        final files = await service.listAngaFiles();
        expect(files.length, equals(2));
      });

      test('excludes hidden files', () async {
        await service.ensureDirectories();
        File('${service.angaPath}/.hidden').writeAsStringSync('hidden');
        await service.saveNote('visible');

        final files = await service.listAngaFiles();
        expect(files.length, equals(1));
        expect(files.first, isNot(startsWith('.')));
      });
    });

    group('loadAnga', () {
      test('loads bookmark with content and URL', () async {
        final saved = await service.saveBookmark('https://example.com/');
        final loaded = await service.loadAnga(saved.filename);

        expect(loaded, isNotNull);
        expect(loaded!.type, equals(AngaType.bookmark));
        expect(loaded.url, equals('https://example.com/'));
      });

      test('loads note with content', () async {
        final saved = await service.saveNote('My note');
        final loaded = await service.loadAnga(saved.filename);

        expect(loaded, isNotNull);
        expect(loaded!.content, equals('My note'));
      });

      test('returns null for non-existent file', () async {
        await service.ensureDirectories();
        final loaded = await service.loadAnga('nonexistent.url');
        expect(loaded, isNull);
      });
    });

    group('loadAllAngas', () {
      test('returns angas sorted newest first', () async {
        await service.saveNote('first');
        // Small delay to ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
        await service.saveNote('second');

        final angas = await service.loadAllAngas();
        expect(angas.length, equals(2));
        expect(
          angas.first.createdAt.isAfter(angas.last.createdAt) ||
              angas.first.createdAt.isAtSameMomentAs(angas.last.createdAt),
          isTrue,
        );
      });
    });

    group('deleteAnga', () {
      test('deletes existing file', () async {
        final saved = await service.saveNote('to delete');
        expect(File(saved.path).existsSync(), isTrue);

        await service.deleteAnga(saved.filename);
        expect(File(saved.path).existsSync(), isFalse);
      });

      test('does nothing for non-existent file', () async {
        await service.ensureDirectories();
        // Should not throw
        await service.deleteAnga('nonexistent.md');
      });
    });

    group('meta operations', () {
      test('saves and loads metadata', () async {
        final meta = await service.saveMeta(
          '2026-01-28T205208-bookmark.url',
          tags: ['tag1', 'tag2'],
          note: 'Test note',
        );

        expect(meta.metaFilename, endsWith('.toml'));
        expect(meta.angaFilename, equals('2026-01-28T205208-bookmark.url'));
        expect(meta.tags, equals(['tag1', 'tag2']));
        expect(meta.note, equals('Test note'));

        // Verify file on disk
        final content = File(meta.path).readAsStringSync();
        expect(content, contains('[anga]'));
        expect(content, contains('2026-01-28T205208-bookmark.url'));
      });

      test('loads metadata for specific anga', () async {
        await service.saveMeta(
          '2026-01-28T205208-bookmark.url',
          tags: ['tag1'],
        );

        final loaded =
            await service.loadMetaForAnga('2026-01-28T205208-bookmark.url');
        expect(loaded, isNotNull);
        expect(loaded!.tags, equals(['tag1']));
      });

      test('returns null when no metadata for anga', () async {
        await service.ensureDirectories();
        final loaded =
            await service.loadMetaForAnga('nonexistent-bookmark.url');
        expect(loaded, isNull);
      });

      test('listMetaFiles only returns .toml files', () async {
        await service.ensureDirectories();
        File('${service.metaPath}/not-a-toml.txt')
            .writeAsStringSync('not toml');
        await service.saveMeta('test.url', tags: ['t']);

        final files = await service.listMetaFiles();
        expect(files.length, equals(1));
        expect(files.first, endsWith('.toml'));
      });
    });

    group('words operations', () {
      test('saves and reads words files', () async {
        await service.saveWordsFile(
          '2026-01-28T205208-bookmark.url',
          'page.txt',
          'Hello world content'.codeUnits,
        );

        final text = await service.getWordsText(
          '2026-01-28T205208-bookmark.url',
        );
        expect(text, equals('Hello world content'));
      });

      test('concatenates multiple words files', () async {
        const angaName = '2026-01-28T205208-bookmark.url';
        await service.saveWordsFile(
          angaName,
          'part1.txt',
          'First part'.codeUnits,
        );
        await service.saveWordsFile(
          angaName,
          'part2.txt',
          'Second part'.codeUnits,
        );

        final text = await service.getWordsText(angaName);
        expect(text, contains('First part'));
        expect(text, contains('Second part'));
      });

      test('returns null when no words for anga', () async {
        await service.ensureDirectories();
        final text = await service.getWordsText('nonexistent.url');
        expect(text, isNull);
      });

      test('lists words anga directories', () async {
        await service.saveWordsFile('anga1.url', 'f.txt', 'a'.codeUnits);
        await service.saveWordsFile('anga2.url', 'f.txt', 'b'.codeUnits);

        final angas = await service.listWordsAngas();
        expect(angas.length, equals(2));
        expect(angas, containsAll(['anga1.url', 'anga2.url']));
      });
    });

    group('cache operations', () {
      test('saves and lists cache files', () async {
        await service.saveCacheFile(
          'bookmark-name',
          'favicon.ico',
          [0x00, 0x01],
        );

        final bookmarks = await service.listCachedBookmarks();
        expect(bookmarks, contains('bookmark-name'));

        final files = await service.listCacheFiles('bookmark-name');
        expect(files, contains('favicon.ico'));
      });

      test('detects favicon presence', () async {
        expect(
          await service.hasFaviconOrMarker('bookmark-name'),
          isFalse,
        );

        await service.saveCacheFile(
          'bookmark-name',
          'favicon.ico',
          [0x00],
        );

        expect(
          await service.hasFaviconOrMarker('bookmark-name'),
          isTrue,
        );
      });

      test('creates .nofavicon marker', () async {
        await service.createNoFaviconMarker('no-icon-bookmark');

        expect(
          await service.hasFaviconOrMarker('no-icon-bookmark'),
          isTrue,
        );
      });
    });
  });
}
