# Pocket PC for iOS

Pocket PC is an experimental iPhone and iPad frontend for the Pocket2Droid Device Emulator machine. It runs Windows Mobile Device Emulator images locally with QEMU's TCG interpreter.

## Current release

**0.1.1, build 4 is an experimental prerelease.** It adds Emulator, Sessions, Settings and About navigation, a ROM session list, a display-smoothing option and more efficient screen-frame polling. A previous build booted Windows Mobile 6 to the Today screen on an iPhone Duo, and the owner reported touch working. Build 4 is installed on the Duo and iPad; its new interface, iPad layout and guest behavior have not yet been visually confirmed. The interpreted CPU can be slow. Audio, persistence across restart and lifecycle behavior remain to be tested.

The release IPA is unsigned and requires sideloading or signing for your device. It does not contain a ROM. Import a compatible `.bin` image through the app; the repository includes the supplied Windows Mobile 6 Device Emulator image. Each imported ROM has its own guest storage.

## Project contents

- `iOS/` — SwiftUI frontend, app icon, XcodeGen project specification and device frameworks.
- `ROMs/` — Windows Mobile 6 Device Emulator image used during development.
- `upstream/Pocket2Droid/` — Pocket2Droid source snapshot with experimental iOS adaptations.
- `scripts/` — iOS compatibility header and reference dependency-build script.

## Build

Install Xcode and XcodeGen, then run:

```sh
xcodegen generate --spec iOS/project.yml
open iOS/PocketPC.xcodeproj
```

Configure signing for your own device. The included frameworks target iOS ARM64 devices; they do not support the simulator. The current app starts one emulation session per app process. It does not yet provide a clean in-app shutdown or verified session switching; preserve guest data and close the app before selecting another ROM.

## Credits

Pocket PC builds on [Pocket2Droid](https://github.com/samsixx6/Pocket2Droid), QEMU and libraries from the [UTM](https://github.com/utmapp/UTM) iOS interpreter sysroot. Source and dependency provenance are recorded in [PROVENANCE.md](PROVENANCE.md); component license notices are retained with the source.
