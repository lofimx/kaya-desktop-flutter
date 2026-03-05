import 'package:flutter_test/flutter_test.dart';
import 'package:kaya_desktop/features/account/models/account_settings.dart';

void main() {
  group('AccountSettings', () {
    test('has correct default server URL', () {
      expect(
        AccountSettings.defaultServerUrl,
        equals('https://savebutton.com'),
      );
    });

    test('canSync is true when email and password are present', () {
      const settings = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: 'user@example.com',
        password: 'secret',
      );

      expect(settings.canSync, isTrue);
      expect(settings.hasCredentials, isTrue);
    });

    test('canSync is false when email is missing', () {
      const settings = AccountSettings(
        serverUrl: 'https://savebutton.com',
        password: 'secret',
      );

      expect(settings.canSync, isFalse);
    });

    test('canSync is false when password is missing', () {
      const settings = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: 'user@example.com',
      );

      expect(settings.canSync, isFalse);
      expect(settings.hasCredentials, isFalse);
    });

    test('canSync is false when email is empty', () {
      const settings = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: '',
        password: 'secret',
      );

      expect(settings.canSync, isFalse);
    });

    test('canSync is false when password is empty', () {
      const settings = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: 'user@example.com',
        password: '',
      );

      expect(settings.canSync, isFalse);
      expect(settings.hasCredentials, isFalse);
    });

    test('uses default server URL when not specified', () {
      const settings = AccountSettings();

      expect(settings.serverUrl, equals(AccountSettings.defaultServerUrl));
    });

    test('freezed equality works', () {
      const a = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: 'user@example.com',
        password: 'secret',
      );
      const b = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: 'user@example.com',
        password: 'secret',
      );

      expect(a, equals(b));
    });

    test('copyWith works', () {
      const original = AccountSettings(
        serverUrl: 'https://savebutton.com',
        email: 'user@example.com',
        password: 'secret',
      );

      final updated = original.copyWith(email: 'new@example.com');

      expect(updated.email, equals('new@example.com'));
      expect(updated.serverUrl, equals('https://savebutton.com'));
      expect(updated.hasCredentials, isTrue);
    });
  });
}
