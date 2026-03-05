import 'package:flutter_test/flutter_test.dart';
import 'package:kaya_desktop/features/anga/models/anga.dart';
import 'package:kaya_desktop/features/anga/models/anga_type.dart';

void main() {
  group('Anga', () {
    group('fromPath', () {
      test('creates bookmark anga from .url file', () {
        const content = '[InternetShortcut]\nURL=https://example.com/\n';
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-example-com.url',
          content: content,
        );

        expect(anga.type, equals(AngaType.bookmark));
        expect(anga.url, equals('https://example.com/'));
        expect(anga.filename, equals('2026-01-27T171207-example-com.url'));
      });

      test('creates note anga from .md file', () {
        const content = 'This is my note';
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-note.md',
          content: content,
        );

        expect(anga.type, equals(AngaType.note));
        expect(anga.content, equals(content));
      });

      test('creates file anga for other extensions', () {
        final anga = Anga.fromPath('/kaya/anga/2026-01-27T171207-image.png');

        expect(anga.type, equals(AngaType.file));
        expect(anga.extension, equals('png'));
        expect(anga.isImage, isTrue);
      });

      test('parses timestamp from filename', () {
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-note.md',
          content: 'test',
        );

        expect(anga.createdAt.year, equals(2026));
        expect(anga.createdAt.month, equals(1));
        expect(anga.createdAt.day, equals(27));
        expect(anga.createdAt.hour, equals(17));
        expect(anga.createdAt.minute, equals(12));
        expect(anga.createdAt.second, equals(7));
      });

      test('stores file size when provided', () {
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-doc.pdf',
          fileSize: 12345,
        );

        expect(anga.fileSize, equals(12345));
      });
    });

    group('displayTitle', () {
      test('returns domain for bookmarks', () {
        const content =
            '[InternetShortcut]\nURL=https://www.example.com/path\n';
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-www-example-com.url',
          content: content,
        );

        expect(anga.displayTitle, equals('www.example.com'));
      });

      test('returns first line for notes', () {
        const content = 'First line\nSecond line';
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-note.md',
          content: content,
        );

        expect(anga.displayTitle, equals('First line'));
      });

      test('truncates long titles', () {
        final longContent = 'A' * 100;
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-note.md',
          content: longContent,
        );

        expect(anga.displayTitle.length, lessThanOrEqualTo(50));
        expect(anga.displayTitle, endsWith('...'));
      });

      test('returns "Note" for empty content', () {
        final anga = Anga.fromPath('/kaya/anga/2026-01-27T171207-note.md');

        expect(anga.displayTitle, equals('Note'));
      });

      test('returns descriptor for file types', () {
        final anga =
            Anga.fromPath('/kaya/anga/2026-01-27T171207-my-document.pdf');

        expect(anga.displayTitle, equals('my-document.pdf'));
      });
    });

    group('file type detection', () {
      test('detects image files', () {
        for (final ext in ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'svg']) {
          final anga =
              Anga.fromPath('/kaya/anga/2026-01-27T171207-photo.$ext');
          expect(anga.isImage, isTrue, reason: 'Expected .$ext to be image');
          expect(anga.isVideo, isFalse);
          expect(anga.isPdf, isFalse);
        }
      });

      test('detects video files', () {
        for (final ext in ['mp4', 'mov', 'avi', 'mkv', 'webm', 'm4v']) {
          final anga =
              Anga.fromPath('/kaya/anga/2026-01-27T171207-video.$ext');
          expect(anga.isVideo, isTrue, reason: 'Expected .$ext to be video');
          expect(anga.isImage, isFalse);
        }
      });

      test('detects PDF files', () {
        final anga =
            Anga.fromPath('/kaya/anga/2026-01-27T171207-document.pdf');
        expect(anga.isPdf, isTrue);
      });
    });

    group('displayTitle URL decoding', () {
      test('decodes URL-encoded filename for display', () {
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-GNOME%20Regento%20NDA.pdf',
        );

        expect(anga.displayTitle, equals('GNOME Regento NDA.pdf'));
      });

      test('decodes complex URL-encoded filename for display', () {
        final anga = Anga.fromPath(
          '/kaya/anga/2026-01-27T171207-My%20File%20%2B%20Notes.txt',
        );

        expect(anga.displayTitle, equals('My File + Notes.txt'));
      });
    });
  });

  group('filename generation', () {
    test('generateBookmarkFilename creates correct format', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateBookmarkFilename(
        'https://www.example.com/path?q=1',
        ts,
      );

      expect(filename, equals('2026-01-27T171207-www-example-com.url'));
    });

    test('generateBookmarkFilename handles complex domains', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateBookmarkFilename(
        'https://sub.domain.example.co.uk/',
        ts,
      );

      expect(
        filename,
        equals('2026-01-27T171207-sub-domain-example-co-uk.url'),
      );
    });

    test('generateBookmarkFilename handles invalid URLs gracefully', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateBookmarkFilename('not a url', ts);

      expect(filename, equals('2026-01-27T171207-bookmark.url'));
    });

    test('generateNoteFilename creates correct format', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateNoteFilename(ts);

      expect(filename, equals('2026-01-27T171207-note.md'));
    });

    test('generateFileFilename preserves extension', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateFileFilename('my-photo.jpg', ts);

      expect(filename, equals('2026-01-27T171207-my-photo.jpg'));
    });

    test('generateFileFilename URL-encodes spaces', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateFileFilename('GNOME Regento NDA.pdf', ts);

      expect(filename, equals('2026-01-27T171207-GNOME%20Regento%20NDA.pdf'));
      expect(filename, isNot(contains(' ')));
    });

    test('generateFileFilename URL-encodes unicode characters', () {
      final ts = DateTime.utc(2026, 1, 27, 17, 12, 7);
      final filename = generateFileFilename('документ.pdf', ts);

      expect(filename, startsWith('2026-01-27T171207-'));
      expect(filename, endsWith('.pdf'));
      expect(filename, isNot(contains('д')));
    });
  });

  group('createBookmarkContent', () {
    test('creates Windows .url format', () {
      final content = createBookmarkContent('https://example.com/');

      expect(content, contains('[InternetShortcut]'));
      expect(content, contains('URL=https://example.com/'));
    });
  });
}
