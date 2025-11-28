# Platform Notes (macOS)

For shared commands, flags, and flow, read `../README.md`. This file only lists macOS-specific details.

- Shell: bash or zsh. Ensure scripts are executable (`chmod +x tools/macos/**/*.sh`).
- Required tooling: Xcode + Command Line Tools, Java 17, Android SDK (`ANDROID_HOME`/`ANDROID_SDK_ROOT`), Node + `firebase-tools`, `jq`. Flutter via `puro` or `fvm` is auto-detected.
- iOS-only tasks live here: `build/build_ios.sh`, `build/build_ipa.sh`, `distribution/distribute_ios.sh` (need signing assets and unlocked keychain).
- Quick smoke checks after changes: run `./build/build_apk.sh --help`, `./build/build_ios.sh --help` (on macOS), `./localization/localization.sh --help`.
- Keep interfaces aligned with Linux/Windows scripts; only iOS flows should diverge.
