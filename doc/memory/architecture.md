# Architecture Details

## Directory Structure
```
lib/
  core/
    routing/router.dart          # GoRouter with riverpod provider
    services/logger_service.dart  # Dual console + file logging
    utils/datetime_utils.dart     # Timestamp generation/parsing
    widgets/
      cloud_status_icon.dart      # Sync status in app bar
      error_alert_icon.dart       # Error badge in app bar
  features/
    account/
      models/account_settings.dart   # Freezed, SharedPreferences + SecureStorage
      services/account_repository.dart
      screens/account_screen.dart
    anga/
      models/anga.dart               # Freezed Anga model
      models/anga_type.dart          # bookmark, note, file enum
      services/file_storage_service.dart  # Core file I/O
      services/anga_repository.dart       # Riverpod notifier
    errors/
      models/app_error.dart          # Freezed with ErrorSeverity
      services/error_service.dart    # In-memory error tracking
      screens/errors_list_screen.dart
    everything/
      screens/everything_screen.dart # Grid of all angas
      screens/preview_screen.dart    # Single anga viewer
    meta/
      models/anga_meta.dart          # TOML parsing, Freezed
    save/
      screens/save_screen.dart       # Main save UI with drag-drop
    search/
      services/search_service.dart   # Substring search over all fields
    sync/
      services/sync_service.dart     # HTTP sync, SyncController with Timer
```

## Routes
- `/` - SaveScreen (home)
- `/everything` - EverythingScreen (grid browse)
- `/preview/:filename` - PreviewScreen
- `/account` - AccountScreen (settings)
- `/errors` - ErrorsListScreen

## Riverpod Provider Patterns
- Simple providers: `@riverpod` on function → generates `fooProvider`
- Class-based notifiers: `@riverpod class Foo extends _$Foo`
- Keep-alive: `@Riverpod(keepAlive: true)` for services that persist
- All generated code in `.g.dart` files via `part` directive

## Sync Architecture
- SyncController: 60s Timer.periodic
- Bidirectional sync for anga/ and meta/
- Download-only for cache/ and words/
- HTTP Basic Auth
- Multipart upload for files

## Theming
- `ColorScheme.fromSeed(seedColor: Color(0xFFFFD700))` (gold)
- `ThemeMode.system` for platform-adaptive light/dark
- Material 3 enabled

## Window
- Default: 500x550, Min: 360x450
- Title: "Save Button"
- Shortcuts: Ctrl+Q quit, Ctrl+, preferences
