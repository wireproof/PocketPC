# Pocket PC for iOS

An experimental iOS frontend for the Pocket2Droid Device Emulator machine. The app is named **Pocket PC** with bundle identifier `com.wireproof.pocketpc`. It runs an ARM Windows Mobile Device Emulator image locally using QEMU's TCG interpreter.

## Current status

Version 0.1.1 is an early development build. A previous 0.1.0 build booted Windows Mobile 6 to the Today screen on an iPhone Duo; touch was reported working by the owner. Version 0.1.1 adds Emulator, Sessions, Settings, and About navigation and avoids reading and decoding unchanged screen frames. The version 0.1.1 UI and icon have not yet been visually confirmed on a physical device. Guest performance is limited by interpreted CPU emulation. Audio, persistence across restart, and lifecycle behavior still require verification.

**Device verification:** Development build 0.1.1 (build 4) was installed on an iPad, and the installed build number was verified. The app was not launched, so the UI, controls, and guest operation were not verified in this build. This is a development status note, not a public tagged release or a downloadable IPA.

## Contents

- `iOS/` contains the SwiftUI frontend, generated icon, XcodeGen specification and embedded iOS frameworks used by the development build. Use your own Apple Development team and signing profile.
- `upstream/Pocket2Droid/` contains the source snapshot from [Pocket2Droid](https://github.com/samsixx6/Pocket2Droid) commit `60d0f71de23c83c39d98ce6984049b492d3867cf`, including local iOS portability and diagnostic changes. The snapshot's source-hash manifest describes upstream files and therefore does not describe the modified files here.
- Windows Mobile system images have separate Microsoft copyright and redistribution terms; this project's source licenses do not cover them.
- `scripts/ios-compat/` contains the libucontext compatibility header used when cross-building the core. `scripts/utm-build-dependencies-v5.0.8.sh` is the upstream UTM dependency build script for reference.

## Build the frontend

Install Xcode and XcodeGen. The included frameworks were produced with an iOS ARM64 cross-build and are for device builds only; a simulator build is not currently provided. From the repository root:

```sh
xcodegen generate --spec iOS/project.yml
open iOS/PocketPC.xcodeproj
```

Select your own development team and a suitable provisioning profile in Xcode. The project currently records the author's team ID, so change it for your account. A compatible, legitimately obtained system image is required and is not embedded in the app. Import the image with the app's file picker. A device must have sufficient free space for the ROM and its separate guest storage.

## Core provenance and limitations

The modified QEMU source is GPL-2.0-or-later; see `upstream/Pocket2Droid/LICENSE` and component-specific notices. The prebuilt iOS frameworks depend on libffi, GLib, pixman, gettext, libiconv, and libucontext from the [UTM](https://github.com/utmapp/UTM) v5.0.8 iOS interpreter sysroot. See `upstream/Pocket2Droid/THIRD_PARTY.md`, individual upstream component notices, and UTM's build script for dependency source and license details. Frameworks and the Windows Mobile ROM have their own copyright and license terms. The iOS core cross-build required local adaptations for Apple filesystem APIs, the interpreter's memory mapping and libucontext; these are experimental and are not intended as an upstream QEMU contribution.

Do not assume that a successful compile or installation proves guest behavior. The current app starts one emulation session per app process and has no in-app clean shutdown or verified session switching. Preserve guest data and exit the app before selecting another ROM.
