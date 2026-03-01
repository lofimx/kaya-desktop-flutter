# Guide for LLMs

This repository will contain the Flutter desktop app for Kaya ("Save Button", to the user).

## Planning

Read [@PLAN.md](./doc/plan/PLAN.md) and follow those instructions for creating a plan before any work is performed. **Plans must always be written to `doc/plan/`** -- never to `~/.claude/plans/` or any other tool-internal location.

---

## Tools

If you need a specific tool (`brew install`, `sudo apt install`, etc.), stop and ask. I'll install it for you.

When using external tools like `gh`, **NEVER WRITE TO EXTERNAL NETWORK SERVICES.** You are not permitted to touch `POST` APIs, use `git push` directly, or to perform any other mutative operation on remote computers, like GitHub. **Only use external tools for research and diagnosing bugs: READ-ONLY.**

---

## Prompt History

You can find a chronological list of significant past prompts in [@PROMPTS.md](./doc/PROMPTS.md). Major prompts are titled with Subheading Level Two (\#\#), sub-prompts are titled with Subheading Level Three (\#\#\#).

The current major prompt or bugfix will probably also be in this file, uncommitted.

This file will get large, over time, so only prioritize reading through it if you require additional context.

---

## Architecture

Files are stored in `~/.kaya/` on disk. Kaya-Desktop-Flutter syncs them directly with the Save Button Server over HTTP.

The app follows the Architectural Decision Records listed in [@arch](./doc/arch)

### Supported Operating Systems

The app is built with Flutter to support multiple OSes from a single codebase:

* Linux
* MacOS
* Windows

### Storage

* `~/kaya/anga/` -- bookmarks (`.url`), text quotes (`.md`), images, and other files
* `~/kaya/meta/` -- TOML metadata files linking anga to tags/notes
* `~/kaya/words/` -- plaintext copies of anga for full-text search, per [@adr-0004-full-text-search.md](./doc/arch/adr-0004-full-text-search.md)

The `words/` directory has a nested structure: `~/kaya/words/{anga}/{filename}`. Words are download-only from the server (the server generates plaintext copies via background jobs).

### Sync

The app syncs directly with the Save Button Server using HTTP Basic Auth:

1. `GET /api/v1/{email}/anga` -- server returns newline-separated filenames
2. Diff against local OPFS file listing
3. Download files missing locally, upload files missing on server
4. Same for `meta/`
5. Sync `words/` (download-only): `GET /api/v1/{email}/words` lists anga dirs, then `GET /api/v1/{email}/words/{anga}` lists files within each, then download missing files

Sync runs on two triggers:
* **Periodic**: every 1 minute
* **Immediate**: After each anga/meta save operation

### Errors

If the app experiences an error during save or sync, it should display it to the user.

### Data Format

Anga and Meta files follow the formats from the ADRs:

* Anga represent a single file: a `.url` bookmark, a `.md` note, or any other arbitrary file
* Meta represent `.toml` files, following the format from [@adr-0003-metadata.md](./doc/arch/adr-0003-metadata.md)

### Bookmarks

Bookmarks will follow the file format `anga/2026-01-27T171207-www-deobald-ca.url`, where the `www-deobald-ca` portion is the domain and subdomains in the URL, with special characters and periods (`.`) turned into hyphens (`-`). Bookmarks are created by clicking the extension's Toolbar Button.

Bookmarks are saved as `.url` files which have the format:

```
[InternetShortcut]
URL=https://perkeep.org/
```

### HTTP API

* `GET /health` -- returns 200 OK
* `GET /anga` -- lists files in `~/.kaya/anga/`
* `GET /meta` -- lists files in `~/.kaya/meta/`
* `GET /words` -- lists anga subdirectories in `~/.kaya/words/`
* `GET /words/{anga}` -- lists files in `~/.kaya/words/{anga}/`
* `POST /anga/{filename}` -- writes request body to `~/.kaya/anga/{filename}`
* `POST /meta/{filename}` -- writes request body to `~/.kaya/meta/{filename}`
* `POST /words/{anga}/{filename}` -- writes request body to `~/.kaya/words/{anga}/{filename}`
* `POST /config` -- accepts JSON `{"server", "email", "password"}`, encrypts password, saves to `~/.kaya/.config`

### Logging

App logs go to `~/.kaya/desktop-app-log`.

### Packaging

The daemon has packaged installers for Windows (MSIX), macOS (PKG), and Linux (Flatpak, Snap, DEB, RPM, AUR).
