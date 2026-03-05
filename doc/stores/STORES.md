# Releasing Extensions to Stores / Packages

Save Button is published to the Mac App Store.
It also produces a Windows installer (MSIX) and packages (tarball, Flatpak) for Linux.
This document covers the full release process.

## Building Locally

All platforms require the same initial steps:

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Linux

```bash
flutter build linux --release
```

Output: `build/linux/x64/release/bundle/`

To create a distributable tarball:

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

The MSIX configuration lives in `pubspec.yaml` under `msix_config`. To change the app name, publisher, version, or capabilities, edit that section.

### macOS (DMG for direct distribution)

```bash
flutter build macos --release
cd build/macos/Build/Products/Release
hdiutil create -volname "Save Button" -srcfolder kaya_desktop.app -ov -format UDZO kaya-desktop-macos.dmg
```

For Mac App Store distribution, see the next section.

## How Packages Are Created

### CI/CD (GitHub Actions)

The release workflow (`.github/workflows/release.yml`) is triggered by pushing a `v*` tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

This builds all three platforms in parallel:

1. **Linux** (`ubuntu-latest`): Installs system deps, builds, creates tarball
2. **Windows** (`windows-latest`): Builds, runs `dart run msix:create`
3. **macOS** (`macos-latest`): Builds, creates DMG with `hdiutil`

A final job collects all artifacts and creates a GitHub Release.

### MSIX (Windows)

The `msix` dev dependency reads `msix_config` from `pubspec.yaml` and packages the built Windows app into an MSIX installer. The current config sets `store: false` for sideloading. To publish to the Microsoft Store, change `store: true` and add a certificate.

### Flatpak (Linux)

A Flatpak manifest is at `linux/org.savebutton.kaya.yml`. To build locally:

```bash
flutter build linux --release
flatpak-builder --force-clean build-dir linux/org.savebutton.kaya.yml
```

A `.desktop` file is at `linux/org.savebutton.kaya.desktop`.

## Mac App Store

### Prerequisites

- Apple Developer Program membership ($99/year)
- Xcode installed with command-line tools
- App Store Connect account at https://appstoreconnect.apple.com

### First-Time Setup

#### 1. Create the App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Click "My Apps" > "+" > "New App"
3. Fill in:
   - **Platform**: macOS
   - **Name**: Save Button
   - **Primary Language**: English
   - **Bundle ID**: `org.savebutton.kayaDesktop` (must match `macos/Runner/Configs/AppInfo.xcconfig`)
   - **SKU**: `save-button-desktop` (your choice, must be unique in your account)
4. Click "Create"

#### 2. Create Signing Certificates

```bash
# Create a Certificate Signing Request (CSR) in Keychain Access:
# Keychain Access > Certificate Assistant > Request a Certificate from a Certificate Authority
# Save to disk

# Then in https://developer.apple.com/account/resources/certificates:
# 1. Create a "Mac App Distribution" certificate (for App Store)
# 2. Create a "Mac Installer Distribution" certificate (for pkg signing)
# 3. Download and double-click both to install in Keychain
```

#### 3. Create a Provisioning Profile

1. Go to https://developer.apple.com/account/resources/profiles
2. Click "+" > "Mac App Store"
3. Select the `org.savebutton.kayaDesktop` App ID
4. Select the Mac App Distribution certificate
5. Download and double-click to install

#### 4. Configure Xcode Project

Open `macos/Runner.xcworkspace` in Xcode:

1. Select the "Runner" target
2. Under "Signing & Capabilities":
   - Check "Automatically manage signing" OR manually set the provisioning profile
   - Team: Select your Apple Developer team
3. Under "Capabilities", ensure these entitlements are enabled:
   - **App Sandbox**: ON
   - **Network**: Outgoing Connections (Client) - for sync
   - **File Access**: User Selected File (Read/Write) - for file storage
4. Verify `macos/Runner/Release.entitlements` has:
   ```xml
   <key>com.apple.security.app-sandbox</key>
   <true/>
   <key>com.apple.security.network.client</key>
   <true/>
   <key>com.apple.security.files.user-selected.read-write</key>
   <true/>
   ```

#### 5. Update Info.plist

In `macos/Runner/Info.plist`, ensure:

```xml
<key>CFBundleName</key>
<string>Save Button</string>
<key>CFBundleDisplayName</key>
<string>Save Button</string>
```

#### 6. Build and Upload

```bash
# Build the release
flutter build macos --release

# Open in Xcode for archiving
open macos/Runner.xcworkspace
```

In Xcode:
1. Product > Archive
2. When the archive completes, the Organizer window opens
3. Click "Distribute App"
4. Select "App Store Connect"
5. Click "Upload"

Alternatively, use the command line:

```bash
# Build the release
flutter build macos --release

# Create an archive
xcodebuild -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/macos/Runner.xcarchive \
  archive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath build/macos/Runner.xcarchive \
  -exportPath build/macos/export \
  -exportOptionsPlist macos/ExportOptions.plist

# Upload to App Store Connect
xcrun altool --upload-app \
  -f build/macos/export/kaya_desktop.pkg \
  -t macos \
  -u "your@apple-id.com" \
  -p "@keychain:AC_PASSWORD"
```

For `altool`, store your app-specific password in Keychain first:

```bash
xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
  -u "your@apple-id.com" \
  -p "xxxx-xxxx-xxxx-xxxx"
```

Generate the app-specific password at https://appleid.apple.com/account/manage > Sign-In and Security > App-Specific Passwords.

#### 7. Submit for Review

1. In App Store Connect, go to the app
2. Fill in the version information:
   - Screenshots (at least 1280x800 for macOS)
   - Description, keywords, categories
   - Support URL, privacy policy URL
3. Select the uploaded build
4. Click "Submit for Review"

First review typically takes 24-48 hours.

### Updating an Existing App

#### 1. Bump the Version

In `pubspec.yaml`:

```yaml
version: 1.1.0+2    # version+buildNumber
```

The build number must increment with every upload. The version string is what users see.

#### 2. Build, Archive, Upload

```bash
flutter build macos --release
```

Then archive and upload via Xcode (Product > Archive > Distribute App > App Store Connect > Upload) or the command line as described above.

#### 3. Submit the New Version

1. In App Store Connect, click "+" next to the version list to create a new version
2. Enter the new version number (e.g., 1.1.0)
3. Add "What's New in This Version" release notes
4. Select the new build
5. Submit for review

Subsequent reviews are usually faster (often within hours).

### Notarization (for direct DMG distribution outside the App Store)

If distributing DMGs directly (not through the App Store), the app must be notarized:

```bash
# Build
flutter build macos --release

# Sign with Developer ID (NOT Mac App Distribution)
codesign --deep --force --options runtime \
  --sign "Developer ID Application: Your Name (TEAM_ID)" \
  build/macos/Build/Products/Release/kaya_desktop.app

# Create DMG
hdiutil create -volname "Save Button" \
  -srcfolder build/macos/Build/Products/Release/kaya_desktop.app \
  -ov -format UDZO kaya-desktop-macos.dmg

# Submit for notarization
xcrun notarytool submit kaya-desktop-macos.dmg \
  --apple-id "your@apple-id.com" \
  --team-id "TEAM_ID" \
  --password "@keychain:AC_PASSWORD" \
  --wait

# Staple the notarization ticket
xcrun stapler staple kaya-desktop-macos.dmg
```
