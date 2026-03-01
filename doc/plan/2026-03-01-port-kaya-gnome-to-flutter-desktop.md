# Plan: Port kaya-gnome to kaya-desktop-flutter

## Goal

Port the GNOME-specific Kaya app (GJS/TypeScript/Libadwaita) to a cross-platform Flutter desktop app targeting Windows, macOS, and Linux.

## Source Analysis

The kaya-gnome app has:

- **Models**: `Anga` (bookmarks/notes), `Meta` (TOML metadata), `Dropped` (drag-drop files), `Timestamp`, `Clock`, `Filename` (validation)
- **Services**: `FileService` (disk I/O), `SettingsService` (GSettings + keyring), `SyncService` (HTTP API client), `SyncManager` (periodic sync every 60s)
- **Views**: Main window (text input + note + save button + drag-drop zone), Preferences dialog (server URL, email, password, sync status, force sync)

## Architecture Decisions

### App ID & Naming

- App ID: `org.savebutton`
- Display name: "Save Button"

### Flutter Version & Packages

Flutter 3.38.5 (stable), Dart 3.10.4. Key packages:

| Purpose | Package | Notes |
|---------|---------|-------|
| State management | `flutter_riverpod` ^2.6.1 | Riverpod with code generation |
| State management | `riverpod_annotation` ^2.6.1 | Provider annotations |
| Models | `freezed_annotation` ^2.4.4 | Immutable data classes |
| HTTP client | `http` ^1.2.2 | Standard HTTP client |
| Secure storage | `flutter_secure_storage` ^9.2.4 | Cross-platform keyring |
| Settings/prefs | `shared_preferences` ^2.3.5 | Key-value settings |
| Path resolution | `path_provider` ^2.1.5 | Platform directory resolution |
| TOML parsing | `toml` ^0.16.0 | For metadata files |
| Logging | `logger` ^2.5.0 | File-based logging |
| Routing | `go_router` ^14.6.3 | Navigation |
| Window management | `window_manager` | Min/max size, title |
| Drag and drop | `desktop_drop` | Desktop file drag-and-drop |
| SVG | `flutter_svg` ^2.0.10 | SVG rendering for icon |
| URL handling | `url_launcher` ^6.3.1 | Open URLs in browser |

Dev dependencies:

| Purpose | Package |
|---------|---------|
| Code gen runner | `build_runner` ^2.4.14 |
| Riverpod codegen | `riverpod_generator` ^2.6.3 |
| Freezed codegen | `freezed` ^2.5.7 |
| Icon generation | `flutter_launcher_icons` ^0.14.3 |
| Linting | `flutter_lints` ^6.0.0 |

### Storage

```
~/.kaya/                        (Linux/macOS: ~/.kaya/, Windows: %USERPROFILE%\.kaya\)
├── anga/       bookmarks (.url), notes (.md), images, other files
├── meta/       TOML metadata files
├── cache/      cached favicons (download-only from server)
└── words/      plaintext search index (download-only from server)
```

Settings stored via `shared_preferences` (server URL, email). Password stored via `flutter_secure_storage`.

### Project Structure

Following the feature-based architecture from kaya-flutter:

```
lib/
├── main.dart                           App entry point + theme
├── core/
│   ├── routing/
│   │   └── router.dart                 GoRouter configuration
│   ├── services/
│   │   └── logger_service.dart         Dual console + file logging
│   └── utils/
│       └── datetime_utils.dart         Timestamp formatting/parsing
│
└── features/
    ├── anga/
    │   ├── models/
    │   │   ├── anga.dart               Anga model (freezed)
    │   │   └── anga_type.dart          AngaType enum
    │   ├── services/
    │   │   ├── file_storage_service.dart  Disk I/O
    │   │   └── anga_repository.dart       Anga state notifier
    │   └── widgets/
    │       └── anga_tile.dart           Grid tile widget
    │
    ├── meta/
    │   └── models/
    │       └── anga_meta.dart          AngaMeta model (freezed)
    │
    ├── account/
    │   ├── models/
    │   │   └── account_settings.dart   AccountSettings model (freezed)
    │   ├── services/
    │   │   └── account_repository.dart SharedPrefs + SecureStorage
    │   └── screens/
    │       └── account_screen.dart     Settings/preferences UI
    │
    ├── sync/
    │   └── services/
    │       └── sync_service.dart       HTTP sync + SyncController
    │
    ├── save/
    │   └── screens/
    │       └── save_screen.dart        Main save UI (text + note + drop)
    │
    ├── everything/
    │   └── screens/
    │       ├── everything_screen.dart  Browse all angas
    │       └── preview_screen.dart     View single anga
    │
    ├── search/
    │   └── services/
    │       └── search_service.dart     Fuzzy search
    │
    └── errors/
        ├── models/
        │   └── app_error.dart          AppError model (freezed)
        └── services/
            └── error_service.dart      In-memory error tracking
```

### State Management: Riverpod

Following the same patterns as kaya-flutter:

- **No StatefulWidgets** -- all widgets are `ConsumerWidget`
- **`@riverpod` annotations** with code generation (`.g.dart` files)
- **`@Riverpod(keepAlive: true)`** for long-lived services (file storage, sync, account)
- **`@freezed`** for all data models (Anga, AngaMeta, AccountSettings, AppError)
- **Class-based notifiers** for mutable state (AngaRepository, SyncController, ErrorService, AccountSettingsNotifier)
- **Function providers** for simple dependencies (router, logger, storage service)

### UI Design

Follow each platform's native design language:

- **macOS**: Cupertino-style widgets where appropriate, system accent color
- **Windows**: Fluent Design cues, system accent color
- **Linux**: Material 3 (GTK/GNOME-friendly), neutral defaults

Use `ThemeData` with `ColorScheme.fromSeed()` and `ThemeMode.system` for dark/light. No hardcoded brand colors -- defer to the OS theme. The `yellow-floppy3.svg` gold (#FFD700) can serve as the seed color for a warm, neutral default across platforms.

**Save Screen** (main window, default route):
- App bar with "Save Button" title, settings icon, error alert icon, cloud status icon
- Text field for bookmark URL or note text
- Multi-line text field for optional metadata note
- "Save" button (elevated, full-width, primary color)
- Drag-and-drop zone (200px, icon + label)
- SnackBar for success/error notifications

**Everything Screen** (browse all angas):
- Responsive grid of AngaTiles
- Search bar
- Drawer with navigation

**Preview Screen** (view single anga):
- Content display (URL, text, image, etc.)
- Metadata editing (tags, notes)

**Account Screen** (settings):
- Server URL text field
- Email text field
- Password field (obscured)
- Test Connection button
- Force Sync button

### Sync

Direct port from kaya-flutter's sync architecture:
1. HTTP Basic Auth with email:password
2. Bidirectional sync for anga and meta (upload + download)
3. Download-only for cache (favicons) and words (search index)
4. Periodic sync every 60 seconds via `Timer.periodic`
5. Connectivity-aware (sync when online)
6. Connection status tracking (connected/disconnected/not configured)
7. Error tracking via ErrorService

### Packaging

**Windows (.msix)**:
- `msix` Dart package
- Capabilities: `internetClient`, `fileSystem`, `runFullTrust`

**macOS (.pkg)**:
- `flutter build macos --release`
- `pkgbuild` / `productbuild` for `.pkg`
- Sign with Developer ID, notarize with `notarytool`
- Universal Binary (arm64 + x86_64)

**Linux**:
- `fastforge` for `.deb`, `.rpm`, `pacman`, `snap`
- `flatpak-flutter` for `.flatpak` / Flathub

### CI/CD (GitHub Actions)

Tag-triggered release workflow building all platforms.

### Icon

`yellow-floppy3.svg` → platform-specific icon sizes via `flutter_launcher_icons`.

---

## Implementation Phases

All phases follow TDD: write tests first, then implement to pass.

### Phase 1: Project Bootstrap
1. Initialize Flutter desktop project (`flutter create --platforms=linux,macos,windows --org org.savebutton`)
2. Configure `pubspec.yaml` with all dependencies
3. Set up directory structure (features, core, etc.)
4. Configure `window_manager` for desktop window defaults (500x550, min 360x450, title "Save Button")
5. Copy `yellow-floppy3.svg` into assets, configure `flutter_launcher_icons`
6. Run `build_runner` to verify codegen works

### Phase 2: Core Utilities + Models (TDD)
1. Write tests for `DateTimeUtils` → implement `DateTimeUtils`
2. Write tests for `Anga` model → implement `Anga` (freezed) + `AngaType`
3. Write tests for `AngaMeta` model → implement `AngaMeta` (freezed)
4. Write tests for filename generation → implement bookmark/note/file filename generators
5. Write tests for `AccountSettings` model → implement `AccountSettings` (freezed)
6. Write tests for `AppError` model → implement `AppError` (freezed)
7. Run `build_runner build` to generate freezed code

### Phase 3: Services (TDD)
1. Write tests for `FileStorageService` → implement file I/O
2. Write tests for `AccountRepository` → implement settings + secure storage
3. Write tests for `SyncService` → implement HTTP sync
4. Implement `SyncController` (notifier with Timer.periodic)
5. Implement `AngaRepository` (notifier wrapping FileStorageService)
6. Implement `LoggerService` (dual console + file logging)
7. Implement `ErrorService` (in-memory error tracking)
8. Implement `SearchService` (fuzzy search over angas/meta/words)
9. Run `build_runner build` to generate provider code

### Phase 4: UI
1. Implement `main.dart` (ProviderScope, MaterialApp.router, themes)
2. Implement `router.dart` (GoRouter with routes)
3. Build `SaveScreen` (text input, note, save button, drag-drop zone)
4. Build `EverythingScreen` (grid of angas, search)
5. Build `PreviewScreen` (view/edit single anga)
6. Build `AccountScreen` (server URL, email, password, test connection, force sync)
7. Add cloud status icon and error alert icon to app bars
8. Keyboard shortcuts (Ctrl+Q quit, Ctrl+, preferences)
9. Accessibility (semantics labels)

### Phase 5: Packaging & CI/CD
1. Configure MSIX for Windows
2. Configure macOS build + signing + notarization scripts
3. Configure fastforge for Linux packages
4. Configure flatpak-flutter for Flatpak
5. Write GitHub Actions workflows
6. Set up tag-triggered release workflow
