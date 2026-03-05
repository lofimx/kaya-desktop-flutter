// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AccountSettings {
  String get serverUrl => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get password => throw _privateConstructorUsedError;

  /// Create a copy of AccountSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AccountSettingsCopyWith<AccountSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AccountSettingsCopyWith<$Res> {
  factory $AccountSettingsCopyWith(
    AccountSettings value,
    $Res Function(AccountSettings) then,
  ) = _$AccountSettingsCopyWithImpl<$Res, AccountSettings>;
  @useResult
  $Res call({String serverUrl, String? email, String? password});
}

/// @nodoc
class _$AccountSettingsCopyWithImpl<$Res, $Val extends AccountSettings>
    implements $AccountSettingsCopyWith<$Res> {
  _$AccountSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AccountSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverUrl = null,
    Object? email = freezed,
    Object? password = freezed,
  }) {
    return _then(
      _value.copyWith(
            serverUrl: null == serverUrl
                ? _value.serverUrl
                : serverUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            password: freezed == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AccountSettingsImplCopyWith<$Res>
    implements $AccountSettingsCopyWith<$Res> {
  factory _$$AccountSettingsImplCopyWith(
    _$AccountSettingsImpl value,
    $Res Function(_$AccountSettingsImpl) then,
  ) = __$$AccountSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String serverUrl, String? email, String? password});
}

/// @nodoc
class __$$AccountSettingsImplCopyWithImpl<$Res>
    extends _$AccountSettingsCopyWithImpl<$Res, _$AccountSettingsImpl>
    implements _$$AccountSettingsImplCopyWith<$Res> {
  __$$AccountSettingsImplCopyWithImpl(
    _$AccountSettingsImpl _value,
    $Res Function(_$AccountSettingsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AccountSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serverUrl = null,
    Object? email = freezed,
    Object? password = freezed,
  }) {
    return _then(
      _$AccountSettingsImpl(
        serverUrl: null == serverUrl
            ? _value.serverUrl
            : serverUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        password: freezed == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$AccountSettingsImpl extends _AccountSettings {
  const _$AccountSettingsImpl({
    this.serverUrl = AccountSettings.defaultServerUrl,
    this.email,
    this.password,
  }) : super._();

  @override
  @JsonKey()
  final String serverUrl;
  @override
  final String? email;
  @override
  final String? password;

  @override
  String toString() {
    return 'AccountSettings(serverUrl: $serverUrl, email: $email, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AccountSettingsImpl &&
            (identical(other.serverUrl, serverUrl) ||
                other.serverUrl == serverUrl) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @override
  int get hashCode => Object.hash(runtimeType, serverUrl, email, password);

  /// Create a copy of AccountSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AccountSettingsImplCopyWith<_$AccountSettingsImpl> get copyWith =>
      __$$AccountSettingsImplCopyWithImpl<_$AccountSettingsImpl>(
        this,
        _$identity,
      );
}

abstract class _AccountSettings extends AccountSettings {
  const factory _AccountSettings({
    final String serverUrl,
    final String? email,
    final String? password,
  }) = _$AccountSettingsImpl;
  const _AccountSettings._() : super._();

  @override
  String get serverUrl;
  @override
  String? get email;
  @override
  String? get password;

  /// Create a copy of AccountSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AccountSettingsImplCopyWith<_$AccountSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
