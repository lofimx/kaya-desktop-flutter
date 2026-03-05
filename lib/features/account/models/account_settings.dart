import 'package:freezed_annotation/freezed_annotation.dart';

part 'account_settings.freezed.dart';

/// Account settings for server sync configuration.
@freezed
class AccountSettings with _$AccountSettings {
  const AccountSettings._();

  static const defaultServerUrl = 'https://savebutton.com';

  const factory AccountSettings({
    @Default(AccountSettings.defaultServerUrl) String serverUrl,
    String? email,
    String? password,
  }) = _AccountSettings;

  /// Whether sync can be performed (email and credentials both present).
  bool get hasCredentials => password != null && password!.isNotEmpty;

  bool get canSync =>
      email != null && email!.isNotEmpty && hasCredentials;
}
