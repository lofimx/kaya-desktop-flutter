# Kaya Desktop Flutter - Project Memory

## Project Overview
- **App**: Save Button (Kaya) - local-first bookmarking & notes desktop app
- **App ID**: `org.savebutton`
- **Platforms**: Linux, macOS, Windows
- **Tech**: Flutter 3.38.5, Dart 3.10.4, Riverpod + Freezed + GoRouter

## Key Patterns
- See [architecture.md](architecture.md) for full details
- Feature-based: `lib/features/{feature}/models/`, `services/`, `screens/`
- Only `ConsumerWidget` - NO StatefulWidget
- Riverpod code generation: `@riverpod`, `@Riverpod(keepAlive: true)`
- Freezed for immutable models with `part` + `@freezed`
- TDD: write tests first, then implementation

## Flutter/Dart Commands
- **MUST** prefix all flutter/dart commands with: `eval "$(~/.local/bin/mise activate bash)"`
- Build runner: `dart run build_runner build --delete-conflicting-outputs`
- Tests: `flutter test`
- Linux build needs: `libsecret-1-dev` (for flutter_secure_storage)

## Known Issues
- Dart 3.10 dot-shorthands not compatible with analyzer 3.9.0 in build_runner
- `ConstrainedBox` is NOT const - don't wrap in `const` context
- `desktop_drop` 0.5.0: `DropTarget` uses `child` not `builder`
- `fuzzy_bolt` API is `searchWithRanks()` not `FuzzyBolt.ratio()` - we removed it, using substring search instead

## File Storage
- Root: `~/.kaya/` (Linux/macOS), `%USERPROFILE%\.kaya` (Windows)
- Dirs: `anga/`, `meta/`, `cache/`, `words/`
- Bookmarks: `.url` files (Windows InternetShortcut format)
- Notes: `.md` files
- Metadata: TOML format in `meta/`
- Filenames: `YYYY-MM-DDTHHMMSS-{descriptor}.{ext}`
