# Save Button (kaya-desktop-flutter)

Local-first bookmarking and notes app for desktop. Saves bookmarks, notes, and files to `~/.kaya/` and syncs with a server via HTTP.

Built with Flutter targeting Linux, macOS, and Windows.

## Prerequisites

- Flutter SDK (stable channel, 3.38.5+)
- Dart SDK 3.10.4+

### Linux

Flutter can only do GTK3 for now, as of `3.38.5`.

```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev libstdc++-12-dev libsecret-1-dev lld
```

| Package | Purpose |
|---------|---------|
| `clang` | C/C++ compiler for Flutter Linux runner |
| `cmake`, `ninja-build`, `pkg-config` | Build toolchain |
| `libgtk-3-dev` | GTK3 for Flutter Linux embedding |
| `libsecret-1-dev` | Keyring access for `flutter_secure_storage` |
| `liblzma-dev`, `libstdc++-12-dev` | Runtime dependencies |
| `lld` | LLVM linker required by Dart AOT compiler |

### macOS

- Xcode with command-line tools
- No additional system packages required

### Windows

- Visual Studio 2022 with "Desktop development with C++" workload
- No additional system packages required

## Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The `build_runner` step generates Riverpod providers (`.g.dart`) and Freezed models (`.freezed.dart`). Run it after any change to files annotated with `@riverpod` or `@freezed`.

## Development

### Run

```bash
flutter run -d linux    # or -d macos, -d windows
```

### Tests

```bash
flutter test
```

### Code Generation

After modifying models or providers:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or watch for changes:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

### Analysis

```bash
flutter analyze
```

## Building Release Packages

### Linux

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

To create a tarball:

```bash
cd build/linux/x64/release/bundle
tar czf kaya-desktop-linux-x64.tar.gz .
```

### Windows (MSIX)

```bash
flutter build windows --release
dart run msix:create
```

Output: `build/windows/x64/runner/Release/*.msix`

MSIX configuration is in `pubspec.yaml` under `msix_config`.

### macOS (DMG)

```bash
flutter build macos --release
cd build/macos/Build/Products/Release
hdiutil create -volname "Save Button" -srcfolder kaya_desktop.app -ov -format UDZO kaya-desktop-macos.dmg
```

For Mac App Store distribution, see [doc/stores/STORES.md](doc/stores/STORES.md).

## Project Structure

```
lib/
  core/
    routing/          # GoRouter configuration
    services/         # Logger service
    utils/            # Timestamp utilities
    widgets/          # Shared widgets (cloud status, error alert)
  features/
    account/          # Server settings, credentials
    anga/             # Core data model and file storage
    errors/           # Error tracking and display
    everything/       # Browse all items, preview
    meta/             # TOML metadata
    save/             # Main save screen with drag-drop
    search/           # Search across all content
    sync/             # HTTP sync with server
```

## CI/CD

- **CI** (`.github/workflows/ci.yml`): Runs on push/PR to `main`. Installs deps, runs `build_runner`, `flutter analyze`, and `flutter test`.
- **Release** (`.github/workflows/release.yml`): Triggered by `v*` tags. Builds Linux tarball, Windows MSIX, and macOS DMG, then creates a GitHub Release with all artifacts.

To cut a release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

## Data Storage

All data lives in `~/.kaya/` (Linux/macOS) or `%USERPROFILE%\.kaya` (Windows):

- `anga/` - Bookmarks (`.url`), notes (`.md`), and files
- `meta/` - TOML metadata (tags, notes about items)
- `cache/` - Favicons and cached content
- `words/` - Full-text search index
