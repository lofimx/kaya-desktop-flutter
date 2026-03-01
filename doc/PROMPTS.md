# Historical Prompts

This file should **not be modified by agents.**

## Rewrite `kaya-gnome` to `kaya-desktop-flutter` to support all desktop operating systems

Read and follow the instructions in [@PLAN.md](file:///home/steven/work/lofimx/kaya-desktop-flutter/doc/plan/PLAN.md).

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
