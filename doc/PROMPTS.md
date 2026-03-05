# Historical Prompts

This file should **not be modified by agents.**

## Rewrite `kaya-gnome` to `kaya-desktop-flutter` to support all desktop operating systems

Read and follow the instructions in [@PLAN.md](file:///home/steven/work/lofimx/kaya-desktop-flutter/doc/plan/PLAN.md). Ask any questions you have before finalizing the plan. Confirm before implementation.

Port the entire project found at [@kaya-gnome](file:///home/steven/work/gnome/steven/kaya-gnome/) to [Flutter For Desktop](https://flutter.dev/multi-platform/desktop) in **this repository** with the intention of supporting all major operating systems (Windows, MacOS, Linux).

### OS Support

* Windows
* MacOS
* Linux

Prefer to support older versions but allow newer dependencies/restrictions where necessary. For example, Windows 10 is now end-of-life so while it's nice to support it, it's not a requirement. Supporting MacOS Universal Binaries is a must. Linux support should prefer older (native) libraries whenever possible to avoid excluding users on older distros.

### Flutter Packages

Always prefer the newest Flutter packages possible, as newer Flutter packages tend to be more stable and full-featured.

### Operating System Support & Packaging

It is important to have proper packaging for all 3 major operating systems:

* Windows (`.msix` via `msix` Dart package)
  * requires `internetClient, fileSystem, runFullTrust` capabilities from MSIX sandbox
* MacOS (`.pkg` via Mac-native tools like `pkgbuild`, `productbuild`, and `notarytool`)
* Linux, which has 2 tools with corresponding packaging formats:
  * fastforge (`.rpm`, `.deb`, `pacman`, `snap`)
  * flatpak-flutter (`.flatpak` / Flathub)

### Automation: CI/CD

All packages for all distribution targets (Windows, MacOS, Linux) should be built automatically by GitHub Actions. Any signing, notarizing, etc. should also happen in the GitHub Actions workflow(s).

### Icon

Instead of the "box" icon found in `kaya-gnome`, use [@yellow-floppy3.svg](file:///home/steven/work/lofimx/kaya-desktop-flutter/doc/design/yellow-floppy3.svg)

### Dependency and Documentation

I've installed  `libsecret-1-dev` - make sure this is listed in [@README.md](file:///home/steven/work/lofimx/kaya-desktop-flutter/README.md) along with any other manual steps required for setup, development, and deployment. Then verify the Linux release build.

Also document the process of building locally, explain how packages are created, and describe the processes (first time and updates) required to publish the MacOS package to the App Store in [@STORES.md](file:///home/steven/work/lofimx/kaya-desktop-flutter/doc/stores/STORES.md) 

Document the memory files you just wrote into [@memory](file:///home/steven/work/lofimx/kaya-desktop-flutter/doc/memory) so they live with the repo.

### BUG: Typing into the email and password fields doesn't work

Typing into the email field repeatedly sends the cursor back to the beginning, so typing is backward. Typing into the password field seems to delete each character almost as soon as it is typed.

### BUG: Icon is incorrect

When running via `flutter run -d linux`, the icon in the task switcher is the default icon, not the correct app icon. Perhaps this will be fixed by Flatpak publishing?

### BUG: Title bar is incorrect

The title bar is not following the system theme. I am in dark mode but the title bar is an off-white color.

### BUG: The settings are not saved

When re-opening the settings screen, the email and password are not saved. The email should still be saved, and visible, and the password should be saved and show as bullets when revisiting that screen.

### FIX: Assume GNOME 46 or later on Linux

It's safe to assume GNOME 46 or later on Linux, since that was the GNOME version released with Ubuntu 24.04, which is likely to be the oldest Linux someone will run on a desktop. Like the title bar issue, fix any other API assumptions about old GNOME versions like GNOME 42.

### BUG: Settings says "Sync: Not configured" even when configured

The UI in the settings screen says "sync: not configured" even when an email/password are set.
